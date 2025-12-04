import PySwiftAST
import PySwiftCodeGen

/// Core AST analysis without JavaScriptKit dependencies
public class ASTCore {
    public private(set) var currentAST: Module?
    
    public init() {}
    
    /// Parse Python code synchronously
    /// - Parameter code: The Python source code
    public func parseCode(_ code: String) throws {
        let module: Module = try parsePython(code)
        currentAST = module
    }
    
    /// Get the type of a variable from the AST with scope awareness
    /// - Parameters:
    ///   - name: Variable name to look up
    ///   - lineNumber: Line number where the variable is referenced (for scope determination)
    /// - Returns: Type information string if found
    public func getVariableType(_ name: String, at lineNumber: Int?) -> String? {
        guard case let .module(statements) = currentAST else {
            return nil
        }
        
        // If we have a line number, find the scope we're in
        if let line = lineNumber {
            if let scopeChain = findScopeChain(at: line, in: statements, globals: statements) {
                return scopeChain.findVariable(name)
            }
        }
        
        // Fallback: search only global scope
        let scopeChain = ScopeChain(localStatements: [], classStatements: nil, globalStatements: statements, lineNumber: lineNumber)
        return scopeChain.findVariable(name)
    }
    
    /// Check if a variable exists anywhere in the AST (ignoring scope)
    /// - Parameter name: Variable name to look up
    /// - Returns: True if the variable exists anywhere, false otherwise
    public func variableExistsAnywhere(_ name: String) -> Bool {
        guard case let .module(statements) = currentAST else {
            return false
        }
        
        return searchStatementsRecursively(statements, for: name)
    }
    
