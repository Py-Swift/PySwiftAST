import PySwiftAST

/// Static type checker for Python code
///
/// Performs type inference and type checking based on:
/// - Variable annotations (x: int = 5)
/// - Function annotations (def f(x: int) -> str)
/// - Inferred types from literals and operations
/// - Type compatibility rules
public struct TypeChecker: PyChecker {
    public let id = "type-checker"
    public let name = "Type Checker"
    public let description = "Static type checking with type inference"
    
    private var typeEnvironment: TypeEnvironment
    
    public init() {
        self.typeEnvironment = TypeEnvironment()
    }
    
    public func check(_ module: Module) -> [Diagnostic] {
        var checker = TypeChecker()
        return checker.checkModule(module)
    }
    
    private mutating func checkModule(_ module: Module) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        let statements: [Statement] = switch module {
        case .module(let stmts), .interactive(let stmts):
            stmts
        default:
            []
        }
        
        for statement in statements {
            diagnostics.append(contentsOf: checkStatement(statement))
        }
        
        return diagnostics
    }
    
    // MARK: - Statement Checking
    
    private mutating func checkStatement(_ stmt: Statement) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        switch stmt {
        case .assign(let assign):
            diagnostics.append(contentsOf: checkAssign(assign))
            
        case .annAssign(let annAssign):
            diagnostics.append(contentsOf: checkAnnAssign(annAssign))
            
        case .functionDef(let funcDef):
            diagnostics.append(contentsOf: checkFunctionDef(funcDef))
            
        case .asyncFunctionDef(let funcDef):
            diagnostics.append(contentsOf: checkAsyncFunctionDef(funcDef))
            
        case .returnStmt(let ret):
            diagnostics.append(contentsOf: checkReturn(ret))
            
        case .ifStmt(let ifStmt):
            diagnostics.append(contentsOf: checkIf(ifStmt))
            
        case .forStmt(let forStmt):
            diagnostics.append(contentsOf: checkFor(forStmt))
            
        case .whileStmt(let whileStmt):
            diagnostics.append(contentsOf: checkWhile(whileStmt))
            
        default:
            break
        }
        
        return diagnostics
    }
    
    // MARK: - Assignment Checking
    
    private mutating func checkAssign(_ assign: Assign) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        // Infer type from value
        let valueType = inferType(assign.value)
        
        // Update type environment for each target
        for target in assign.targets {
            if case .name(let name) = target {
                // Check if variable already has a type
                if let existingType = typeEnvironment.getType(name.id) {
                    // Check type compatibility
                    if !existingType.isCompatible(with: valueType) {
                        diagnostics.append(.error(
                            checkerId: id,
                            message: "Type mismatch: cannot assign \(valueType) to \(name.id) of type \(existingType)",
                            line: assign.lineno,
                            column: assign.colOffset
                        ))
                    }
                } else {
                    // Infer and store type
                    typeEnvironment.setType(name.id, type: valueType)
                }
            }
        }
        
        return diagnostics
    }
    
    private mutating func checkAnnAssign(_ annAssign: AnnAssign) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        // Parse annotation
        let annotatedType = TypeAnnotationParser.parse(annAssign.annotation)
        
        // Store annotated type
        if case .name(let name) = annAssign.target {
            typeEnvironment.setType(name.id, type: annotatedType)
            
            // If there's a value, check compatibility
            if let value = annAssign.value {
                let valueType = inferType(value)
                if !annotatedType.isCompatible(with: valueType) {
                    diagnostics.append(.error(
                        checkerId: id,
                        message: "Type mismatch: cannot assign \(valueType) to \(name.id): \(annotatedType)",
                        line: annAssign.lineno,
                        column: annAssign.colOffset,
                        suggestion: "Ensure the assigned value matches the annotated type"
                    ))
                }
            }
        }
        
        return diagnostics
    }
    
    // MARK: - Function Checking
    
    private mutating func checkFunctionDef(_ funcDef: FunctionDef) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        // Create new scope for function
        typeEnvironment.pushScope()
        
        // Register parameter types
        for arg in funcDef.args.args {
            if let annotation = arg.annotation {
                let paramType = TypeAnnotationParser.parse(annotation)
                typeEnvironment.setType(arg.arg, type: paramType)
            } else {
                typeEnvironment.setType(arg.arg, type: .any)
            }
        }
        
        // Store expected return type
        let expectedReturn = funcDef.returns.map { TypeAnnotationParser.parse($0) }
        typeEnvironment.setReturnType(expectedReturn)
        
        // Check function body
        for statement in funcDef.body {
            diagnostics.append(contentsOf: checkStatement(statement))
        }
        
        typeEnvironment.popScope()
        
        return diagnostics
    }
    
    private mutating func checkAsyncFunctionDef(_ funcDef: AsyncFunctionDef) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        typeEnvironment.pushScope()
        
        for arg in funcDef.args.args {
            if let annotation = arg.annotation {
                let paramType = TypeAnnotationParser.parse(annotation)
                typeEnvironment.setType(arg.arg, type: paramType)
            } else {
                typeEnvironment.setType(arg.arg, type: .any)
            }
        }
        
        let expectedReturn = funcDef.returns.map { TypeAnnotationParser.parse($0) }
        typeEnvironment.setReturnType(expectedReturn)
        
        for statement in funcDef.body {
            diagnostics.append(contentsOf: checkStatement(statement))
        }
        
        typeEnvironment.popScope()
        
        return diagnostics
    }
    
    private mutating func checkReturn(_ ret: Return) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        guard let expectedType = typeEnvironment.getReturnType() else {
            return diagnostics
        }
        
        if let value = ret.value {
            let actualType = inferType(value)
            if !expectedType.isCompatible(with: actualType) {
                diagnostics.append(.error(
                    checkerId: id,
                    message: "Return type mismatch: expected \(expectedType), got \(actualType)",
                    line: ret.lineno,
                    column: ret.colOffset
                ))
            }
        } else {
            // Returning None
            if !expectedType.isCompatible(with: .none) {
                diagnostics.append(.error(
                    checkerId: id,
                    message: "Return type mismatch: expected \(expectedType), got None",
                    line: ret.lineno,
                    column: ret.colOffset
                ))
            }
        }
        
        return diagnostics
    }
    
    // MARK: - Control Flow Checking
    
    private mutating func checkIf(_ ifStmt: If) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        for statement in ifStmt.body {
            diagnostics.append(contentsOf: checkStatement(statement))
        }
        
        for statement in ifStmt.orElse {
            diagnostics.append(contentsOf: checkStatement(statement))
        }
        
        return diagnostics
    }
    
    private mutating func checkFor(_ forStmt: For) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        // Infer iterator type
        let iterType = inferType(forStmt.iter)
        
        // Try to infer element type from iterator
        if case .list(let elemType) = iterType,
           case .name(let targetName) = forStmt.target {
            typeEnvironment.setType(targetName.id, type: elemType)
        }
        
        for statement in forStmt.body {
            diagnostics.append(contentsOf: checkStatement(statement))
        }
        
        for statement in forStmt.orElse {
            diagnostics.append(contentsOf: checkStatement(statement))
        }
        
        return diagnostics
    }
    
    private mutating func checkWhile(_ whileStmt: While) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        for statement in whileStmt.body {
            diagnostics.append(contentsOf: checkStatement(statement))
        }
        
        for statement in whileStmt.orElse {
            diagnostics.append(contentsOf: checkStatement(statement))
        }
        
        return diagnostics
    }
    
    // MARK: - Type Inference
    
    private func inferType(_ expr: Expression) -> PythonType {
        switch expr {
        case .constant(let constant):
            return inferConstantType(constant)
            
        case .name(let name):
            return typeEnvironment.getType(name.id) ?? .unknown
            
        case .binOp(let binOp):
            return inferBinOpType(binOp)
            
        case .unaryOp(let unaryOp):
            return inferUnaryOpType(unaryOp)
            
        case .compare:
            return .bool
            
        case .call(let call):
            return inferCallType(call)
            
        case .list(let list):
            return inferListType(list)
            
        case .dict(let dict):
            return inferDictType(dict)
            
        case .set(let set):
            return inferSetType(set)
            
        case .tuple(let tuple):
            return inferTupleType(tuple)
            
        case .ifExp(let ifExp):
            return inferIfExpType(ifExp)
            
        default:
            return .unknown
        }
    }
    
    private func inferConstantType(_ constant: Constant) -> PythonType {
        switch constant.value {
        case .int: return .int
        case .float: return .float
        case .complex: return .float // Treat complex as float for simplicity
        case .string: return .str
        case .bytes: return .bytes
        case .bool: return .bool
        case .none: return .none
        case .ellipsis: return .any
        }
    }
    
    private func inferBinOpType(_ binOp: BinOp) -> PythonType {
        let leftType = inferType(binOp.left)
        let rightType = inferType(binOp.right)
        
        // Simple numeric operations
        if leftType == .int && rightType == .int {
            switch binOp.op {
            case .div: return .float // Division always returns float
            default: return .int
            }
        }
        
        if (leftType == .float || rightType == .float) {
            return .float
        }
        
        // String concatenation
        if leftType == .str && rightType == .str {
            switch binOp.op {
            case .add: return .str
            default: return .unknown
            }
        }
        
        return .unknown
    }
    
    private func inferUnaryOpType(_ unaryOp: UnaryOp) -> PythonType {
        let operandType = inferType(unaryOp.operand)
        
        switch unaryOp.op {
        case .not:
            return .bool
        case .uSub, .uAdd:
            return operandType
        case .invert:
            return operandType
        }
    }
    
    private func inferCallType(_ call: Call) -> PythonType {
        // Try to infer from function name
        if case .name(let name) = call.fun {
            switch name.id {
            case "int": return .int
            case "float": return .float
            case "str": return .str
            case "bool": return .bool
            case "list": return .list(.any)
            case "dict": return .dict(key: .any, value: .any)
            case "set": return .set(.any)
            case "tuple": return .tuple([.any])
            default:
                return .unknown
            }
        }
        
        return .unknown
    }
    
    private func inferListType(_ list: List) -> PythonType {
        if list.elts.isEmpty {
            return .list(.any)
        }
        
        // Infer from first element
        let firstType = inferType(list.elts[0])
        return .list(firstType)
    }
    
    private func inferDictType(_ dict: Dict) -> PythonType {
        if dict.keys.isEmpty {
            return .dict(key: .any, value: .any)
        }
        
        // Find first non-nil key
        guard let firstKey = dict.keys.compactMap({ $0 }).first,
              let firstValue = dict.values.first else {
            return .dict(key: .any, value: .any)
        }
        
        let keyType = inferType(firstKey)
        let valueType = inferType(firstValue)
        return .dict(key: keyType, value: valueType)
    }
    
    private func inferSetType(_ set: Set) -> PythonType {
        if set.elts.isEmpty {
            return .set(.any)
        }
        
        let elemType = inferType(set.elts[0])
        return .set(elemType)
    }
    
    private func inferTupleType(_ tuple: Tuple) -> PythonType {
        let types = tuple.elts.map { inferType($0) }
        return .tuple(types)
    }
    
    private func inferIfExpType(_ ifExp: IfExp) -> PythonType {
        let trueType = inferType(ifExp.body)
        let falseType = inferType(ifExp.orElse)
        
        if trueType == falseType {
            return trueType
        }
        
        return .union([trueType, falseType])
    }
}

// MARK: - Type Environment

/// Manages variable types and scopes during type checking
private struct TypeEnvironment {
    private var scopes: [[String: PythonType]] = [[:]]
    private var returnTypes: [PythonType?] = [nil]
    
    mutating func pushScope() {
        scopes.append([:])
        returnTypes.append(nil)
    }
    
    mutating func popScope() {
        if scopes.count > 1 {
            scopes.removeLast()
            returnTypes.removeLast()
        }
    }
    
    mutating func setType(_ name: String, type: PythonType) {
        scopes[scopes.count - 1][name] = type
    }
    
    func getType(_ name: String) -> PythonType? {
        // Search from innermost to outermost scope
        for scope in scopes.reversed() {
            if let type = scope[name] {
                return type
            }
        }
        return nil
    }
    
    mutating func setReturnType(_ type: PythonType?) {
        returnTypes[returnTypes.count - 1] = type
    }
    
    func getReturnType() -> PythonType? {
        returnTypes.last ?? nil
    }
}
