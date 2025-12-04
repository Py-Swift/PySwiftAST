import PySwiftAST
import PySwiftCodeGen

// MARK: - Built-in Types Registry

/// Registry of built-in Python type methods and their return types
struct BuiltinTypesRegistry {
    /// Get the return type of a method for a given type
    static func getMethodReturnType(forType type: PythonType, methodName: String) -> PythonType? {
        switch type {
        case .str:
            return stringMethods[methodName]
        case .list:
            return listMethods[methodName]
        case .dict:
            return dictMethods[methodName]
        case .set:
            return setMethods[methodName]
        case .tuple:
            return tupleMethods[methodName]
        case .int:
            return intMethods[methodName]
        case .float:
            return floatMethods[methodName]
        case .bool:
            return boolMethods[methodName]
        default:
            return nil
        }
    }
    
    // String methods
    private static let stringMethods: [String: PythonType] = [
        "upper": .str,
        "lower": .str,
        "capitalize": .str,
        "title": .str,
        "strip": .str,
        "lstrip": .str,
        "rstrip": .str,
        "replace": .str,
        "split": .list(.str),
        "join": .str,
        "startswith": .bool,
        "endswith": .bool,
        "find": .int,
        "rfind": .int,
        "index": .int,
        "rindex": .int,
        "count": .int,
        "isalpha": .bool,
        "isdigit": .bool,
        "isalnum": .bool,
        "isspace": .bool,
        "islower": .bool,
        "isupper": .bool,
        "format": .str,
        "encode": .any, // bytes
        "zfill": .str,
        "center": .str,
        "ljust": .str,
        "rjust": .str,
    ]
    
    // List methods
    private static let listMethods: [String: PythonType] = [
        "append": .none,
        "extend": .none,
        "insert": .none,
        "remove": .none,
        "pop": .any, // Returns element type
        "clear": .none,
        "index": .int,
        "count": .int,
        "sort": .none,
        "reverse": .none,
        "copy": .any, // Returns list copy
    ]
    
    // Dict methods
    private static let dictMethods: [String: PythonType] = [
        "keys": .any, // dict_keys
        "values": .any, // dict_values
        "items": .any, // dict_items
        "get": .any, // Returns value type or None
        "pop": .any, // Returns value type
        "popitem": .any, // tuple
        "clear": .none,
        "update": .none,
        "setdefault": .any,
        "copy": .any, // Returns dict copy
    ]
    
    // Set methods
    private static let setMethods: [String: PythonType] = [
        "add": .none,
        "remove": .none,
        "discard": .none,
        "pop": .any, // Returns element
        "clear": .none,
        "union": .any, // Returns set
        "intersection": .any, // Returns set
        "difference": .any, // Returns set
        "symmetric_difference": .any, // Returns set
        "update": .none,
        "intersection_update": .none,
        "difference_update": .none,
        "symmetric_difference_update": .none,
        "issubset": .bool,
        "issuperset": .bool,
        "isdisjoint": .bool,
        "copy": .any, // Returns set copy
    ]
    
    // Tuple methods (limited - tuples are immutable)
    private static let tupleMethods: [String: PythonType] = [
        "count": .int,
        "index": .int,
    ]
    
    // Int methods
    private static let intMethods: [String: PythonType] = [
        "bit_length": .int,
        "to_bytes": .any, // bytes
        "from_bytes": .int, // classmethod
    ]
    
    // Float methods
    private static let floatMethods: [String: PythonType] = [
        "is_integer": .bool,
        "as_integer_ratio": .tuple([.int, .int]),
        "hex": .str,
        "fromhex": .float, // classmethod
    ]
    
    // Bool methods (inherits from int, but listed separately)
    private static let boolMethods: [String: PythonType] = [:]
}

/// Static type checker for Python code with queryable type analysis
///
/// Performs type inference and type checking based on:
/// - Variable annotations (x: int = 5)
/// - Function annotations (def f(x: int) -> str)
/// - Inferred types from literals and operations
/// - Type compatibility rules
///
/// Provides query APIs for IDE features:
/// - analyze(module:) - Analyze a module and cache results for queries
/// - getTypeAt(name:line:column:) - Get type of symbol at position
/// - getVariableType(name:at:) - Get type of variable (simpler API)
/// - getScopeAt(line:column:) - Get containing scope
/// - getSymbolsAt(line:column:) - Get all accessible symbols
/// - getClassMembers(className:) - Get class properties and methods
/// - getClassContext(lineNumber:) - Get name of containing class
/// - getClassProperties(at:) - Get properties of class at line
/// - getAllVariablesInScope(at:) - Get all variables as [String: String]
/// - variableExists(name:anywhere:) - Check if variable exists
public final class TypeChecker: PyChecker {
    public let id = "type-checker"
    public let name = "Type Checker"
    public let description = "Static type checking with type inference and IDE queries"
    
    private var visitor: TypeCheckingVisitor
    private var currentModule: Module?
    
    public init() {
        self.visitor = TypeCheckingVisitor()
    }
    
    /// Analyze a module and cache the results for querying
    /// - Parameter module: The module to analyze
    /// - Returns: Diagnostics found during analysis
    public func analyze(_ module: Module) -> [Diagnostic] {
        self.currentModule = module
        visitor = TypeCheckingVisitor() // Fresh visitor for new analysis
        visitor.visitModule(module)
        return visitor.diagnostics
    }
    
    /// Legacy method for PyChecker protocol - delegates to analyze()
    public func check(_ module: Module) -> [Diagnostic] {
        return analyze(module)
    }
    
    // MARK: - Query APIs for IDE Features
    
    /// Get the type of a symbol at a specific location
    /// - Parameters:
    ///   - name: Symbol name to look up
    ///   - line: Line number (1-indexed)
    ///   - column: Column number (0-indexed)
    /// - Returns: The inferred type, or nil if not found
    public func getTypeAt(name: String, line: Int, column: Int) -> PythonType? {
        return visitor.typeEnvironment.getType(name, at: line)
    }
    
    /// Get the type of a variable as a string (simplified API matching ASTCore)
    /// - Parameters:
    ///   - name: Variable name
    ///   - lineNumber: Optional line number for scope-aware lookup
    /// - Returns: Type as a display string, or nil if not found
    public func getVariableType(_ name: String, at lineNumber: Int? = nil) -> String? {
        if let line = lineNumber {
            return visitor.typeEnvironment.getType(name, at: line)?.toDisplayString()
        } else {
            // No line number - find the most recent definition
            return visitor.typeEnvironment.getType(name, at: 999999)?.toDisplayString()
        }
    }
    
    /// Get all symbols accessible at a specific location
    /// - Parameters:
    ///   - line: Line number (1-indexed)
    ///   - column: Column number (0-indexed)
    /// - Returns: Array of (name, type) tuples for all accessible symbols
    public func getSymbolsAt(line: Int, column: Int) -> [(name: String, type: PythonType)] {
        return visitor.typeEnvironment.getAllSymbolsInScope(at: line)
    }
    
    /// Get all variables in scope as a dictionary (matching ASTCore API)
    /// - Parameter lineNumber: Line number (1-indexed)
    /// - Returns: Dictionary mapping variable names to type strings
    public func getAllVariablesInScope(at lineNumber: Int) -> [String: String] {
        let symbols = visitor.typeEnvironment.getAllSymbolsInScope(at: lineNumber)
        var result: [String: String] = [:]
        for (name, type) in symbols {
            result[name] = type.toDisplayString()
        }
        return result
    }
    
    /// Get the containing scope at a specific location
    /// - Parameters:
    ///   - line: Line number (1-indexed)
    ///   - column: Column number (0-indexed)
    /// - Returns: The scope information, or nil if not in a specific scope
    public func getScopeAt(line: Int, column: Int) -> ScopeInfo? {
        return visitor.scopeTracker.getScopeAt(line: line)
    }
    
    /// Get the name of the containing class at a line number
    /// - Parameter lineNumber: Line number (1-indexed)
    /// - Returns: Class name if inside a class, nil otherwise
    public func getClassContext(lineNumber: Int) -> String? {
        // Get scope chain and find the first class scope
        let scopes = visitor.scopeTracker.getScopeChainAt(line: lineNumber)
        for scope in scopes {
            if scope.kind == .classScope {
                return scope.name
            }
        }
        return nil
    }
    
    /// Get all scopes at a position (returns chain from outermost to innermost)
    /// - Parameters:
    ///   - line: Line number (1-indexed)
    ///   - column: Column number (0-indexed)
    /// - Returns: Array of scopes from module to innermost containing scope
    public func getScopeChainAt(line: Int, column: Int) -> [ScopeInfo] {
        return visitor.scopeTracker.getScopeChainAt(line: line)
    }
    
    /// Check if a line is inside a specific scope type
    /// - Parameters:
    ///   - line: Line number (1-indexed)
    ///   - column: Column number (0-indexed)
    ///   - kind: The scope kind to check for
    /// - Returns: True if the line is inside a scope of the specified kind
    public func isInScope(line: Int, column: Int, kind: ScopeKind) -> Bool {
        let chain = visitor.scopeTracker.getScopeChainAt(line: line)
        return chain.contains { $0.kind == kind }
    }
    
    /// Get all members of a class
    /// - Parameter className: Name of the class
    /// - Returns: Array of class members (properties and methods)
    public func getClassMembers(className: String) -> [MemberInfo] {
        return visitor.classRegistry.getMembers(className)
    }
    
    /// Get properties of the class at a specific line
    /// - Parameter lineNumber: Line number (1-indexed)
    /// - Returns: Dictionary mapping property names to type strings
    public func getClassProperties(at lineNumber: Int) -> [String: String] {
        guard let className = getClassContext(lineNumber: lineNumber) else {
            return [:]
        }
        
        let members = visitor.classRegistry.getMembers(className)
        var properties: [String: String] = [:]
        for member in members where member.kind == .property {
            properties[member.name] = member.type.toDisplayString()
        }
        return properties
    }
    