    /// Recursively search statements for a variable assignment
    private func searchStatementsRecursively(_ statements: [Statement], for name: String) -> Bool {
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
                if searchStatementsRecursively(funcDef.body, for: name) {
                    return true
                }
            case .classDef(let classDef):
                if searchStatementsRecursively(classDef.body, for: name) {
                    return true
                }
            default:
                break
            }
        }
        return false
    }
    
    /// Find the scope chain for a given line number
    private func findScopeChain(at lineNumber: Int, in statements: [Statement], globals: [Statement], inClass: ClassDef? = nil) -> ScopeChain? {
        for statement in statements {
            switch statement {
            case .functionDef(let funcDef):
                // Check if line is within this function
                let funcEndLine = getStatementEndLine(statement)
                if funcDef.lineno <= lineNumber && lineNumber <= funcEndLine {
                    return ScopeChain(
                        localStatements: funcDef.body,
                        classStatements: inClass.map { [$0].map { Statement.classDef($0) } },
                        globalStatements: globals,
                        lineNumber: lineNumber
                    )
                }
                
            case .classDef(let classDef):
                // Check if line is within this class
                let classEndLine = getStatementEndLine(statement)
                if classDef.lineno <= lineNumber && lineNumber <= classEndLine {
                    // Recursively search within the class for nested functions
                    if let nestedScope = findScopeChain(at: lineNumber, in: classDef.body, globals: globals, inClass: classDef) {
                        return nestedScope
                    }
                    // If not in a nested function, it's in class scope (but class vars aren't accessible without self.)
                    // So we return empty local scope
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
    
    private func getStatementEndLine(_ statement: Statement) -> Int {
        switch statement {
        case .functionDef(let funcDef):
            if let lastStmt = funcDef.body.last {
                return getStatementEndLine(lastStmt)
            }
            return funcDef.lineno
        case .classDef(let classDef):
            if let lastStmt = classDef.body.last {
                return getStatementEndLine(lastStmt)
            }
            return classDef.lineno
        case .assign(let assign):
            return assign.lineno
        case .annAssign(let annAssign):
            return annAssign.lineno
        case .expr(let expr):
            return expr.lineno
        case .pass(let pass):
            return pass.lineno
        default:
            // For any other statement type, use a large number to ensure we're inside
            return 999999
        }
    }
    
    /// Get the type of a class property
    /// - Parameters:
    ///   - className: Name of the class
    ///   - propertyName: Name of the property
    /// - Returns: Type information string if found
    public func getPropertyType(className: String, propertyName: String) -> String? {
        guard case let .module(statements) = currentAST else {
            return nil
        }
        
        return searchPropertyInStatements(statements, className: className, propertyName: propertyName)
    }
    
    /// Recursively search for a property in a class
    private func searchPropertyInStatements(_ statements: [Statement], className: String, propertyName: String) -> String? {
        for statement in statements {
            if case let .classDef(classDef) = statement {
                if classDef.name == className {
                    // Found the target class, check for properties
                    for stmt in classDef.body {
                        // Check annotated class variables
                        if case let .annAssign(annAssign) = stmt,
                           case let .name(target) = annAssign.target,
                           target.id == propertyName {
                            return describeExpression(annAssign.annotation)
                        }
                        
                        // Check __init__ for self.property assignments
                        if case let .functionDef(funcDef) = stmt, funcDef.name == "__init__" {
                            for funcStatement in funcDef.body {
                                if case let .assign(assign) = funcStatement {
                                    for target in assign.targets {
                                        if case let .attribute(attr) = target,
                                           case let .name(value) = attr.value,
                                           value.id == "self",
                                           attr.attr == propertyName {
                                            return inferSimpleType(assign.value)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    return nil
                }
                
                // Check nested classes
                if let result = searchPropertyInStatements(classDef.body, className: className, propertyName: propertyName) {
                    return result
                }
            } else if case let .functionDef(funcDef) = statement {
                // Check nested classes inside functions
                if let result = searchPropertyInStatements(funcDef.body, className: className, propertyName: propertyName) {
                    return result
                }
            }
        }
        return nil
    }
    
    /// Get class context for a line number
    /// - Parameter lineNumber: Line number (1-indexed)
    /// - Returns: Class name if the line is inside a class definition
    public func getClassContext(lineNumber: Int) -> String? {
        guard case let .module(statements) = currentAST else {
            return nil
        }
        
        return findClassContainingLine(lineNumber, in: statements)?.name
    }
    
    /// Get class definition and generated code
    /// - Parameter lineNumber: Line number (1-indexed)
    /// - Returns: Tuple of (className, generatedCode) if found
    public func getClassDefinition(lineNumber: Int) -> (name: String, code: String)? {
        guard case let .module(statements) = currentAST else {
            return nil
        }
        
        if let (name, classDef) = findClassContainingLine(lineNumber, in: statements) {
            let statement = Statement.classDef(classDef)
            let code = generatePythonCode(from: statement)
            return (name: name, code: code)
        }
        
        return nil
    }
    
    /// Get all variables in scope at a given line number
    /// - Parameter lineNumber: Line number to check scope
    /// - Returns: Dictionary of variable names to their types
    public func getAllVariablesInScope(at lineNumber: Int) -> [String: String] {
        guard case let .module(statements) = currentAST else {
            return [:]
        }
        
        var variables: [String: String] = [:]
        
        // Find the scope chain for this line
        if let scopeChain = findScopeChain(at: lineNumber, in: statements, globals: statements) {
            // Get all variables from the scope chain
            variables = scopeChain.getAllVariables()
        } else {
            // Global scope only
            let scopeChain = ScopeChain(localStatements: [], classStatements: nil, globalStatements: statements, lineNumber: lineNumber)
            variables = scopeChain.getAllVariables()
        }
        
        return variables
    }
    
    /// Get all properties of the class at a given line number
    /// - Parameter lineNumber: Line number inside a class
    /// - Returns: Dictionary of property names to their types
    public func getClassProperties(at lineNumber: Int) -> [String: String] {
        guard case let .module(statements) = currentAST else {
            return [:]
        }
        
        guard let (_, classDef) = findClassContainingLine(lineNumber, in: statements) else {
            return [:]
        }
        
        var properties: [String: String] = [:]
        
        // Search for properties in __init__ and class body
        for stmt in classDef.body {
            // Check annotated class variables
            if case let .annAssign(annAssign) = stmt,
               case let .name(target) = annAssign.target {
                properties[target.id] = describeExpression(annAssign.annotation)
            }
            
            // Check __init__ for self.property assignments
            if case let .functionDef(funcDef) = stmt, funcDef.name == "__init__" {
                for funcStatement in funcDef.body {
                    if case let .assign(assign) = funcStatement {
                        for target in assign.targets {
                            if case let .attribute(attr) = target,
                               case let .name(value) = attr.value,
                               value.id == "self" {
                                properties[attr.attr] = inferSimpleType(assign.value)
                            }
                        }
                    }
                }
            }
        }
        
        return properties
    }
    
    /// Recursively search for a class containing the target line
    private func findClassContainingLine(_ lineNumber: Int, in statements: [Statement]) -> (name: String, classDef: ClassDef)? {
        for statement in statements {
            if case .classDef(let classDef) = statement {
                // Check if target line is within this class's range
                if classDef.lineno <= lineNumber {
                    let classEndLine: Int
                    if let lastStatement = classDef.body.last {
                        classEndLine = getStatementEndLine(lastStatement)
                    } else {
                        classEndLine = classDef.lineno
                    }
                    
                    // If we're within the class range, check nested classes first
                    if lineNumber <= classEndLine {
                        // Check nested classes first to find most specific context
                        if let nested = findClassContainingLine(lineNumber, in: classDef.body) {
                            return nested
                        }
                        // If no nested class found, this is our context
                        return (name: classDef.name, classDef: classDef)
                    }
                }
            } else if case .functionDef(let funcDef) = statement {
                // Also check inside functions for nested classes
                if let nested = findClassContainingLine(lineNumber, in: funcDef.body) {
                    return nested
                }
            }
        }
        
        return nil
    }
    
    /// Infer simple type from expression
    private func inferSimpleType(_ expr: Expression) -> String {
        switch expr {
        case .constant(let constant):
            switch constant.value {
            case .int(_): return "int"
            case .float(_): return "float"
            case .string(_): return "str"
            case .bool(_): return "bool"
            case .none: return "None"
            default: return "Any"
            }
        case .list(_): return "list"
        case .dict(_): return "dict"
        case .tuple(_): return "tuple"
        case .set(_): return "set"
        default: return "Any"
        }
    }
    
    /// Describe an annotation expression
    private func describeExpression(_ expr: Expression) -> String {
        switch expr {
        case let .name(name):
            return name.id
        case let .subscriptExpr(subscriptExpr):
            // Handle subscript types like list[str], dict[int, str]
            if case let .name(baseType) = subscriptExpr.value {
                let sliceType = describeSubscriptSlice(subscriptExpr.slice)
                if sliceType.isEmpty {
                    return baseType.id
                }
                return "\(baseType.id)[\(sliceType)]"
            }
            return "Any"
        case let .constant(constant):
            // Handle constant types
            return inferConstantType(constant)
        default:
            return "Any"
        }
    }
    
    /// Describe a subscript slice for type annotations
    private func describeSubscriptSlice(_ slice: Expression) -> String {
        switch slice {
        case let .tuple(tupleExpr):
            let elements = tupleExpr.elts.map { describeExpression($0) }
            return elements.joined(separator: ", ")
        default:
            return describeExpression(slice)
        }
    }
    
    /// Infer type from a constant value
    private func inferConstantType(_ constant: Constant) -> String {
        switch constant.value {
        case .int(_):
            return "int"
        case .float(_):
            return "float"
        case .string(_):
            return "str"
        case .bool(_):
            return "bool"
        case .none:
            return "None"
        case .complex(_, _):
            return "complex"
        case .bytes(_):
            return "bytes"
        case .ellipsis:
            return "..."
        }
    }
}
