import PySwiftAST
import PySwiftCodeGen

/// Black-style formatter that enforces Black's blank line rules
///
/// Based on: https://black.readthedocs.io/en/stable/the_black_code_style/current_style.html
///
/// Key rules:
/// - 2 blank lines before/after module-level functions and classes
/// - 1 blank line before/after inner functions
/// - Single empty line between class docstring and first field/method
/// - Preserves single empty lines inside functions
/// - No empty lines after function docstrings (unless inner function follows)
public struct BlackFormatter {
    
    public init() {}
    
    /// Format a module's statements according to Black style
    public func format(_ module: Module) -> Module {
        switch module {
        case .module(let statements):
            let formatted = formatTopLevel(statements)
            return .module(formatted)
        case .interactive(let statements):
            let formatted = formatTopLevel(statements)
            return .interactive(formatted)
        case .expression, .functionType:
            return module
        }
    }
    
    /// Format top-level (module-level) statements
    private func formatTopLevel(_ statements: [Statement]) -> [Statement] {
        var result: [Statement] = []
        
        for (index, stmt) in statements.enumerated() {
            // Add 2 blank lines before function/class definitions (except first item)
            if index > 0 && isDefinition(stmt) {
                result.append(.blank(2))
            }
            
            result.append(stmt)
            
            // Add 2 blank lines after function/class definitions (except last item)
            if index < statements.count - 1 && isDefinition(stmt) {
                let nextStmt = statements[index + 1]
                if !isBlank(nextStmt) {
                    result.append(.blank(2))
                }
            }
        }
        
        return result
    }
    
    /// Format statements inside a class body
    private func formatClassBody(_ statements: [Statement]) -> [Statement] {
        var result: [Statement] = []
        var hadDocstring = false
        
        for (index, stmt) in statements.enumerated() {
            // Check if first statement is a docstring
            if index == 0, case .expr(let exprStmt) = stmt,
               case .constant(let constant) = exprStmt.value,
               case .string = constant.value {
                result.append(stmt)
                hadDocstring = true
                continue
            }
            
            // Add single blank line after class docstring before first field/method
            if index == 1 && hadDocstring {
                result.append(.blank(1))
            }
            
            // Add single blank line before method definitions (but not first item)
            if index > 0 && isMethodDef(stmt) {
                let prevIndex = result.count - 1
                if prevIndex >= 0 && !isBlank(result[prevIndex]) {
                    result.append(.blank(1))
                }
            }
            
            result.append(stmt)
        }
        
        return result
    }
    
    /// Format statements inside a function body
    private func formatFunctionBody(_ statements: [Statement]) -> [Statement] {
        var result: [Statement] = []
        var hasDocstring = false
        
        for (index, stmt) in statements.enumerated() {
            // Check if first statement is a docstring
            if index == 0, case .expr(let exprStmt) = stmt,
               case .constant(let constant) = exprStmt.value,
               case .string = constant.value {
                result.append(stmt)
                hasDocstring = true
                continue
            }
            
            // Add 1 blank line before inner function definitions
            if isDefinition(stmt) {
                // Check if this is right after docstring
                let shouldAddBlank = if index == 1 && hasDocstring {
                    false // No blank line after function docstring unless needed
                } else {
                    index > 0
                }
                
                if shouldAddBlank {
                    let prevIndex = result.count - 1
                    if prevIndex >= 0 && !isBlank(result[prevIndex]) {
                        result.append(.blank(1))
                    }
                }
            }
            
            result.append(stmt)
            
            // Add 1 blank line after inner function definitions
            if isDefinition(stmt) && index < statements.count - 1 {
                let nextStmt = statements[index + 1]
                if !isBlank(nextStmt) {
                    result.append(.blank(1))
                }
            }
        }
        
        return result
    }
    
    // MARK: - Helper Methods
    
    private func isDefinition(_ stmt: Statement) -> Bool {
        switch stmt {
        case .functionDef, .asyncFunctionDef, .classDef:
            return true
        default:
            return false
        }
    }
    
    private func isMethodDef(_ stmt: Statement) -> Bool {
        switch stmt {
        case .functionDef, .asyncFunctionDef:
            return true
        default:
            return false
        }
    }
    
    private func isBlank(_ stmt: Statement) -> Bool {
        if case .blank = stmt {
            return true
        }
        return false
    }
}

// MARK: - Deep Formatting