    /// Get the type of a specific property in a class
    /// - Parameters:
    ///   - className: Name of the class
    ///   - propertyName: Name of the property
    /// - Returns: Type as a display string, or nil if not found
    public func getPropertyType(className: String, propertyName: String) -> String? {
        let members = visitor.classRegistry.getMembers(className)
        if let member = members.first(where: { $0.name == propertyName && $0.kind == .property }) {
            return member.type.toDisplayString()
        }
        return nil
    }
    
    /// Get the class definition at a specific line number
    /// - Parameter lineNumber: Line number (1-indexed)
    /// - Returns: Tuple of (class name, generated code) if found, nil otherwise
    public func getClassDefinition(at lineNumber: Int) -> (name: String, code: String)? {
        guard case .module(let statements) = currentModule else { return nil }
        
        // Find the class definition that contains this line
        func findClassInStatements(_ statements: [Statement]) -> (ClassDef, String)? {
            for statement in statements {
                if case .classDef(let classDef) = statement {
                    let endLine = classDef.endLineno ?? classDef.body.last?.lineno ?? classDef.lineno
                    if classDef.lineno <= lineNumber && lineNumber <= endLine {
                        // Generate code for this class
                        let code = statement.toPythonCode(context: CodeGenContext())
                        return (classDef, code)
                    }
                }
                
                // Search nested statements (e.g., classes inside functions)
                switch statement {
                case .functionDef(let funcDef):
                    if let found = findClassInStatements(funcDef.body) {
                        return found
                    }
                case .asyncFunctionDef(let funcDef):
                    if let found = findClassInStatements(funcDef.body) {
                        return found
                    }
                case .classDef(let classDef):
                    if let found = findClassInStatements(classDef.body) {
                        return found
                    }
                case .forStmt(let forStmt):
                    if let found = findClassInStatements(forStmt.body) {
                        return found
                    }
                    if let found = findClassInStatements(forStmt.orElse) {
                        return found
                    }
                case .asyncFor(let forStmt):
                    if let found = findClassInStatements(forStmt.body) {
                        return found
                    }
                    if let found = findClassInStatements(forStmt.orElse) {
                        return found
                    }
                case .whileStmt(let whileStmt):
                    if let found = findClassInStatements(whileStmt.body) {
                        return found
                    }
                    if let found = findClassInStatements(whileStmt.orElse) {
                        return found
                    }
                case .ifStmt(let ifStmt):
                    if let found = findClassInStatements(ifStmt.body) {
                        return found
                    }
                    if let found = findClassInStatements(ifStmt.orElse) {
                        return found
                    }
                case .withStmt(let withStmt):
                    if let found = findClassInStatements(withStmt.body) {
                        return found
                    }
                case .asyncWith(let withStmt):
                    if let found = findClassInStatements(withStmt.body) {
                        return found
                    }
                case .tryStmt(let tryStmt):
                    if let found = findClassInStatements(tryStmt.body) {
                        return found
                    }
                    for handler in tryStmt.handlers {
                        if let found = findClassInStatements(handler.body) {
                            return found
                        }
                    }
                    if let found = findClassInStatements(tryStmt.orElse) {
                        return found
                    }
                    if let found = findClassInStatements(tryStmt.finalBody) {
                        return found
                    }
                case .tryStar(let tryStmt):
                    if let found = findClassInStatements(tryStmt.body) {
                        return found
                    }
                    for handler in tryStmt.handlers {
                        if let found = findClassInStatements(handler.body) {
                            return found
                        }
                    }
                    if let found = findClassInStatements(tryStmt.orElse) {
                        return found
                    }
                    if let found = findClassInStatements(tryStmt.finalBody) {
                        return found
                    }
                case .match(let matchStmt):
                    for matchCase in matchStmt.cases {
                        if let found = findClassInStatements(matchCase.body) {
                            return found
                        }
                    }
                default:
                    break
                }
            }
            return nil
        }
        
        if let (classDef, code) = findClassInStatements(statements) {
            return (name: classDef.name, code: code)
        }
        
        return nil
    }
    
    /// Get a global constant's type and value
    /// - Parameter name: The constant name
    /// - Returns: Tuple of (type: String, value: String) if found, nil otherwise
    public func getGlobalConstant(name: String) -> (type: String, value: String)? {
        guard case .module(let statements) = currentModule else { return nil }
        
        // Search for module-level assignments to this name
        for statement in statements {
            if case .assign(let assign) = statement {
                // Check if any target is this name
                for target in assign.targets {
                    if case .name(let nameExpr) = target, nameExpr.id == name {
                        // Get the type from type environment
                        let type = visitor.typeEnvironment.getType(name, at: assign.lineno)
                        let typeString = type?.toDisplayString() ?? "Any"
                        
                        // Generate value string using PySwiftCodeGen
                        let valueString = assign.value.toPythonCode(context: CodeGenContext())
                        
                        return (type: typeString, value: valueString)
                    }
                }
            } else if case .annAssign(let annAssign) = statement {
                // Annotated assignment: x: int = 5
                if case .name(let target) = annAssign.target, target.id == name {
                    // Use annotation for type
                    let typeString = annAssign.annotation.toPythonCode(context: CodeGenContext())
                    
                    // Get value if present
                    let valueString: String
                    if let value = annAssign.value {
                        valueString = value.toPythonCode(context: CodeGenContext())
                    } else {
                        valueString = "..."  // No value assigned yet
                    }
                    
                    return (type: typeString, value: valueString)
                }
            }
        }
        
        return nil
    }
    
    /// Get a method definition including signature and full code
    /// - Parameters:
    ///   - className: The class name
    ///   - methodName: The method name
    /// - Returns: Tuple of (signature: String, code: String) if found, nil otherwise
    public func getMethodDefinition(className: String, methodName: String) -> (signature: String, code: String)? {
        guard case .module(let statements) = currentModule else { return nil }
        
        // Find the class definition
        func findClass(_ name: String, in statements: [Statement]) -> ClassDef? {
            for statement in statements {
                if case .classDef(let classDef) = statement, classDef.name == name {
                    return classDef
                }
                // Search nested structures
                switch statement {
                case .functionDef(let funcDef):
                    if let found = findClass(name, in: funcDef.body) {
                        return found
                    }
                case .asyncFunctionDef(let funcDef):
                    if let found = findClass(name, in: funcDef.body) {
                        return found
                    }
                case .classDef(let classDef):
                    if let found = findClass(name, in: classDef.body) {
                        return found
                    }
                default:
                    break
                }
            }
            return nil
        }
        
        guard let classDef = findClass(className, in: statements) else { return nil }
        
        // Find the method in the class body
        for statement in classDef.body {
            switch statement {
            case .functionDef(let funcDef) where funcDef.name == methodName:
                let fullCode = statement.toPythonCode(context: CodeGenContext())
                // Extract signature (first line)
                let lines = fullCode.components(separatedBy: .newlines)
                let signature = lines.first ?? ""
                return (signature: signature, code: fullCode)
                
            case .asyncFunctionDef(let funcDef) where funcDef.name == methodName:
                let fullCode = statement.toPythonCode(context: CodeGenContext())
                // Extract signature (first line)
                let lines = fullCode.components(separatedBy: .newlines)
                let signature = lines.first ?? ""
                return (signature: signature, code: fullCode)
                
            default:
                continue
            }
        }
        
        return nil
    }
    
    /// Check if a variable exists in scope
    /// - Parameters:
    ///   - name: Variable name
    ///   - anywhere: If true, searches all scopes; if false, only current scope
    /// - Returns: True if variable exists
    public func variableExists(_ name: String, anywhere: Bool = false) -> Bool {
        guard case .module(let statements) = currentModule else {
            return false
        }
        
        if anywhere {
            return searchVariableAnywhereInStatements(statements, name: name)
        } else {
            return visitor.typeEnvironment.variableExists(name)
        }
    }
    
    /// Check if a variable follows the constant naming convention (UPPERCASE)
    /// - Parameter name: Variable name to check
    /// - Returns: True if the variable is defined as a constant
    public func isConstant(_ name: String) -> Bool {
        return visitor.typeEnvironment.isConstant(name)
    }
    
    // MARK: - Private Scope-Aware Search Methods
    
    /// Find the scope chain (local + global statements) for a given line number
    private func findScopeChain(at lineNumber: Int, in statements: [Statement], globals: [Statement], inClass: ClassDef? = nil) -> ScopeChain? {
        for statement in statements {
            switch statement {
            case .functionDef(let funcDef):
                let funcEndLine = statement.endLineno ?? funcDef.body.last?.lineno ?? funcDef.lineno
                if funcDef.lineno <= lineNumber && lineNumber <= funcEndLine {
                    return ScopeChain(
                        localStatements: funcDef.body,
                        classStatements: inClass.map { [$0].map { Statement.classDef($0) } },
                        globalStatements: globals,
                        lineNumber: lineNumber
                    )
                }
                
            case .asyncFunctionDef(let funcDef):
                let funcEndLine = statement.endLineno ?? funcDef.body.last?.lineno ?? funcDef.lineno
                if funcDef.lineno <= lineNumber && lineNumber <= funcEndLine {
                    return ScopeChain(
                        localStatements: funcDef.body,
                        classStatements: inClass.map { [$0].map { Statement.classDef($0) } },
                        globalStatements: globals,
                        lineNumber: lineNumber
                    )
                }
                
            case .classDef(let classDef):
                let classEndLine = statement.endLineno ?? classDef.body.last?.lineno ?? classDef.lineno
                if classDef.lineno <= lineNumber && lineNumber <= classEndLine {
                    // Recursively search within the class for nested functions
                    if let nestedScope = findScopeChain(at: lineNumber, in: classDef.body, globals: globals, inClass: classDef) {
                        return nestedScope
                    }
                    // If not in a nested function, it's in class scope (but class vars aren't accessible without self.)
                    return ScopeChain(
                        localStatements: [],
                        classStatements: classDef.body,
                        globalStatements: globals,
                        lineNumber: lineNumber
                    )
                }
                
            default:
                break
            }
        }
        
        return nil
    }
    
