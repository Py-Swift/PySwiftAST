import PySwiftAST
import PySwiftCodeGen

/// Google Python Style Guide formatter
///
/// Based on: https://github.com/google/styleguide/blob/gh-pages/pyguide.md
///
/// Key rules (Section 3.5 - Blank Lines):
/// - 2 blank lines between top-level definitions (functions or classes)
/// - 1 blank line between method definitions
/// - 1 blank line between class docstring and first method
/// - No blank line following a def line
/// - Single blank lines within functions as appropriate
public struct GoogleFormatter: PyFormatter {
    
    public init() {}
    
    /// Format a module's statements according to Google style
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
                // Check if previous statement was also a definition
                if let prevStmt = result.last, !isBlank(prevStmt) {
                    result.append(.blank(2))
                }
            }
            
            result.append(stmt)
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
            
            // Add single blank line after class docstring before first method
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
    /// Google style: No blank line following def, single blank lines as appropriate
    private func formatFunctionBody(_ statements: [Statement]) -> [Statement] {
        // For function bodies, Google style is more lenient
        // Just preserve the statements as-is, removing any blank lines immediately after def
        // (which would be handled by not adding them in the first place)
        return statements
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

extension GoogleFormatter {
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