extension BlackFormatter {
    /// Recursively format all statements in a module and nested structures
    public func formatDeep(_ module: Module) -> Module {
        switch module {
        case .module(let statements):
            let formatted = formatStatementsDeep(statements, level: .topLevel)
            return .module(formatted)
        case .interactive(let statements):
            let formatted = formatStatementsDeep(statements, level: .topLevel)
            return .interactive(formatted)
        case .expression, .functionType:
            return module
        }
    }
    
    private enum NestingLevel {
        case topLevel
        case classBody
        case functionBody
    }
    
    private func formatStatementsDeep(_ statements: [Statement], level: NestingLevel) -> [Statement] {
        // First apply appropriate blank line formatting for this level
        let formatted = switch level {
        case .topLevel:
            formatTopLevel(statements)
        case .classBody:
            formatClassBody(statements)
        case .functionBody:
            formatFunctionBody(statements)
        }
        
        // Then recursively format nested structures
        return formatted.map { stmt in
            formatStatementDeep(stmt)
        }
    }
    
    private func formatStatementDeep(_ stmt: Statement) -> Statement {
        switch stmt {
        case .functionDef(var funcDef):
            funcDef.body = formatStatementsDeep(funcDef.body, level: .functionBody)
            return .functionDef(funcDef)
            
        case .asyncFunctionDef(var funcDef):
            funcDef.body = formatStatementsDeep(funcDef.body, level: .functionBody)
            return .asyncFunctionDef(funcDef)
            
        case .classDef(var classDef):
            classDef.body = formatStatementsDeep(classDef.body, level: .classBody)
            return .classDef(classDef)
            
        case .ifStmt(var ifStmt):
            ifStmt.body = formatStatementsDeep(ifStmt.body, level: .functionBody)
            ifStmt.orElse = formatStatementsDeep(ifStmt.orElse, level: .functionBody)
            return .ifStmt(ifStmt)
            
        case .whileStmt(var whileStmt):
            whileStmt.body = formatStatementsDeep(whileStmt.body, level: .functionBody)
            whileStmt.orElse = formatStatementsDeep(whileStmt.orElse, level: .functionBody)
            return .whileStmt(whileStmt)
            
        case .forStmt(var forStmt):
            forStmt.body = formatStatementsDeep(forStmt.body, level: .functionBody)
            forStmt.orElse = formatStatementsDeep(forStmt.orElse, level: .functionBody)
            return .forStmt(forStmt)
            
        case .asyncFor(var forStmt):
            forStmt.body = formatStatementsDeep(forStmt.body, level: .functionBody)
            forStmt.orElse = formatStatementsDeep(forStmt.orElse, level: .functionBody)
            return .asyncFor(forStmt)
            
        case .withStmt(var withStmt):
            withStmt.body = formatStatementsDeep(withStmt.body, level: .functionBody)
            return .withStmt(withStmt)
            
        case .asyncWith(var withStmt):
            withStmt.body = formatStatementsDeep(withStmt.body, level: .functionBody)
            return .asyncWith(withStmt)
            
        case .tryStmt(var tryStmt):
            tryStmt.body = formatStatementsDeep(tryStmt.body, level: .functionBody)
            tryStmt.orElse = formatStatementsDeep(tryStmt.orElse, level: .functionBody)
            tryStmt.finalBody = formatStatementsDeep(tryStmt.finalBody, level: .functionBody)
            tryStmt.handlers = tryStmt.handlers.map { handler in
                var h = handler
                h.body = formatStatementsDeep(h.body, level: .functionBody)
                return h
            }
            return .tryStmt(tryStmt)
            
        case .tryStar(var tryStmt):
            tryStmt.body = formatStatementsDeep(tryStmt.body, level: .functionBody)
            tryStmt.orElse = formatStatementsDeep(tryStmt.orElse, level: .functionBody)
            tryStmt.finalBody = formatStatementsDeep(tryStmt.finalBody, level: .functionBody)
            tryStmt.handlers = tryStmt.handlers.map { handler in
                var h = handler
                h.body = formatStatementsDeep(h.body, level: .functionBody)
                return h
            }
            return .tryStar(tryStmt)
            
        case .match(var matchStmt):
            matchStmt.cases = matchStmt.cases.map { matchCase in
                var mc = matchCase
                mc.body = formatStatementsDeep(mc.body, level: .functionBody)
                return mc
            }
            return .match(matchStmt)
            
        default:
            // For other statement types, return as-is
            return stmt
        }
    }
}