    /// Search for a variable anywhere in statements (recursive)
    private func searchVariableAnywhereInStatements(_ statements: [Statement], name: String) -> Bool {
        for stmt in statements {
            switch stmt {
            case .assign(let assign):
                for target in assign.targets {
                    if case let .name(nameExpr) = target, nameExpr.id == name {
                        return true
                    }
                }
            case .annAssign(let annAssign):
                if case let .name(target) = annAssign.target, target.id == name {
                    return true
                }
            case .functionDef(let funcDef):
                if searchVariableAnywhereInStatements(funcDef.body, name: name) {
                    return true
                }
            case .asyncFunctionDef(let funcDef):
                if searchVariableAnywhereInStatements(funcDef.body, name: name) {
                    return true
                }
            case .classDef(let classDef):
                if searchVariableAnywhereInStatements(classDef.body, name: name) {
                    return true
                }
            default:
                break
            }
        }
        return false
    }
    
    /// Search for a variable in statements
    private func searchVariableInStatements(_ statements: [Statement], name: String, at lineNumber: Int?) -> PythonType? {
        var mostRecentAssignment: (line: Int, type: PythonType)? = nil
        
        for stmt in statements {
            switch stmt {
            case .assign(let assign):
                for target in assign.targets {
                    if case let .name(nameExpr) = target, nameExpr.id == name {
                        if let queryLine = lineNumber {
                            if assign.lineno <= queryLine {
                                let type = PythonType.fromExpression(assign.value)
                                if mostRecentAssignment == nil || assign.lineno > mostRecentAssignment!.line {
                                    mostRecentAssignment = (line: assign.lineno, type: type)
                                }
                            }
                        } else {
                            return PythonType.fromExpression(assign.value)
                        }
                    }
                }
            case .annAssign(let annAssign):
                if case let .name(target) = annAssign.target, target.id == name {
                    if let queryLine = lineNumber {
                        if annAssign.lineno <= queryLine {
                            let type = PythonType.fromExpression(annAssign.annotation)
                            if mostRecentAssignment == nil || annAssign.lineno > mostRecentAssignment!.line {
                                mostRecentAssignment = (line: annAssign.lineno, type: type)
                            }
                        }
                    } else {
                        return PythonType.fromExpression(annAssign.annotation)
                    }
                }
            default:
                break
            }
        }
        
        return mostRecentAssignment?.type
    }
    
    /// Get the diagnostics from the last check
    public func getDiagnostics() -> [Diagnostic] {
        return visitor.diagnostics
    }
    
    /// Get the currently analyzed module
    public func getCurrentModule() -> Module? {
        return currentModule
    }
}

// MARK: - Type Checking Visitor

/// Internal visitor that performs type checking and analysis
private class TypeCheckingVisitor: StatementVisitor, ExpressionVisitor {
    typealias StatementResult = Void
    typealias ExpressionResult = PythonType
    
    var diagnostics: [Diagnostic] = []
    var typeEnvironment = TypeEnvironment()
    var classRegistry = ClassRegistry()
    var scopeTracker = ScopeTracker()
    
    init() {}
    
    // MARK: - Helper Methods
    
    /// Calculate the actual end line of a list of statements by recursively finding the last line
    private func calculateEndLine(_ statements: [Statement]) -> Int? {
        guard let lastStmt = statements.last else { return nil }
        
        switch lastStmt {
        case .functionDef(let funcDef):
            return funcDef.endLineno ?? calculateEndLine(funcDef.body) ?? funcDef.lineno
        case .asyncFunctionDef(let funcDef):
            return funcDef.endLineno ?? calculateEndLine(funcDef.body) ?? funcDef.lineno
        case .classDef(let classDef):
            return classDef.endLineno ?? calculateEndLine(classDef.body) ?? classDef.lineno
        case .ifStmt(let ifStmt):
            // Check orElse first as it comes last, then body
            if let elseEnd = calculateEndLine(ifStmt.orElse) {
                return elseEnd
            }
            return calculateEndLine(ifStmt.body) ?? ifStmt.lineno
        case .whileStmt(let whileStmt):
            if let elseEnd = calculateEndLine(whileStmt.orElse) {
                return elseEnd
            }
            return calculateEndLine(whileStmt.body) ?? whileStmt.lineno
        case .forStmt(let forStmt):
            if let elseEnd = calculateEndLine(forStmt.orElse) {
                return elseEnd
            }
            return calculateEndLine(forStmt.body) ?? forStmt.lineno
        case .withStmt(let withStmt):
            return calculateEndLine(withStmt.body) ?? withStmt.lineno
        case .tryStmt(let tryStmt):
            // Check orElse, finalBody, then handlers, then body
            if let finalEnd = calculateEndLine(tryStmt.finalBody) {
                return finalEnd
            }
            if let elseEnd = calculateEndLine(tryStmt.orElse) {
                return elseEnd
            }
            if let lastHandler = tryStmt.handlers.last {
                if let handlerEnd = calculateEndLine(lastHandler.body) {
                    return handlerEnd
                }
            }
            return calculateEndLine(tryStmt.body) ?? tryStmt.lineno
        default:
            // For simple statements, return their line number
            return lastStmt.lineno
        }
    }
    
    // MARK: - Module Visitation
    
    func visitModule(_ module: Module) {
        let statements: [Statement] = switch module {
        case .module(let stmts), .interactive(let stmts):
            stmts
        default:
            []
        }
        
        // Track module scope
        scopeTracker.enterScope(kind: .module, name: nil, startLine: 1, endLine: Int.max)
        
        for statement in statements {
            visitStatement(statement)
        }
        
        scopeTracker.exitScope()
    }
    
    // MARK: - Statement Visitors
    
