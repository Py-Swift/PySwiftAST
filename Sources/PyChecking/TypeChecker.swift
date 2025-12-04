import PySwiftAST

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
            // Search all scopes if no line specified
            let allSymbols = visitor.typeEnvironment.getAllSymbols()
            return allSymbols.first(where: { $0.name == name })?.type.toDisplayString()
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
        if let scope = visitor.scopeTracker.getScopeAt(line: lineNumber),
           scope.kind == .classScope {
            return scope.name
        }
        return nil
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
    
    /// Check if a variable exists in scope
    /// - Parameters:
    ///   - name: Variable name
    ///   - anywhere: If true, searches all scopes; if false, only current scope
    /// - Returns: True if variable exists
    public func variableExists(_ name: String, anywhere: Bool = false) -> Bool {
        if anywhere {
            return visitor.typeEnvironment.variableExistsAnywhere(name)
        } else {
            return visitor.typeEnvironment.variableExists(name)
        }
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
        _ = visitExpression(node.value)
    }
    
    func visitFunctionDef(_ node: FunctionDef) {
        // Calculate function end line
        let endLine = node.body.last?.lineno ?? node.lineno
        
        // Track function scope
        scopeTracker.enterScope(kind: .function, name: node.name, startLine: node.lineno, endLine: endLine)
        typeEnvironment.pushScope()
        
        // Register parameter types
        for arg in node.args.args {
            if let annotation = arg.annotation {
                let paramType = PythonType.fromExpression(annotation)
                typeEnvironment.setType(arg.arg, type: paramType, at: node.lineno)
            } else {
                typeEnvironment.setType(arg.arg, type: .any, at: node.lineno)
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
        let endLine = node.body.last?.lineno ?? node.lineno
        
        scopeTracker.enterScope(kind: .function, name: node.name, startLine: node.lineno, endLine: endLine)
        typeEnvironment.pushScope()
        
        for arg in node.args.args {
            if let annotation = arg.annotation {
                let paramType = PythonType.fromExpression(annotation)
                typeEnvironment.setType(arg.arg, type: paramType, at: node.lineno)
            } else {
                typeEnvironment.setType(arg.arg, type: .any, at: node.lineno)
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
        let endLine = node.body.last?.lineno ?? node.lineno
        
        // Track class scope
        scopeTracker.enterScope(kind: .classScope, name: node.name, startLine: node.lineno, endLine: endLine)
        typeEnvironment.pushScope()
        
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
        
        // Try to infer element type from iterator
        if case .list(let elemType) = iterType,
           case .name(let targetName) = node.target {
            typeEnvironment.setType(targetName.id, type: elemType, at: node.lineno)
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
        
        // Simple numeric operations
        if leftType == .int && rightType == .int {
            switch node.op {
            case .div: return .float
            default: return .int
            }
        }
        
        if (leftType == .float || rightType == .float) {
            return .float
        }
        
        // String concatenation
        if leftType == .str && rightType == .str {
            switch node.op {
            case .add: return .str
            default: return .unknown
            }
        }
        
        return .unknown
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
        // Try to infer from function name
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
            default: return .unknown
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
            return .dict(key: .any, value: .any)
        }
        
        guard let firstKey = node.keys.compactMap({ $0 }).first,
              let firstValue = node.values.first else {
            return .dict(key: .any, value: .any)
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
    func visitImportStmt(_ node: Import) {}
    func visitImportFrom(_ node: ImportFrom) {}
    func visitGlobal(_ node: Global) {}
    func visitNonlocal(_ node: Nonlocal) {}
    func visitExpr(_ node: Expr) { _ = visitExpression(node.value) }
    func visitBlank(_ node: Blank) {}
    func visitWith(_ node: With) { for stmt in node.body { visitStatement(stmt) } }
    func visitTry(_ node: Try) { for stmt in node.body { visitStatement(stmt) } }
    func visitTryStar(_ node: TryStar) { for stmt in node.body { visitStatement(stmt) } }
    func visitMatch(_ node: Match) {}
    func visitAsyncFor(_ node: AsyncFor) { for stmt in node.body { visitStatement(stmt) } }
    func visitAsyncWith(_ node: AsyncWith) { for stmt in node.body { visitStatement(stmt) } }
    func visitTypeAlias(_ node: TypeAlias) {}
    
    func visitAttribute(_ node: Attribute) -> PythonType { 
        // TODO: Implement class member resolution
        .unknown 
    }
    
    func visitSubscript(_ node: Subscript) -> PythonType { 
        // Infer type from subscript - extract element type from collection
        let collectionType = visitExpression(node.value)
        
        switch collectionType {
        case .list(let elementType):
            return elementType
        case .set(let elementType):
            return elementType
        case .tuple(let types):
            // For tuple indexing, we'd need to know the specific index
            // For now, return union of all types or first type
            if types.count == 1 {
                return types[0]
            }
            return .union(types)
        case .dict(_, let valueType):
            return valueType
        case .str:
            return .str // String indexing returns str
        default:
            return .any
        }
    }
    
    func visitStarred(_ node: Starred) -> PythonType { .unknown }
    func visitLambda(_ node: Lambda) -> PythonType { .unknown }
    func visitListComp(_ node: ListComp) -> PythonType { .list(.any) }
    func visitSetComp(_ node: SetComp) -> PythonType { .set(.any) }
    func visitDictComp(_ node: DictComp) -> PythonType { .dict(key: .any, value: .any) }
    func visitGeneratorExp(_ node: GeneratorExp) -> PythonType { .any }
    func visitNamedExpr(_ node: NamedExpr) -> PythonType { visitExpression(node.value) }
    func visitYield(_ node: Yield) -> PythonType { .any }
    func visitYieldFrom(_ node: YieldFrom) -> PythonType { .any }
    func visitAwait(_ node: Await) -> PythonType { .any }
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
public enum ScopeKind: Sendable {
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
    
    func enterScope(kind: ScopeKind, name: String?, startLine: Int, endLine: Int) {
        scopes.append(ScopeInfo(kind: kind, name: name, startLine: startLine, endLine: endLine))
    }
    
    func exitScope() {
        if !scopes.isEmpty {
            scopes.removeLast()
        }
    }
    
    func getScopeAt(line: Int) -> ScopeInfo? {
        // Return the innermost scope containing the line
        for scope in scopes.reversed() {
            if scope.startLine <= line && line <= scope.endLine {
                return scope
            }
        }
        return nil
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
}

// MARK: - Enhanced Type Environment

/// Manages variable types and scopes with line-aware lookups and variable chain tracking
public final class TypeEnvironment {
    private class Scope {
        var variables: [(name: String, type: PythonType, line: Int)] = []
        var returnType: PythonType?
    }
    
    private var scopes: [Scope] = [Scope()]
    
    init() {}
    
    func pushScope() {
        scopes.append(Scope())
    }
    
    func popScope() {
        if scopes.count > 1 {
            scopes.removeLast()
        }
    }
    
    func setType(_ name: String, type: PythonType, at line: Int) {
        scopes[scopes.count - 1].variables.append((name: name, type: type, line: line))
    }
    
    func setReturnType(_ type: PythonType) {
        scopes[scopes.count - 1].returnType = type
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
        
        // Search from innermost to outermost scope
        for scope in scopes.reversed() {
            // Find the most recent assignment at or before the line
            var mostRecent: (type: PythonType, line: Int)?
            
            for (varName, varType, varLine) in scope.variables {
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
        for scope in scopes {
            for (name, type, varLine) in scope.variables {
                if varLine <= line {
                    // Use the most recent assignment for each variable
                    if symbols[name] != nil {
                        // Check if this assignment is more recent
                        if let existingLine = findMostRecentLine(for: name, in: scopes, before: line),
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
    
    /// Find the most recent line where a variable was assigned
    private func findMostRecentLine(for name: String, in scopes: [Scope], before line: Int) -> Int? {
        var mostRecent: Int?
        
        for scope in scopes {
            for (varName, _, varLine) in scope.variables {
                if varName == name && varLine <= line {
                    if mostRecent == nil || varLine > mostRecent! {
                        mostRecent = varLine
                    }
                }
            }
        }
        
        return mostRecent
    }
    
    func setReturnType(_ type: PythonType?) {
        scopes[scopes.count - 1].returnType = type
    }
    
    func getReturnType() -> PythonType? {
        return scopes.last?.returnType
    }
    
    /// Get the current scope level (for debugging)
    func getCurrentScopeLevel() -> Int {
        return scopes.count - 1
    }
    
    /// Check if a variable exists in any scope
    func variableExists(_ name: String) -> Bool {
        for scope in scopes {
            for (varName, _, _) in scope.variables {
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
        for scope in scopes.reversed() {
            for (name, type, _) in scope.variables {
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
            return name
        case .instance(let name):
            return name
        }
    }
}
