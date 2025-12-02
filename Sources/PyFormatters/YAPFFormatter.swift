import PySwiftAST
import PySwiftCodeGen

/// YAPF (Yet Another Python Formatter) style formatter
///
/// Implements YAPF's default PEP 8-based formatting rules for blank lines.
/// YAPF is Google's highly configurable Python formatter that defaults to PEP 8.
///
/// Key characteristics:
/// - 2 blank lines around top-level definitions
/// - 1 blank line before nested class/function definitions
/// - 1 blank line between top-level imports and variables
/// - Follows PEP 8 spacing conventions
///
/// Unlike Black (aggressive) or Google (conservative), YAPF is balanced and PEP 8 compliant.
public struct YAPFFormatter: PyFormatter {
    public init() {}
    
    /// Format module with YAPF's PEP 8 style (top-level only)
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
        var lastWasImport = false
        
        for (index, stmt) in statements.enumerated() {
            // Track if previous statement was an import
            if index > 0 {
                lastWasImport = isImport(statements[index - 1])
            }
            
            // Add 2 blank lines before top-level definitions (PEP 8)
            if index > 0 && isDefinition(stmt) {
                if lastWasImport {
                    // 1 blank line between imports and definitions
                    result.append(.blank(1))
                } else {
                    result.append(.blank(2))
                }
            }
            
            // Add 1 blank line between imports and variables
            if index > 0 && isVariable(stmt) && lastWasImport {
                if !isBlank(result.last) {
                    result.append(.blank(1))
                }
            }
            
            result.append(stmt)
            
            // Add 2 blank lines after definitions (except last item)
            if index < statements.count - 1 && isDefinition(stmt) {
                let nextStmt = statements[index + 1]
                if !isBlank(nextStmt) && !isImport(nextStmt) {
                    result.append(.blank(2))
                }
            }
        }
        
        return result
    }
    
    /// Recursively format with YAPF style
    public func formatDeep(_ module: Module) -> Module {
        let formatted = format(module)
        switch formatted {
        case .module(let statements):
            return .module(statements.map { formatStatementDeep($0) })
        case .interactive(let statements):
            return .interactive(statements.map { formatStatementDeep($0) })
        case .expression, .functionType:
            return formatted
        }
    }
    
    // MARK: - Statement Formatting
    
    private func formatStatementDeep(_ stmt: Statement) -> Statement {
        switch stmt {
        case .functionDef(var funcDef):
            funcDef.body = formatFunctionBody(funcDef.body)
            return .functionDef(funcDef)
            
        case .asyncFunctionDef(var funcDef):
            funcDef.body = formatFunctionBody(funcDef.body)
            return .asyncFunctionDef(funcDef)
            
        case .classDef(var classDef):
            classDef.body = formatClassBody(classDef.body)
            return .classDef(classDef)
            
        case .ifStmt(var ifStmt):
            ifStmt.body = ifStmt.body.map(formatStatementDeep)
            ifStmt.orElse = ifStmt.orElse.map(formatStatementDeep)
            return .ifStmt(ifStmt)
            
        case .whileStmt(var whileStmt):
            whileStmt.body = whileStmt.body.map(formatStatementDeep)
            whileStmt.orElse = whileStmt.orElse.map(formatStatementDeep)
            return .whileStmt(whileStmt)
            
        case .forStmt(var forStmt):
            forStmt.body = forStmt.body.map(formatStatementDeep)
            forStmt.orElse = forStmt.orElse.map(formatStatementDeep)
            return .forStmt(forStmt)
            
        case .asyncFor(var forStmt):
            forStmt.body = forStmt.body.map(formatStatementDeep)
            forStmt.orElse = forStmt.orElse.map(formatStatementDeep)
            return .asyncFor(forStmt)
            
        case .withStmt(var withStmt):
            withStmt.body = withStmt.body.map(formatStatementDeep)
            return .withStmt(withStmt)
            
        case .asyncWith(var withStmt):
            withStmt.body = withStmt.body.map(formatStatementDeep)
            return .asyncWith(withStmt)
            
        case .match(var matchStmt):
            matchStmt.cases = matchStmt.cases.map { matchCase in
                var c = matchCase
                c.body = c.body.map(formatStatementDeep)
                return c
            }
            return .match(matchStmt)
            
        case .tryStmt(var tryStmt):
            tryStmt.body = tryStmt.body.map(formatStatementDeep)
            tryStmt.orElse = tryStmt.orElse.map(formatStatementDeep)
            tryStmt.finalBody = tryStmt.finalBody.map(formatStatementDeep)
            tryStmt.handlers = tryStmt.handlers.map { handler in
                var h = handler
                h.body = h.body.map(formatStatementDeep)
                return h
            }
            return .tryStmt(tryStmt)
            
        case .tryStar(var tryStmt):
            tryStmt.body = tryStmt.body.map(formatStatementDeep)
            tryStmt.orElse = tryStmt.orElse.map(formatStatementDeep)
            tryStmt.finalBody = tryStmt.finalBody.map(formatStatementDeep)
            tryStmt.handlers = tryStmt.handlers.map { handler in
                var h = handler
                h.body = h.body.map(formatStatementDeep)
                return h
            }
            return .tryStar(tryStmt)
            
        default:
            return stmt
        }
    }
    
    // MARK: - Function and Class Body Formatting
    
    private func formatFunctionBody(_ statements: [Statement]) -> [Statement] {
        var result: [Statement] = []
        
        for (index, stmt) in statements.enumerated() {
            // YAPF: 1 blank line before nested class or function (PEP 8)
            if index > 0 && isDefinition(stmt) {
                if !isBlank(result.last) {
                    result.append(.blank(1))
                }
            }
            
            result.append(formatStatementDeep(stmt))
        }
        
        return result
    }
    
    private func formatClassBody(_ statements: [Statement]) -> [Statement] {
        var result: [Statement] = []
        var hasSeenDocstring = false
        
        for (index, stmt) in statements.enumerated() {
            // Track docstring
            if index == 0 && isDocstring(stmt) {
                hasSeenDocstring = true
                result.append(formatStatementDeep(stmt))
                continue
            }
            
            // YAPF: 1 blank line after docstring before first method
            if index == 1 && hasSeenDocstring && isDefinition(stmt) {
                if !isBlank(result.last) {
                    result.append(.blank(1))
                }
            }
            
            // 1 blank line between methods
            if index > 0 && isMethodDef(stmt) {
                if !isBlank(result.last) {
                    result.append(.blank(1))
                }
            }
            
            result.append(formatStatementDeep(stmt))
        }
        
        return result
    }
    
    // MARK: - Helper Functions
    
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
    
    private func isImport(_ stmt: Statement) -> Bool {
        switch stmt {
        case .importStmt, .importFrom:
            return true
        default:
            return false
        }
    }
    
    private func isVariable(_ stmt: Statement) -> Bool {
        switch stmt {
        case .assign, .annAssign, .augAssign:
            return true
        default:
            return false
        }
    }
    
    private func isDocstring(_ stmt: Statement) -> Bool {
        if case .expr(let exprStmt) = stmt {
            if case .constant(let constant) = exprStmt.value {
                if case .string = constant.value {
                    return true
                }
            }
        }
        return false
    }
    
    private func isBlank(_ stmt: Statement?) -> Bool {
        guard let stmt = stmt else { return false }
        if case .blank = stmt {
            return true
        }
        return false
    }
}