    func visitAssign(_ node: Assign) {
        let valueType = visitExpression(node.value)
        
        for target in node.targets {
            if case .name(let name) = target {
                // Check if this is a constant reassignment
                if typeEnvironment.isConstant(name.id) {
                    diagnostics.append(.warning(
                        checkerId: "type-checker",
                        message: "Constant \(name.id) is being reassigned",
                        line: node.lineno,
                        column: node.colOffset
                    ))
                }
                
                // Check if variable already has a type
                if let existingType = typeEnvironment.getType(name.id, at: node.lineno) {
                    // Check type compatibility
                    if !existingType.isCompatible(with: valueType) {
                        diagnostics.append(.error(
                            checkerId: "type-checker",
                            message: "Type mismatch: cannot assign \(valueType) to \(name.id) of type \(existingType)",
                            line: node.lineno,
                            column: node.colOffset
                        ))
                    }
                }
                
                // Store type with line number for scope-aware lookup
                typeEnvironment.setType(name.id, type: valueType, at: node.lineno)
            } else if case .tuple(let tupleNode) = target {
                // Handle tuple unpacking: a, b = (1, "hello") or first, *rest = [1, 2, 3]
                if case .tuple(let types) = valueType {
                    // Assign each element type to corresponding variable
                    for (index, element) in tupleNode.elts.enumerated() {
                        if case .name(let name) = element, index < types.count {
                            typeEnvironment.setType(name.id, type: types[index], at: node.lineno)
                        } else if case .starred(let starredNode) = element {
                            // Handle *rest in unpacking
                            if case .name(let name) = starredNode.value {
                                // Remaining elements go into a list
                                let remainingTypes = Array(types.dropFirst(index))
                                let listType: PythonType = remainingTypes.isEmpty ? .list(.any) : .list(remainingTypes[0])
                                typeEnvironment.setType(name.id, type: listType, at: node.lineno)
                            }
                        }
                    }
                } else if case .list(let elementType) = valueType {
                    // Unpacking from list: first, *rest = [1, 2, 3]
                    for element in tupleNode.elts {
                        if case .name(let name) = element {
                            typeEnvironment.setType(name.id, type: elementType, at: node.lineno)
                        } else if case .starred(let starredNode) = element {
                            // Handle *rest in unpacking from list
                            if case .name(let name) = starredNode.value {
                                typeEnvironment.setType(name.id, type: .list(elementType), at: node.lineno)
                            }
                        }
                    }
                } else {
                    // Value is not a tuple or list - try to extract element type for iteration
                    let elementType = extractElementType(from: valueType)
                    for element in tupleNode.elts {
                        if case .name(let name) = element {
                            typeEnvironment.setType(name.id, type: elementType, at: node.lineno)
                        } else if case .starred(let starredNode) = element {
                            if case .name(let name) = starredNode.value {
                                typeEnvironment.setType(name.id, type: .list(elementType), at: node.lineno)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func visitAnnAssign(_ node: AnnAssign) {
        let annotatedType = PythonType.fromExpression(node.annotation)
        
        if case .name(let name) = node.target {
            typeEnvironment.setType(name.id, type: annotatedType, at: node.lineno)
            
            // If there's a value, check compatibility
            if let value = node.value {
                let valueType = visitExpression(value)
                if !annotatedType.isCompatible(with: valueType) {
                    diagnostics.append(.error(
                        checkerId: "type-checker",
                        message: "Type mismatch: cannot assign \(valueType) to \(name.id): \(annotatedType)",
                        line: node.lineno,
                        column: node.colOffset
                    ))
                }
            }
        }
    }
    
    func visitAugAssign(_ node: AugAssign) {
        // Handle augmented assignments like +=, -=, etc.
        let valueType = visitExpression(node.value)
        
        if case .name(let name) = node.target {
            if let existingType = typeEnvironment.getType(name.id, at: node.lineno) {
                // Check type compatibility for augmented assignment
                // For numeric types, result should be compatible
                var resultType = existingType
                
                switch node.op {
                case .add:
                    // str += str, int += int, list += list
                    if existingType == .str && valueType == .str {
                        resultType = .str
                    } else if existingType == .int && valueType == .int {
                        resultType = .int
                    } else if (existingType == .int || existingType == .float) && (valueType == .int || valueType == .float) {
                        resultType = .float
                    } else if case .list(let elemType) = existingType, case .list = valueType {
                        resultType = .list(elemType)
                    }
                case .sub, .mult, .div, .floorDiv, .mod, .pow:
                    // Numeric operations
                    if existingType == .int && valueType == .int {
                        resultType = node.op == .div ? .float : .int
                    } else if (existingType == .int || existingType == .float) && (valueType == .int || valueType == .float) {
                        resultType = .float
                    }
                case .matMult, .bitOr, .bitXor, .bitAnd, .lShift, .rShift:
                    // Preserve type for these operations
                    break
                }
                
                typeEnvironment.setType(name.id, type: resultType, at: node.lineno)
            } else {
                // Variable not yet defined, infer from value
                typeEnvironment.setType(name.id, type: valueType, at: node.lineno)
            }
        }
    }
    
    func visitFunctionDef(_ node: FunctionDef) {
        // Register function with its return type in outer scope (before entering function scope)
        let returnType = node.returns.map { PythonType.fromExpression($0) } ?? .any
        typeEnvironment.setType(node.name, type: returnType, at: node.lineno)
        
        // Use actual end line from AST node, or calculate from body
        let endLine = node.endLineno ?? calculateEndLine(node.body) ?? node.lineno
        
        // Check if we're inside a class
        let containingClass = scopeTracker.getScopeAt(line: node.lineno)?.kind == .classScope 
            ? scopeTracker.getScopeAt(line: node.lineno)?.name 
            : nil
        
        // Check decorators for method type
        let isStaticMethod = node.decoratorList.contains { decorator in
            if case .name(let name) = decorator, name.id == "staticmethod" {
                return true
            }
            return false
        }
        
        let isClassMethod = node.decoratorList.contains { decorator in
            if case .name(let name) = decorator, name.id == "classmethod" {
                return true
            }
            return false
        }
        
        // Track function scope
        scopeTracker.enterScope(kind: .function, name: node.name, startLine: node.lineno, endLine: endLine)
        typeEnvironment.pushScope(startLine: node.lineno, endLine: endLine)
        
        // Register parameter types
        for (index, arg) in node.args.args.enumerated() {
            if let annotation = arg.annotation {
                let paramType = PythonType.fromExpression(annotation)
                typeEnvironment.setType(arg.arg, type: paramType, at: node.lineno)
            } else {
                // Special handling for first parameter in methods
                if index == 0 && containingClass != nil && !isStaticMethod {
                    if isClassMethod {
                        // First param in @classmethod is 'cls' - reference to the class itself
                        if let className = containingClass {
                            typeEnvironment.setType(arg.arg, type: .classType(className), at: node.lineno)
                        } else {
                            typeEnvironment.setType(arg.arg, type: .any, at: node.lineno)
                        }
                    } else {
                        // First param in regular method is 'self' - reference to class instance
                        if let className = containingClass {
                            typeEnvironment.setType(arg.arg, type: .instance(className), at: node.lineno)
                        } else {
                            typeEnvironment.setType(arg.arg, type: .any, at: node.lineno)
                        }
                    }
                } else {
                    typeEnvironment.setType(arg.arg, type: .any, at: node.lineno)
                }
            }
        }
        
        // Store expected return type
        let expectedReturn = node.returns.map { PythonType.fromExpression($0) }
        typeEnvironment.setReturnType(expectedReturn)
        
        // Check function body
        for statement in node.body {
            visitStatement(statement)
        }
        
        typeEnvironment.popScope()
        scopeTracker.exitScope()
    }
    
    func visitAsyncFunctionDef(_ node: AsyncFunctionDef) {
        // Register async function with its return type in outer scope
        let returnType = node.returns.map { PythonType.fromExpression($0) } ?? .any
        typeEnvironment.setType(node.name, type: returnType, at: node.lineno)
        
        let endLine = node.endLineno ?? calculateEndLine(node.body) ?? node.lineno
        
        // Check if we're inside a class
        let containingClass = scopeTracker.getScopeAt(line: node.lineno)?.kind == .classScope 
            ? scopeTracker.getScopeAt(line: node.lineno)?.name 
            : nil
        
        // Check decorators for method type
        let isStaticMethod = node.decoratorList.contains { decorator in
            if case .name(let name) = decorator, name.id == "staticmethod" {
                return true
            }
            return false
        }
        
        let isClassMethod = node.decoratorList.contains { decorator in
            if case .name(let name) = decorator, name.id == "classmethod" {
                return true
            }
            return false
        }
        
        scopeTracker.enterScope(kind: .function, name: node.name, startLine: node.lineno, endLine: endLine)
        typeEnvironment.pushScope(startLine: node.lineno, endLine: endLine)
        
        for (index, arg) in node.args.args.enumerated() {
            if let annotation = arg.annotation {
                let paramType = PythonType.fromExpression(annotation)
                typeEnvironment.setType(arg.arg, type: paramType, at: node.lineno)
            } else {
                // Special handling for first parameter in methods
                if index == 0 && containingClass != nil && !isStaticMethod {
                    if isClassMethod {
                        // First param in @classmethod is 'cls' - reference to the class itself
                        if let className = containingClass {
                            typeEnvironment.setType(arg.arg, type: .classType(className), at: node.lineno)
                        } else {
                            typeEnvironment.setType(arg.arg, type: .any, at: node.lineno)
                        }
                    } else {
                        // First param in regular method is 'self' - reference to class instance
                        if let className = containingClass {
                            typeEnvironment.setType(arg.arg, type: .instance(className), at: node.lineno)
                        } else {
                            typeEnvironment.setType(arg.arg, type: .any, at: node.lineno)
                        }
                    }
                } else {
                    typeEnvironment.setType(arg.arg, type: .any, at: node.lineno)
                }
            }
        }
        
        let expectedReturn = node.returns.map { PythonType.fromExpression($0) }
        typeEnvironment.setReturnType(expectedReturn)
        
        for statement in node.body {
            visitStatement(statement)
        }
        
        typeEnvironment.popScope()
        scopeTracker.exitScope()
    }
    
    func visitClassDef(_ node: ClassDef) {
        let endLine = node.endLineno ?? calculateEndLine(node.body) ?? node.lineno
        
        // Track class scope
        scopeTracker.enterScope(kind: .classScope, name: node.name, startLine: node.lineno, endLine: endLine)
        typeEnvironment.pushScope(startLine: node.lineno, endLine: endLine)
        
        // Register class in registry
        classRegistry.registerClass(node.name, at: node.lineno, endLine: endLine)
        
        // Process class body
        for statement in node.body {
            // Track class-level annotations
            if case .annAssign(let annAssign) = statement,
               case .name(let target) = annAssign.target {
                let memberType = PythonType.fromExpression(annAssign.annotation)
                classRegistry.addMember(
                    toClass: node.name,
                    name: target.id,
                    type: memberType,
                    kind: .property,
                    line: annAssign.lineno
                )
            }
            
            // Track methods (regular and async)
            if case .functionDef(let funcDef) = statement {
                // Determine method kind
                let methodKind: MemberKind
                if funcDef.decoratorList.contains(where: { decorator in
                    if case .name(let name) = decorator, name.id == "classmethod" {
                        return true
                    }
                    return false
                }) {
                    methodKind = .classMethod
                } else if funcDef.decoratorList.contains(where: { decorator in
                    if case .name(let name) = decorator, name.id == "staticmethod" {
                        return true
                    }
                    return false
                }) {
                    methodKind = .staticMethod
                } else {
                    methodKind = .method
                }
                
                // Register method
                let returnType = funcDef.returns.map { PythonType.fromExpression($0) } ?? .any
                classRegistry.addMember(
                    toClass: node.name,
                    name: funcDef.name,
                    type: returnType,
                    kind: methodKind,
                    line: funcDef.lineno
                )
                
                // Track __init__ for instance properties
                if funcDef.name == "__init__" {
                    // Create temporary scope and register parameters to properly infer property types
                    let endLine = funcDef.endLineno ?? funcDef.body.last?.lineno ?? funcDef.lineno
                    typeEnvironment.pushScope(startLine: funcDef.lineno, endLine: endLine)
                    
                    // Register parameter types in temporary scope
                    for arg in funcDef.args.args {
                        if let annotation = arg.annotation {
                            let paramType = PythonType.fromExpression(annotation)
                            typeEnvironment.setType(arg.arg, type: paramType, at: funcDef.lineno)
                        }
                    }
                    
                    for funcStatement in funcDef.body {
                        // Handle regular assignments: self.x = value
                        if case .assign(let assign) = funcStatement {
                            for target in assign.targets {
                                if case .attribute(let attr) = target,
                                   case .name(let value) = attr.value,
                                   value.id == "self" {
                                    let propType = visitExpression(assign.value)
                                    classRegistry.addMember(
                                        toClass: node.name,
                                        name: attr.attr,
                                        type: propType,
                                        kind: .property,
                                        line: assign.lineno
                                    )
                                }
                            }
                        }
                        
                        // Handle annotated assignments: self.x: int = value
                        if case .annAssign(let annAssign) = funcStatement,
                           case .attribute(let attr) = annAssign.target,
                           case .name(let value) = attr.value,
                           value.id == "self" {
                            let propType = PythonType.fromExpression(annAssign.annotation)
                            classRegistry.addMember(
                                toClass: node.name,
                                name: attr.attr,
                                type: propType,
                                kind: .property,
                                line: annAssign.lineno
                            )
                        }
                    }
                    
                    typeEnvironment.popScope()
                }
            }
            
            // Track async methods
            if case .asyncFunctionDef(let funcDef) = statement {
                let returnType = funcDef.returns.map { PythonType.fromExpression($0) } ?? .any
                classRegistry.addMember(
                    toClass: node.name,
                    name: funcDef.name,
                    type: returnType,
                    kind: .method,
                    line: funcDef.lineno
                )
            }
            
            visitStatement(statement)
        }
        
        typeEnvironment.popScope()
        scopeTracker.exitScope()
    }
    
    func visitReturn(_ node: Return) {
        guard let expectedType = typeEnvironment.getReturnType() else {
            return
        }
        
        if let value = node.value {
            let actualType = visitExpression(value)
            if !expectedType.isCompatible(with: actualType) {
                diagnostics.append(.error(
                    checkerId: "type-checker",
                    message: "Return type mismatch: expected \(expectedType), got \(actualType)",
                    line: node.lineno,
                    column: node.colOffset
                ))
            }
        } else {
            // Returning None
            if !expectedType.isCompatible(with: .none) {
                diagnostics.append(.error(
                    checkerId: "type-checker",
                    message: "Return type mismatch: expected \(expectedType), got None",
                    line: node.lineno,
                    column: node.colOffset
                ))
            }
        }
    }
    
    func visitIf(_ node: If) {
        // Check for type narrowing patterns like isinstance(x, int)
        let testExpr = node.test
        
        // Look for isinstance(variable, type) pattern
        if case .call(let call) = testExpr,
           case .name(let funcName) = call.fun,
           funcName.id == "isinstance",
           call.args.count >= 2,
           case .name(let varName) = call.args[0] {
            
            // Try to extract the type from second argument
            if case .name(let typeName) = call.args[1] {
                var narrowedType: PythonType? = nil
                
                switch typeName.id {
                case "int": narrowedType = .int
                case "float": narrowedType = .float
                case "str": narrowedType = .str
                case "bool": narrowedType = .bool
                case "list": narrowedType = .list(.any)
                case "dict": narrowedType = .dict(key: .any, value: .any)
                case "set": narrowedType = .set(.any)
                case "tuple": narrowedType = .tuple([.any])
                default:
                    // Check if it's a class name
                    if classRegistry.classExists(typeName.id) {
                        narrowedType = .instance(typeName.id)
                    }
                }
                
                // Apply type narrowing in the if body
                if let narrowedType = narrowedType {
                    let currentType = typeEnvironment.getType(varName.id, at: node.lineno)
                    // Temporarily narrow the type in the if block
                    // Note: This is simplified - a full implementation would create a new scope
                    typeEnvironment.setType(varName.id, type: narrowedType, at: node.lineno)
                    
                    for statement in node.body {
                        visitStatement(statement)
                    }
                    
                    // Restore original type for else block
                    if let currentType = currentType {
                        typeEnvironment.setType(varName.id, type: currentType, at: node.lineno)
                    }
                    
                    for statement in node.orElse {
                        visitStatement(statement)
                    }
                    
                    return
                }
            }
        }
        
        // Default behavior - no type narrowing
        for statement in node.body {
            visitStatement(statement)
        }
        
        for statement in node.orElse {
            visitStatement(statement)
        }
    }
    
    func visitWhile(_ node: While) {
        for statement in node.body {
            visitStatement(statement)
        }
        
        for statement in node.orElse {
            visitStatement(statement)
        }
    }
    
    func visitFor(_ node: For) {
        let iterType = visitExpression(node.iter)
        let elementType = extractElementType(from: iterType)
        
        // Handle different target patterns
        switch node.target {
        case .name(let targetName):
            // Simple loop variable: for x in iterable:
            typeEnvironment.setType(targetName.id, type: elementType, at: node.lineno)
            
        case .tuple(let tupleNode):
            // Tuple unpacking: for key, value in dict.items():
            if case .tuple(let elementTypes) = elementType {
                // Element is a tuple, unpack it
                for (index, element) in tupleNode.elts.enumerated() {
                    if case .name(let name) = element, index < elementTypes.count {
                        typeEnvironment.setType(name.id, type: elementTypes[index], at: node.lineno)
                    }
                }
            } else {
                // Element is not a tuple, assign same type to all variables
                for element in tupleNode.elts {
                    if case .name(let name) = element {
                        typeEnvironment.setType(name.id, type: elementType, at: node.lineno)
                    }
                }
            }
            
        default:
            // Other target patterns (subscript, attribute, etc.)
            break
        }
        
        for statement in node.body {
            visitStatement(statement)
        }
        
        for statement in node.orElse {
            visitStatement(statement)
        }
    }
    
    // MARK: - Expression Visitors
    
    func visitConstant(_ node: Constant) -> PythonType {
        switch node.value {
        case .int: return .int
        case .float: return .float
        case .complex: return .float
        case .string: return .str
        case .bytes: return .bytes
        case .bool: return .bool
        case .none: return .none
        case .ellipsis: return .any
        }
    }
    
    func visitName(_ node: Name) -> PythonType {
        // Look up type in environment (will search scopes properly)
        return typeEnvironment.getType(node.id, at: nil) ?? .unknown
    }
    
    func visitBinOp(_ node: BinOp) -> PythonType {
        let leftType = visitExpression(node.left)
        let rightType = visitExpression(node.right)
        
        switch node.op {
        case .add:
            // String concatenation
            if leftType == .str && rightType == .str {
                return .str
            }
            // Numeric addition
            if leftType == .int && rightType == .int {
                return .int
            }
            if (leftType == .int || leftType == .float) && (rightType == .int || rightType == .float) {
                return .float
            }
            // List concatenation
            if case .list(let elemType) = leftType, case .list = rightType {
                return .list(elemType)
            }
            return .any
        case .sub:
            if leftType == .int && rightType == .int {
                return .int
            }
            if (leftType == .int || leftType == .float) && (rightType == .int || rightType == .float) {
                return .float
            }
            return .any
        case .mult:
            // String repetition: str * int or int * str
            if (leftType == .str && rightType == .int) || (leftType == .int && rightType == .str) {
                return .str
            }
            // List repetition: list * int or int * list
            if case .list(let elemType) = leftType, rightType == .int {
                return .list(elemType)
            }
            if leftType == .int, case .list(let elemType) = rightType {
                return .list(elemType)
            }
            // Numeric multiplication
            if leftType == .int && rightType == .int {
                return .int
            }
            if (leftType == .int || leftType == .float) && (rightType == .int || rightType == .float) {
                return .float
            }
            return .any
        case .div:
            // Division always returns float in Python 3
            return .float
        case .floorDiv:
            // Floor division returns int if both operands are int
            if leftType == .int && rightType == .int {
                return .int
            }
            // Otherwise returns float
            return .float
        case .mod:
            // Modulo preserves int if both are int
            if leftType == .int && rightType == .int {
                return .int
            }
            // String formatting: str % tuple
            if leftType == .str {
                return .str
            }
            return .float
        case .pow:
            // Power operation
            if leftType == .int && rightType == .int {
                return .int
            }
            return .float
        case .matMult:
            // Matrix multiplication - return same type
            return leftType
        case .lShift, .rShift, .bitOr, .bitXor, .bitAnd:
            // Bitwise operations return int
            return .int
        }
    }
    
    func visitUnaryOp(_ node: UnaryOp) -> PythonType {
        let operandType = visitExpression(node.operand)
        
        switch node.op {
        case .not: return .bool
        case .uSub, .uAdd: return operandType
        case .invert: return operandType
        }
    }
    
    func visitBoolOp(_ node: BoolOp) -> PythonType {
        return .bool
    }
    
    func visitCompare(_ node: Compare) -> PythonType {
        return .bool
    }
    
    func visitCall(_ node: Call) -> PythonType {
        // Handle method calls (obj.method())
        if case .attribute(let attr) = node.fun {
            let objectType = visitExpression(attr.value)
            
            // Check built-in type methods
            if let returnType = BuiltinTypesRegistry.getMethodReturnType(
                forType: objectType,
                methodName: attr.attr
            ) {
                // Special handling for methods that return element/value types
                switch (objectType, attr.attr) {
                case (.list(let elementType), "pop"):
                    return elementType
                case (.set(let elementType), "pop"):
                    return elementType
                case (.dict(_, let valueType), "get"), (.dict(_, let valueType), "pop"):
                    return valueType
                case (.dict(let keyType, _), "keys"):
                    // dict_keys is iterable of keys - represent as list[K] for simplicity
                    return .list(keyType)
                case (.dict(_, let valueType), "values"):
                    // dict_values is iterable of values - represent as list[V] for simplicity
                    return .list(valueType)
                case (.dict(let keyType, let valueType), "items"):
                    // dict_items is iterable of (key, value) tuples
                    return .list(.tuple([keyType, valueType]))
                case (.set(let elementType), "union"), (.set(let elementType), "intersection"),
                     (.set(let elementType), "difference"), (.set(let elementType), "symmetric_difference"):
                    return .set(elementType)
                default:
                    return returnType
                }
            }
            
            // Check custom class methods
            switch objectType {
            case .classType(let className), .instance(let className):
                let members = classRegistry.getMembers(className)
                if let member = members.first(where: { $0.name == attr.attr && $0.kind == .method }) {
                    return member.type
                }
            default:
                break
            }
            
            return .unknown
        }
        
        // Handle direct function calls
        if case .name(let name) = node.fun {
            switch name.id {
            case "int": return .int
            case "float": return .float
            case "str": return .str
            case "bool": return .bool
            case "list": return .list(.any)
            case "dict": return .dict(key: .any, value: .any)
            case "set": return .set(.any)
            case "tuple": return .tuple([.any])
            // Built-in functions
            case "len": return .int
            case "max", "min":
                // Return element type of the collection if we can infer it
                if !node.args.isEmpty {
                    let argType = visitExpression(node.args[0])
                    return extractElementType(from: argType)
                }
                return .any
            case "sum":
                // Return int for sum of numeric collections
                if !node.args.isEmpty {
                    let argType = visitExpression(node.args[0])
                    let elementType = extractElementType(from: argType)
                    // sum of ints/floats returns the same type
                    if elementType == .int || elementType == .float {
                        return elementType
                    }
                }
                return .int
            case "abs":
                // abs preserves numeric type
                if !node.args.isEmpty {
                    let argType = visitExpression(node.args[0])
                    if argType == .int || argType == .float {
                        return argType
                    }
                }
                return .int
            case "round":
                // round returns int
                return .int
            case "sorted", "reversed":
                // Return list of same element type
                if !node.args.isEmpty {
                    let argType = visitExpression(node.args[0])
                    let elementType = extractElementType(from: argType)
                    return .list(elementType)
                }
                return .list(.any)
            case "enumerate":
                // Returns iterator of tuples (int, element_type)
                if !node.args.isEmpty {
                    let argType = visitExpression(node.args[0])
                    let elementType = extractElementType(from: argType)
                    return .list(.tuple([.int, elementType]))
                }
                return .list(.tuple([.int, .any]))
            case "zip":
                // Returns iterator of tuples with types from each argument
                if node.args.count >= 2 {
                    let types = node.args.map { extractElementType(from: visitExpression($0)) }
                    return .list(.tuple(types))
                }
                return .list(.tuple([.any]))
            case "map", "filter":
                // Returns iterator - simplified to list[Any]
                return .list(.any)
            case "range":
                // range returns a range object, but we'll treat as iterable of ints
                return .list(.int)
            case "all", "any":
                return .bool
            case "isinstance", "issubclass", "callable", "hasattr":
                return .bool
            case "type":
                // type() returns type object
                return .any  // Could be .type(...) if we add that
            case "print":
                return .none
            case "input":
                return .str
            case "open":
                return .any  // file object
            case "iter":
                // Returns iterator of same element type
                if !node.args.isEmpty {
                    let argType = visitExpression(node.args[0])
                    let elementType = extractElementType(from: argType)
                    return .list(elementType)  // Simplified as list
                }
                return .any
            case "next":
                // Returns element type from iterator
                if !node.args.isEmpty {
                    let argType = visitExpression(node.args[0])
                    return extractElementType(from: argType)
                }
                return .any
            case "bytes", "bytearray":
                return .any  // bytes type
            case "ord":
                return .int
            case "chr":
                return .str
            case "pow":
                // pow(x, y) returns numeric type
                if !node.args.isEmpty {
                    let baseType = visitExpression(node.args[0])
                    if baseType == .float || (node.args.count > 1 && visitExpression(node.args[1]) == .float) {
                        return .float
                    }
                    return .int
                }
                return .int
            case "divmod":
                // Returns tuple of (quotient, remainder)
                return .tuple([.int, .int])
            case "hash", "id":
                return .int
            case "getattr":
                // Returns attribute value - unknown type
                return .any
            case "setattr", "delattr":
                return .none
            case "repr", "ascii":
                return .str
            case "bin", "hex", "oct":
                return .str
            case "format":
                return .str
            case "vars", "dir", "globals", "locals":
                return .dict(key: .str, value: .any)
            case "eval", "exec", "compile":
                return .any
            default:
                // Check if it's a class instantiation
                if classRegistry.classExists(name.id) {
                    return .instance(name.id)
                }
                
                // Check if it's a known function
                if let funcType = typeEnvironment.getType(name.id, at: nil) {
                    return funcType
                }
                return .unknown
            }
        }
        
        return .unknown
    }
    
    func visitList(_ node: List) -> PythonType {
        if node.elts.isEmpty {
            return .list(.any)
        }
        
        let firstType = visitExpression(node.elts[0])
        return .list(firstType)
    }
    
    func visitDict(_ node: Dict) -> PythonType {
        if node.keys.isEmpty {
            // Empty dicts default to dict[str, Any] since string keys are most common
            return .dict(key: .str, value: .any)
        }
        
        guard let firstKey = node.keys.compactMap({ $0 }).first,
              let firstValue = node.values.first else {
            return .dict(key: .str, value: .any)
        }
        
        let keyType = visitExpression(firstKey)
        let valueType = visitExpression(firstValue)
        return .dict(key: keyType, value: valueType)
    }
    
    func visitSet(_ node: Set) -> PythonType {
        if node.elts.isEmpty {
            return .set(.any)
        }
        
        let elemType = visitExpression(node.elts[0])
        return .set(elemType)
    }
    
    func visitTuple(_ node: Tuple) -> PythonType {
        let types = node.elts.map { visitExpression($0) }
        return .tuple(types)
    }
    
    func visitIfExp(_ node: IfExp) -> PythonType {
        let trueType = visitExpression(node.body)
        let falseType = visitExpression(node.orElse)
        
        if trueType == falseType {
            return trueType
        }
        
        return .union([trueType, falseType])
    }
    
    // MARK: - Stub implementations for other visitors
    
    func visitAssertStmt(_ node: Assert) {}
    func visitPass(_ node: Pass) {}
    func visitDelete(_ node: Delete) {}
    func visitRaise(_ node: Raise) {}
    func visitBreakStmt(_ node: Break) {}
    func visitContinueStmt(_ node: Continue) {}
    func visitImportStmt(_ node: Import) {
        // Track imported modules
        for alias in node.names {
            let moduleName = alias.asName ?? alias.name
            // Register module as Any type (we don't have type stubs)
            typeEnvironment.setType(moduleName, type: .any, at: node.lineno)
        }
    }
    
    func visitImportFrom(_ node: ImportFrom) {
        // Track from X import Y statements
        for alias in node.names {
            let name = alias.asName ?? alias.name
            // Register imported name as Any type (we don't have type stubs)
            typeEnvironment.setType(name, type: .any, at: node.lineno)
        }
    }
    func visitGlobal(_ node: Global) {}
    func visitNonlocal(_ node: Nonlocal) {}
    func visitExpr(_ node: Expr) { _ = visitExpression(node.value) }
    func visitBlank(_ node: Blank) {}
    
    func visitWith(_ node: With) {
        // Track context manager variables
        for item in node.items {
            if let optionalVars = item.optionalVars {
                // Get type from context manager expression
                let contextType = visitExpression(item.contextExpr)
                
                // Assign the context expression type to the variable
                if case .name(let name) = optionalVars {
                    typeEnvironment.setType(name.id, type: contextType, at: node.lineno)
                }
            }
        }
        
        for stmt in node.body {
            visitStatement(stmt)
        }
    }
    
    func visitTry(_ node: Try) {
        for stmt in node.body {
            visitStatement(stmt)
        }
        
        // Handle exception handlers
        for handler in node.handlers {
            // Track exception variable if specified
            if let name = handler.name, let type = handler.type {
                let exceptionType = visitExpression(type)
                typeEnvironment.setType(name, type: exceptionType, at: node.lineno)
            }
            
            for stmt in handler.body {
                visitStatement(stmt)
            }
        }
        
        // Handle else and finally clauses
        for stmt in node.orElse {
            visitStatement(stmt)
        }
        for stmt in node.finalBody {
            visitStatement(stmt)
        }
    }
    
    func visitTryStar(_ node: TryStar) {
        for stmt in node.body {
            visitStatement(stmt)
        }
        
        for handler in node.handlers {
            if let name = handler.name, let type = handler.type {
                let exceptionType = visitExpression(type)
                typeEnvironment.setType(name, type: exceptionType, at: node.lineno)
            }
            
            for stmt in handler.body {
                visitStatement(stmt)
            }
        }
        
        for stmt in node.orElse {
            visitStatement(stmt)
        }
        for stmt in node.finalBody {
            visitStatement(stmt)
        }
    }
    
    func visitMatch(_ node: Match) {}
    
    func visitAsyncFor(_ node: AsyncFor) {
        for stmt in node.body {
            visitStatement(stmt)
        }
    }
    
    func visitAsyncWith(_ node: AsyncWith) {
        // Similar to visitWith but for async context managers
        for item in node.items {
            if let optionalVars = item.optionalVars {
                let contextType = visitExpression(item.contextExpr)
                
                if case .name(let name) = optionalVars {
                    typeEnvironment.setType(name.id, type: contextType, at: node.lineno)
                }
            }
        }
        
        for stmt in node.body {
            visitStatement(stmt)
        }
    }
    func visitTypeAlias(_ node: TypeAlias) {}
    
    func visitAttribute(_ node: Attribute) -> PythonType {
        // Infer the type of the object being accessed
        let objectType = visitExpression(node.value)
        
        // Check built-in type methods first
        if let builtinMethod = BuiltinTypesRegistry.getMethodReturnType(
            forType: objectType,
            methodName: node.attr
        ) {
            return builtinMethod
        }
        
        // Check custom class members
        switch objectType {
        case .classType(let className), .instance(let className):
            let members = classRegistry.getMembers(className)
            if let member = members.first(where: { $0.name == node.attr }) {
                return member.type
            }
        default:
            break
        }
        
        // Unknown attribute
        return .unknown
    }
    
    func visitSubscript(_ node: Subscript) -> PythonType { 
        // Infer type from subscript - extract element type from collection
        let collectionType = visitExpression(node.value)
        
        // Check if this is a slice operation
        let isSlice: Bool
        if case .slice = node.slice {
            isSlice = true
        } else {
            isSlice = false
        }
        
        switch collectionType {
        case .list(let elementType):
            // Slicing a list returns a list, indexing returns element
            return isSlice ? .list(elementType) : elementType
        case .set(let elementType):
            return elementType
        case .tuple(let types):
            // Tuple slicing returns tuple, indexing needs specific index
            if isSlice {
                return .tuple(types)  // Simplified - actual slice might have fewer elements
            }
            // For tuple indexing, we'd need to know the specific index
            // For now, return union of all types or first type
            if types.count == 1 {
                return types[0]
            }
            return .union(types)
        case .dict(_, let valueType):
            return valueType
        case .str:
            // String slicing returns str, indexing returns str (char)
            return .str
        default:
            return .any
        }
    }
    
    func visitStarred(_ node: Starred) -> PythonType {
        // Starred expressions are used in unpacking
        // The type depends on context - for now return list of element type
        let valueType = visitExpression(node.value)
        return valueType
    }
    
    func visitLambda(_ node: Lambda) -> PythonType {
        // Infer return type from lambda body
        // Create temporary scope for lambda parameters
        typeEnvironment.pushScope(startLine: node.lineno, endLine: node.endLineno ?? node.lineno)
        
        // Register parameter types if annotated
        for arg in node.args.args {
            if let annotation = arg.annotation {
                let paramType = PythonType.fromExpression(annotation)
                typeEnvironment.setType(arg.arg, type: paramType, at: node.lineno)
            } else {
                // Parameter type is unknown
                typeEnvironment.setType(arg.arg, type: .any, at: node.lineno)
            }
        }
        
        // Infer return type from body expression
        let returnType = visitExpression(node.body)
        
        typeEnvironment.popScope()
        
        // Return callable type (simplified - we don't have full function type support)
        return returnType  // For now, just return the return type
    }
    
    func visitListComp(_ node: ListComp) -> PythonType {
        // Set up comprehension variables in a temporary scope
        typeEnvironment.pushScope(startLine: node.lineno, endLine: node.endLineno ?? node.lineno)
        
        // Register loop variables with inferred types from iterables
        for generator in node.generators {
            let iterType = visitExpression(generator.iter)
            let varType = extractElementType(from: iterType)
            
            // Register the loop variable
            if case .name(let name) = generator.target {
                typeEnvironment.setType(name.id, type: varType, at: node.lineno)
            }
        }
        
        // Infer element type from the element expression
        let elementType = visitExpression(node.elt)
        
        typeEnvironment.popScope()
        return .list(elementType)
    }
    
    func visitSetComp(_ node: SetComp) -> PythonType {
        // Set up comprehension variables in a temporary scope
        typeEnvironment.pushScope(startLine: node.lineno, endLine: node.endLineno ?? node.lineno)
        
        // Register loop variables with inferred types from iterables
        for generator in node.generators {
            let iterType = visitExpression(generator.iter)
            let varType = extractElementType(from: iterType)
            
            // Register the loop variable
            if case .name(let name) = generator.target {
                typeEnvironment.setType(name.id, type: varType, at: node.lineno)
            }
        }
        
        // Infer element type from the element expression
        let elementType = visitExpression(node.elt)
        
        typeEnvironment.popScope()
        return .set(elementType)
    }
    
    func visitDictComp(_ node: DictComp) -> PythonType {
        // Set up comprehension variables in a temporary scope
        typeEnvironment.pushScope(startLine: node.lineno, endLine: node.endLineno ?? node.lineno)
        
        // Register loop variables with inferred types from iterables
        for generator in node.generators {
            let iterType = visitExpression(generator.iter)
            let varType = extractElementType(from: iterType)
            
            // Register the loop variable
            if case .name(let name) = generator.target {
                typeEnvironment.setType(name.id, type: varType, at: node.lineno)
            }
        }
        
        // Infer key and value types from the expressions
        let keyType = visitExpression(node.key)
        let valueType = visitExpression(node.value)
        
        typeEnvironment.popScope()
        return .dict(key: keyType, value: valueType)
    }
    
    /// Extract element type from iterable types
    private func extractElementType(from type: PythonType) -> PythonType {
        switch type {
        case .list(let elementType):
            return elementType
        case .set(let elementType):
            return elementType
        case .tuple(let types):
            return types.first ?? .any
        case .dict(let keyType, _):
            return keyType  // Iterating over dict gives keys
        case .str:
            return .str  // Iterating over string gives strings
        default:
            return .int  // range() and most numeric iterables produce ints
        }
    }
    
    func visitGeneratorExp(_ node: GeneratorExp) -> PythonType {
        // Generator expressions work like list comprehensions but return generators
        // For simplicity, we'll treat them as iterables with inferred element type
        typeEnvironment.pushScope(startLine: node.lineno, endLine: node.endLineno ?? node.lineno)
        
        // Register loop variables with inferred types from iterables
        for generator in node.generators {
            let iterType = visitExpression(generator.iter)
            let varType = extractElementType(from: iterType)
            
            if case .name(let name) = generator.target {
                typeEnvironment.setType(name.id, type: varType, at: node.lineno)
            }
        }
        
        // Infer element type from the element expression
        let elementType = visitExpression(node.elt)
        
        typeEnvironment.popScope()
        
        // Return as list for IDE purposes (generators are iterable)
        return .list(elementType)
    }
    func visitNamedExpr(_ node: NamedExpr) -> PythonType {
        let valueType = visitExpression(node.value)
        // Register the walrus operator variable
        if case .name(let name) = node.target {
            typeEnvironment.setType(name.id, type: valueType, at: node.lineno)
        }
        return valueType
    }
    
    func visitYield(_ node: Yield) -> PythonType {
        // Yield returns the yielded value type
        if let value = node.value {
            return visitExpression(value)
        }
        return .none
    }
    
    func visitYieldFrom(_ node: YieldFrom) -> PythonType {
        // Yield from returns the element type of the iterable
        let iterType = visitExpression(node.value)
        return extractElementType(from: iterType)
    }
    
    func visitAwait(_ node: Await) -> PythonType {
        // Await unwraps the awaitable/coroutine type
        // For now, just return the type of the awaited expression
        return visitExpression(node.value)
    }
    func visitFormattedValue(_ node: FormattedValue) -> PythonType { .str }
    func visitJoinedStr(_ node: JoinedStr) -> PythonType { .str }
    func visitSlice(_ node: Slice) -> PythonType { .any }
}

// MARK: - Supporting Types

/// Information about a scope
public struct ScopeInfo: Sendable {
    public let kind: ScopeKind
    public let name: String?
    public let startLine: Int
    public let endLine: Int
}

/// Kind of scope
public enum ScopeKind: Sendable, Equatable {
    case module
    case function
    case classScope
}

/// Information about a class member
public struct MemberInfo: Sendable {
    public let name: String
    public let type: PythonType
    public let kind: MemberKind
    public let line: Int
}

/// Kind of class member
public enum MemberKind: Sendable {
    case property
    case method
    case classMethod
    case staticMethod
}

// MARK: - Scope Tracker

/// Tracks scope boundaries during analysis
final class ScopeTracker {
    private var scopes: [ScopeInfo] = []
    private var allScopes: [ScopeInfo] = [] // Permanent record of all scopes
    
    func enterScope(kind: ScopeKind, name: String?, startLine: Int, endLine: Int) {
        let scopeInfo = ScopeInfo(kind: kind, name: name, startLine: startLine, endLine: endLine)
        scopes.append(scopeInfo)
        allScopes.append(scopeInfo)
    }
    
    func exitScope() {
        if !scopes.isEmpty {
            scopes.removeLast()
        }
    }
    
    func getScopeAt(line: Int) -> ScopeInfo? {
        // Search permanent record of all scopes, return innermost match
        // Innermost = smallest range containing the line
        var matchingScope: ScopeInfo? = nil
        var smallestRange = Int.max
        
        for scope in allScopes {
            if scope.startLine <= line && line <= scope.endLine {
                let range = scope.endLine - scope.startLine
                // Prefer smaller ranges (more nested scopes)
                if range < smallestRange {
                    matchingScope = scope
                    smallestRange = range
                }
            }
        }
        
        return matchingScope
    }
    
    func getScopeChainAt(line: Int) -> [ScopeInfo] {
        // Return all scopes containing the line, sorted from outermost to innermost
        var matchingScopes: [(scope: ScopeInfo, range: Int)] = []
        
        for scope in allScopes {
            if scope.startLine <= line && line <= scope.endLine {
                let range = scope.endLine - scope.startLine
                matchingScopes.append((scope, range))
            }
        }
        
        // Sort by range size (largest first = outermost)
        matchingScopes.sort { $0.range > $1.range }
        
        return matchingScopes.map { $0.scope }
    }
}

// MARK: - Class Registry

/// Tracks class definitions and their members
final class ClassRegistry {
    private var classes: [String: ClassInfo] = [:]
    
    class ClassInfo {
        let name: String
        let startLine: Int
        let endLine: Int
        var members: [MemberInfo] = []
        
        init(name: String, startLine: Int, endLine: Int) {
            self.name = name
            self.startLine = startLine
            self.endLine = endLine
        }
    }
    
    func registerClass(_ name: String, at startLine: Int, endLine: Int) {
        classes[name] = ClassInfo(name: name, startLine: startLine, endLine: endLine)
    }
    
    func addMember(toClass className: String, name: String, type: PythonType, kind: MemberKind, line: Int) {
        classes[className]?.members.append(MemberInfo(name: name, type: type, kind: kind, line: line))
    }
    
    func getMembers(_ className: String) -> [MemberInfo] {
        return classes[className]?.members ?? []
    }
    
    func classExists(_ name: String) -> Bool {
        return classes[name] != nil
    }
}

// MARK: - Enhanced Type Environment

/// Manages variable types and scopes with line-aware lookups and variable chain tracking
public final class TypeEnvironment {
    private class Scope {
        var variables: [(name: String, type: PythonType, line: Int, isConstant: Bool)] = []
        var returnType: PythonType?
        var startLine: Int
        var endLine: Int
        
        init(startLine: Int, endLine: Int) {
            self.startLine = startLine
            self.endLine = endLine
        }
    }
    
    private var activeScopes: [Scope] = []  // Stack for current traversal
    private var allScopes: [Scope] = []     // All scopes with line ranges (permanent)
    
    init() {
        // Global scope covers all lines
        let globalScope = Scope(startLine: 1, endLine: Int.max)
        activeScopes.append(globalScope)
        allScopes.append(globalScope)
    }
    
    func pushScope(startLine: Int = 1, endLine: Int = Int.max) {
        let scope = Scope(startLine: startLine, endLine: endLine)
        activeScopes.append(scope)
        allScopes.append(scope)
    }
    
    func popScope() {
        if activeScopes.count > 1 {
            activeScopes.removeLast()
        }
    }
    
    /// Check if a name follows the constant naming convention (all uppercase with underscores)
    private func isConstantName(_ name: String) -> Bool {
        return name.allSatisfy { $0.isUppercase || $0 == "_" || $0.isNumber } && !name.isEmpty
    }
    
    func setType(_ name: String, type: PythonType, at line: Int) {
        let isConstant = isConstantName(name)
        activeScopes[activeScopes.count - 1].variables.append((name: name, type: type, line: line, isConstant: isConstant))
    }
    
    func setReturnType(_ type: PythonType?) {
        activeScopes[activeScopes.count - 1].returnType = type
    }
    
    /// Get type with variable chain following and cycle detection
    func getType(_ name: String, at line: Int?) -> PythonType? {
        return getTypeWithVisited(name, at: line, visited: Swift.Set<String>())
    }
    
    /// Internal method with cycle detection for variable chains
    private func getTypeWithVisited(_ name: String, at line: Int?, visited: Swift.Set<String>) -> PythonType? {
        // Prevent infinite loops when following variable chains
        if visited.contains(name) {
            return nil
        }
        
        var newVisited = visited
        newVisited.insert(name)
        
        // Find scopes that contain this line, ordered from innermost to outermost
        let relevantScopes: [Scope]
        if let queryLine = line {
            relevantScopes = allScopes
                .filter { $0.startLine <= queryLine && queryLine <= $0.endLine }
                .sorted { ($0.endLine - $0.startLine) < ($1.endLine - $1.startLine) }
        } else {
            relevantScopes = allScopes
        }
        
        // Search from innermost to outermost scope
        for scope in relevantScopes {
            // Find the most recent assignment at or before the line
            var mostRecent: (type: PythonType, line: Int)?
            
            for (varName, varType, varLine, _) in scope.variables {
                if varName == name {
                    if let queryLine = line {
                        if varLine <= queryLine {
                            if mostRecent == nil || varLine > mostRecent!.line {
                                mostRecent = (type: varType, line: varLine)
                            }
                        }
                    } else {
                        // No line filtering - return first match
                        return resolveTypeChain(varType, at: line, visited: newVisited)
                    }
                }
            }
            
            if let result = mostRecent {
                return resolveTypeChain(result.type, at: line, visited: newVisited)
            }
        }
        
        return nil
    }
    
    /// Resolve variable chains where type might reference another variable
    /// For example: a = b where b: int → resolve to int
    private func resolveTypeChain(_ type: PythonType, at line: Int?, visited: Swift.Set<String>) -> PythonType {
        // If the type is unknown, it might be a reference to another variable
        // This handles patterns like: x = y where we need to look up y's type
        // Note: In practice, this is handled during visitExpression in the visitor
        // but we keep this for potential future enhancements
        return type
    }
    
    func getAllSymbolsInScope(at line: Int) -> [(name: String, type: PythonType)] {
        var symbols: [String: PythonType] = [:]
        
        // Collect from all scopes (outer to inner)
        for scope in allScopes {
            for (name, type, varLine, _) in scope.variables {
                if varLine <= line {
                    // Use the most recent assignment for each variable
                    if symbols[name] != nil {
                        // Check if this assignment is more recent
                        if let existingLine = findMostRecentLine(for: name, in: allScopes, before: line),
                           varLine > existingLine {
                            symbols[name] = type
                        }
                    } else {
                        symbols[name] = type
                    }
                }
            }
        }
        
        return Array(symbols.map { ($0.key, $0.value) })
    }
    
    /// Check if a variable is defined as a constant (uppercase naming)
    func isConstant(_ name: String) -> Bool {
        // Search all scopes for the first definition
        for scope in allScopes {
            for (varName, _, _, isConst) in scope.variables {
                if varName == name {
                    return isConst
                }
            }
        }
        return false
    }
    
    /// Find the most recent line where a variable was assigned
    private func findMostRecentLine(for name: String, in scopes: [Scope], before line: Int) -> Int? {
        var mostRecent: Int?
        
        for scope in scopes {
            for (varName, _, varLine, _) in scope.variables {
                if varName == name && varLine <= line {
                    if mostRecent == nil || varLine > mostRecent! {
                        mostRecent = varLine
                    }
                }
            }
        }
        
        return mostRecent
    }
    
    func getReturnType() -> PythonType? {
        return activeScopes.last?.returnType
    }
    
    /// Get the current scope level (for debugging)
    func getCurrentScopeLevel() -> Int {
        return activeScopes.count - 1
    }
    
    /// Check if a variable exists in any scope
    func variableExists(_ name: String) -> Bool {
        for scope in allScopes {
            for (varName, _, _, _) in scope.variables {
                if varName == name {
                    return true
                }
            }
        }
        return false
    }
    
    /// Check if a variable exists anywhere in any scope (global search)
    func variableExistsAnywhere(_ name: String) -> Bool {
        return variableExists(name)
    }
    
    /// Get all symbols from all scopes (for global search)
    func getAllSymbols() -> [(name: String, type: PythonType)] {
        var result: [(name: String, type: PythonType)] = []
        var seen: Swift.Set<String> = []
        
        // Collect from all scopes, avoiding duplicates
        for scope in allScopes.reversed() {
            for (name, type, _, _) in scope.variables {
                if !seen.contains(name) {
                    result.append((name: name, type: type))
                    seen.insert(name)
                }
            }
        }
        
        return result
    }
}

// MARK: - PythonType Extensions

extension PythonType {
    /// Create a PythonType from an Expression (type annotation)
    public static func fromExpression(_ expr: Expression) -> PythonType {
        switch expr {
        case .name(let name):
            switch name.id {
            case "int": return .int
            case "float": return .float
            case "str": return .str
            case "bool": return .bool
            case "bytes": return .bytes
            case "list": return .list(.any)
            case "dict": return .dict(key: .any, value: .any)
            case "set": return .set(.any)
            case "tuple": return .tuple([.any])
            case "Any": return .any
            case "None": return .none
            default: return .unknown
            }
            
        case .subscriptExpr(let subscriptExpr):
            // Handle generic types like list[str], dict[int, str]
            if case .name(let baseType) = subscriptExpr.value {
                switch baseType.id {
                case "list", "List":
                    let elementType = fromExpression(subscriptExpr.slice)
                    return .list(elementType)
                case "set", "Set":
                    let elementType = fromExpression(subscriptExpr.slice)
                    return .set(elementType)
                case "tuple", "Tuple":
                    if case .tuple(let tupleExpr) = subscriptExpr.slice {
                        let types = tupleExpr.elts.map { fromExpression($0) }
                        return .tuple(types)
                    }
                    return .tuple([fromExpression(subscriptExpr.slice)])
                case "dict", "Dict":
                    if case .tuple(let tupleExpr) = subscriptExpr.slice,
                       tupleExpr.elts.count == 2 {
                        let keyType = fromExpression(tupleExpr.elts[0])
                        let valueType = fromExpression(tupleExpr.elts[1])
                        return .dict(key: keyType, value: valueType)
                    }
                    return .dict(key: .any, value: .any)
                default:
                    return .unknown
                }
            }
            return .unknown
            
        case .constant(let constant):
            switch constant.value {
            case .int: return .int
            case .float: return .float
            case .string: return .str
            case .bool: return .bool
            case .none: return .none
            default: return .any
            }
            
        default:
            return .unknown
        }
    }
    
    /// Format type for display
    public func toDisplayString() -> String {
        switch self {
        case .int: return "int"
        case .float: return "float"
        case .str: return "str"
        case .bool: return "bool"
        case .bytes: return "bytes"
        case .none: return "None"
        case .any: return "Any"
        case .unknown: return "Unknown"
        case .list(let elementType):
            return "list[\(elementType.toDisplayString())]"
        case .dict(let keyType, let valueType):
            return "dict[\(keyType.toDisplayString()), \(valueType.toDisplayString())]"
        case .set(let elementType):
            return "set[\(elementType.toDisplayString())]"
        case .tuple(let types):
            if types.count == 1 {
                return "tuple[\(types[0].toDisplayString()), ...]"
            }
            let typeStrs = types.map { $0.toDisplayString() }
            return "tuple[\(typeStrs.joined(separator: ", "))]"
        case .union(let types):
            let typeStrs = types.map { $0.toDisplayString() }
            return typeStrs.joined(separator: " | ")
        case .function:
            return "function"
        case .classType(let name):
            return "type[\(name)]"
        case .instance(let name):
            return name
        }
    }
}

// MARK: - Scope Chain for Query-Time Variable Resolution

/// Represents a scope chain for variable lookup at a specific line
struct ScopeChain {
    let localStatements: [Statement]  // Current function/method scope
    let classStatements: [Statement]? // Enclosing class scope (if any)
    let globalStatements: [Statement] // Module-level scope
    let lineNumber: Int // Line number for finding most recent assignment
    
    /// Search for a variable in the proper scope order: local -> global
    func findVariable(_ name: String) -> PythonType? {
        return findVariableWithVisited(name, visited: Swift.Set<String>())
    }
    
    /// Internal search with cycle detection
    private func findVariableWithVisited(_ name: String, visited: Swift.Set<String>) -> PythonType? {
        if visited.contains(name) {
            return nil
        }
        
        var newVisited = visited
        newVisited.insert(name)
        
        // 1. Search local scope first
        if let type = searchStatements(localStatements, for: name, visited: newVisited) {
            return type
        }
        
        // 2. Search global scope
        if let type = searchStatements(globalStatements, for: name, visited: newVisited) {
            return type
        }
        
        return nil
    }
    
    /// Search statements for a variable assignment
    private func searchStatements(_ statements: [Statement], for name: String, visited: Swift.Set<String>) -> PythonType? {
        var mostRecentAssignment: (line: Int, type: PythonType)? = nil
        
        for stmt in statements {
            switch stmt {
            case .assign(let assign):
                for target in assign.targets {
                    if case let .name(nameExpr) = target, nameExpr.id == name {
                        if assign.lineno <= lineNumber {
                            let type = inferTypeFromExpression(assign.value, visited: visited)
                            if mostRecentAssignment == nil || assign.lineno > mostRecentAssignment!.line {
                                mostRecentAssignment = (line: assign.lineno, type: type)
                            }
                        }
                    }
                }
            case .annAssign(let annAssign):
                if case let .name(target) = annAssign.target, target.id == name {
                    if annAssign.lineno <= lineNumber {
                        let type = PythonType.fromExpression(annAssign.annotation)
                        if mostRecentAssignment == nil || annAssign.lineno > mostRecentAssignment!.line {
                            mostRecentAssignment = (line: annAssign.lineno, type: type)
                        }
                    }
                }
            default:
                break
            }
        }
        
        return mostRecentAssignment?.type
    }
    
    /// Infer type from an expression with variable resolution
    private func inferTypeFromExpression(_ expr: Expression, visited: Swift.Set<String>) -> PythonType {
        switch expr {
        case .name(let nameExpr):
            // Resolve variable reference
            if let type = findVariableWithVisited(nameExpr.id, visited: visited) {
                return type
            }
            return .any
        default:
            return PythonType.fromExpression(expr)
        }
    }
}
