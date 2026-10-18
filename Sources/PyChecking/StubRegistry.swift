import PySwiftAST

/// Types of a module's names, read from a `.pyi` stub
public struct ModuleStub: Sendable {
    /// Full dotted module name, e.g. "os.path"
    public let name: String
    /// Types of the module's variables, functions (`.function`) and classes (`.classType`)
    public var members: [String: PythonType]
    /// Members of the classes defined in the stub, by class name
    public var classes: [String: [MemberInfo]]
}

/// Type stubs for modules that scripts import, used by `TypeChecker` to type
/// `import` statements and attribute access on modules.
///
/// Stubs are `.pyi` source. Top-level annotated variables, constants, functions
/// and classes are read; everything else (imports, `if sys.version_info` blocks)
/// is skipped. Of several `@overload`s the first one is used.
///
/// ```swift
/// var stubs = StubRegistry.standardLibrary
/// try stubs.register(module: "touchbay", source: touchbayStub)
/// let checker = TypeChecker(stubs: stubs)
/// ```
public struct StubRegistry: Sendable {
    public private(set) var modules: [String: ModuleStub] = [:]

    public init() {}

    /// Stubs for common standard library modules
    public static let standardLibrary: StubRegistry = {
        var registry = StubRegistry()
        for (name, source) in StandardLibraryStubs.sources {
            // The bundled stubs are covered by tests, so a parse failure is a bug here
            try! registry.register(module: name, source: source)
        }
        return registry
    }()

    /// Add or replace the stub for a module
    /// - Parameters:
    ///   - name: Full dotted module name, e.g. "os.path"
    ///   - source: `.pyi` source
    public mutating func register(module name: String, source: String) throws {
        modules[name] = StubRegistry.parseStub(name: name, module: try parsePython(source))
    }

    public func module(_ name: String) -> ModuleStub? {
        modules[name]
    }

    /// Type of `module.attribute`: a stubbed member or a stubbed submodule
    public func memberType(module name: String, attribute: String) -> PythonType? {
        if let type = modules[name]?.members[attribute] {
            return type
        }
        if modules["\(name).\(attribute)"] != nil {
            return .module("\(name).\(attribute)")
        }
        return nil
    }

    // MARK: - Stub parsing

    private static func parseStub(name: String, module: Module) -> ModuleStub {
        let statements: [Statement] = switch module {
        case .module(let stmts), .interactive(let stmts): stmts
        default: []
        }

        // Register the stub's classes first so annotations can refer to them
        let classRegistry = ClassRegistry()
        for statement in statements {
            if case .classDef(let classDef) = statement {
                classRegistry.registerClass(classDef.name, at: classDef.lineno, endLine: classDef.endLineno ?? classDef.lineno)
            }
        }

        var members: [String: PythonType] = [:]
        var classes: [String: [MemberInfo]] = [:]

        for statement in statements {
            switch statement {
            case .annAssign(let annAssign):
                if case .name(let target) = annAssign.target {
                    members[target.id] = PythonType.fromExpression(annAssign.annotation, classRegistry: classRegistry)
                }
            case .assign(let assign):
                // Constants such as `MAX = 3`
                let valueType = PythonType.fromExpression(assign.value, classRegistry: classRegistry)
                for case .name(let target) in assign.targets where members[target.id] == nil {
                    members[target.id] = valueType
                }
            case .functionDef(let funcDef):
                if members[funcDef.name] == nil {
                    members[funcDef.name] = functionType(funcDef.args, funcDef.returns, classRegistry)
                }
            case .asyncFunctionDef(let funcDef):
                if members[funcDef.name] == nil {
                    members[funcDef.name] = functionType(funcDef.args, funcDef.returns, classRegistry)
                }
            case .classDef(let classDef):
                members[classDef.name] = .classType(classDef.name)
                classes[classDef.name] = classMembers(classDef, classRegistry)
            default:
                break
            }
        }

        return ModuleStub(name: name, members: members, classes: classes)
    }

    private static func functionType(_ args: Arguments, _ returns: Expression?, _ classRegistry: ClassRegistry) -> PythonType {
        let returnType = returns.map { PythonType.fromExpression($0, classRegistry: classRegistry) } ?? .any
        return .function(parameters: FunctionParameter.parameters(of: args, classRegistry: classRegistry), returnType: returnType)
    }

    /// Class members, following `ClassRegistry`'s convention that a method's type is its return type
    private static func classMembers(_ classDef: ClassDef, _ classRegistry: ClassRegistry) -> [MemberInfo] {
        var members: [MemberInfo] = []

        for statement in classDef.body {
            switch statement {
            case .annAssign(let annAssign):
                if case .name(let target) = annAssign.target {
                    let type = PythonType.fromExpression(annAssign.annotation, classRegistry: classRegistry)
                    members.append(MemberInfo(name: target.id, type: type, kind: .property, line: annAssign.lineno))
                }
            case .functionDef(let funcDef):
                guard !members.contains(where: { $0.name == funcDef.name }) else { continue }
                let decorators = funcDef.decoratorList.compactMap { decorator -> String? in
                    if case .name(let name) = decorator { return name.id }
                    return nil
                }
                let kind: MemberKind = decorators.contains("property") ? .property
                    : decorators.contains("classmethod") ? .classMethod
                    : decorators.contains("staticmethod") ? .staticMethod
                    : .method
                let returnType = funcDef.returns.map { PythonType.fromExpression($0, classRegistry: classRegistry) } ?? .any
                members.append(MemberInfo(name: funcDef.name, type: returnType, kind: kind, line: funcDef.lineno))
            default:
                break
            }
        }

        return members
    }
}
