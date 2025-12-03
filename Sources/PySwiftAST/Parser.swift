import Foundation

/// Main parser class that converts tokens into an AST
/// This will be generated/expanded from Python's PEG grammar
public class Parser {
    private let tokens: [Token]
    private var position: Int = 0
    private var sourceLines: [String] = []
    
    public init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    public convenience init(tokens: [Token], source: String) {
        self.init(tokens: tokens)
        self.sourceLines = source.components(separatedBy: .newlines)
    }
    
    /// Parse the tokens into a Module
    public func parse() throws -> Module {
        // For now, implement a simple expression parser
        // This will be expanded with the full Python grammar
        let statements = try parseStatements()
        return .module(statements)
    }
    
    // MARK: - Basic Parsing Methods
    
    private func parseStatements() throws -> [Statement] {
        var statements: [Statement] = []
        
        while !isAtEnd() && currentToken().type != .endmarker {
            // Skip newlines and comments
            if currentToken().type == .newline {
                advance()
                continue
            }
            
            if case .comment = currentToken().type {
                advance()
                continue
            }
            
            if case .typeComment = currentToken().type {
                advance()
                continue
            }
            
            let stmt = try parseStatement()
            statements.append(stmt)
        }
        
        return statements
    }
    
    private func parseStatement() throws -> Statement {
        let token = currentToken()
        
        switch token.type {
        case .pass:
            let line = token.line
            let col = token.column
            advance()
            consumeNewlineOrSemicolon()
            return .pass(Pass(lineno: line, colOffset: col, endLineno: line, endColOffset: col))
            
        case .return:
            return try parseReturn()
            
        case .break:
            let line = token.line
            let col = token.column
            advance()
            consumeNewlineOrSemicolon()
            return .breakStmt(Break(lineno: line, colOffset: col, endLineno: line, endColOffset: col))
            
        case .continue:
            let line = token.line
            let col = token.column
            advance()
            consumeNewlineOrSemicolon()
            return .continueStmt(Continue(lineno: line, colOffset: col, endLineno: line, endColOffset: col))
            
        case .if:
            return try parseIf()
            
        case .for:
            return try parseFor()
            
        case .while:
            return try parseWhile()
            
        case .def:
            return try parseFunctionDef(decorators: [])
            
        case .class:
            return try parseClassDef(decorators: [])
            
        case .at:
            // Decorator
            return try parseDecorated()
            
        case .async:
            // Async function or async for/with
            return try parseAsync()
            
        case .import:
            return try parseImport()
            
        case .from:
            return try parseFromImport()
            
        case .with:
            return try parseWith()
            
        case .try:
            return try parseTry()
            
        case .raise:
            return try parseRaise()
            
        case .assert:
            return try parseAssert()
            
        case .match:
            return try parseMatch()
            
        case .global:
            return try parseGlobal()
            
        case .nonlocal:
            return try parseNonlocal()
            
        case .del:
            return try parseDel()
            
        case .name(let name) where name == "type":
            // "type" is a soft keyword in Python 3.12+ for type aliases
            return try parseTypeAlias()
            
        case .yield:
            return try parseYield()
            
        default:
            // Try to parse as expression statement or assignment
            var expr = try parseStarExpression()
            
            // Check for comma - could be tuple expression (e.g., a, b, c = 1, 2, 3)
            if currentToken().type == .comma {
                var elements = [expr]
                while currentToken().type == .comma {
                    advance() // consume ','
                    // Check for trailing comma or end of statement
                    if isNewlineOrSemicolon() || isAtEnd() {
                        break
                    }
                    elements.append(try parseStarExpression())
                }
                
                expr = .tuple(Tuple(
                    elts: elements,
                    ctx: .load,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            // Grammar: assignment[stmt_ty]: 
            //   | NAME ':' expression ['=' annotated_rhs] → AnnAssign(target, annotation, value, simple=1)
            //   | (single_target | single_subscript_attribute_target) ':' expression ['=' annotated_rhs] → AnnAssign(target, annotation, value, simple=0)
            // Where single_subscript_attribute_target includes:
            //   - Attribute: t_primary '.' NAME (e.g., self.x)
            //   - Subscript: t_primary '[' slices ']' (e.g., dict[key])
            if currentToken().type == .colon {
                // Validate target is a valid annotation target per grammar
                let isSimple: Bool
                switch expr {
                case .name:
                    isSimple = true  // simple=1 for NAME targets
                case .attribute, .subscriptExpr:
                    isSimple = false  // simple=0 for attribute/subscript targets
                default:
                    throw ParseError.expected(message: "Invalid target for type annotation", line: currentToken().line)
                }
                
                advance() // consume ':'
                let annotation = try parseExpression()
                
                // Check if there's also an assignment
                var value: Expression? = nil
                if currentToken().type == .assign {
                    advance() // consume '='
                    value = try parseExpression()
                }
                
                consumeNewlineOrSemicolon()
                return .annAssign(AnnAssign(
                    target: expr,
                    annotation: annotation,
                    value: value,
                    simple: isSimple,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            // Check for assignment
            if currentToken().type == .assign {
                // Validate that the left side is a valid assignment target
                switch expr {
                case .name, .attribute, .subscriptExpr, .tuple, .list:
                    // Valid assignment targets
                    break
                case .starred:
                    // Starred expressions are valid in tuple/list unpacking
                    break
                default:
                    throw ParseError.expected(message: "Invalid assignment target", line: token.line)
                }
                
                // Collect all targets for chained assignment (e.g., a = b = c = 1)
                var targets = [expr]
                
                while currentToken().type == .assign {
                    advance() // consume '='
                    
                    // Parse next part - could be another target or the final value
                    var nextExpr = try parseExpression()
                    
                    // Check if this is a tuple
                    if currentToken().type == .comma {
                        var elements = [nextExpr]
                        while currentToken().type == .comma {
                            advance()
                            if isNewlineOrSemicolon() || isAtEnd() || currentToken().type == .assign {
                                break
                            }
                            elements.append(try parseExpression())
                        }
                        nextExpr = .tuple(Tuple(
                            elts: elements,
                            ctx: .load,
                            lineno: token.line,
                            colOffset: token.column,
                            endLineno: nil,
                            endColOffset: nil
                        ))
                    }
                    
                    // If there's another '=', this is a target, not the value
                    if currentToken().type == .assign {
                        targets.append(nextExpr)
                    } else {
                        // This is the final value
                        consumeNewlineOrSemicolon()
                        return .assign(Assign(
                            targets: targets,
                            value: nextExpr,
                            typeComment: nil,
                            lineno: token.line,
                            colOffset: token.column,
                            endLineno: nil,
                            endColOffset: nil
                        ))
                    }
                }
                
                // Should not reach here
                throw ParseError.expected(message: "Expected value in assignment", line: currentToken().line)
            }
            
            // Check for augmented assignment
            if isAugmentedAssignOp() {
                let augOp = try parseAugmentedAssignOp()
                let value = try parseExpression()
                consumeNewlineOrSemicolon()
                return .augAssign(AugAssign(
                    target: expr,
                    op: augOp,
                    value: value,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            consumeNewlineOrSemicolon()
            return .expr(Expr(value: expr, lineno: token.line, colOffset: token.column, endLineno: nil, endColOffset: nil))
        }
    }
    
    private func parseReturn() throws -> Statement {
        let returnToken = currentToken()
        advance() // consume 'return'
        
        // Skip comments after 'return' keyword
        skipComments()
        
        var value: Expression? = nil
        if !isNewlineOrSemicolon() && !isAtEnd() {
            // Parse the first expression
            let first = try parseExpression()
            
            // Check if this is an implicit tuple: return a, b, c
            if currentToken().type == .comma {
                var elts = [first]
                while currentToken().type == .comma {
                    advance()
                    // Check for trailing comma before newline
                    if isNewlineOrSemicolon() || isAtEnd() {
                        break
                    }
                    elts.append(try parseExpression())
                }
                // Create implicit tuple
                value = .tuple(Tuple(
                    elts: elts,
                    ctx: .load,
                    lineno: returnToken.line,
                    colOffset: returnToken.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            } else {
                value = first
            }
        }
        
        consumeNewlineOrSemicolon()
        
        return .returnStmt(Return(
            value: value,
            lineno: returnToken.line,
            colOffset: returnToken.column,
            endLineno: returnToken.endLine,
            endColOffset: returnToken.endColumn
        ))
    }
    
    private func parseFor() throws -> Statement {
        let forToken = currentToken()
        advance() // consume 'for'
        
        // Parse target (can be a tuple like: i, j)
        var targetExprs = [try parseBitwiseOrExpression()]
        while currentToken().type == .comma {
            advance()
            // Check if we've hit 'in' (trailing comma case)
            if currentToken().type == .in {
                break
            }
            targetExprs.append(try parseBitwiseOrExpression())
        }
        
        let target: Expression
        if targetExprs.count == 1 {
            target = targetExprs[0]
        } else {
            target = .tuple(Tuple(
                elts: targetExprs,
                ctx: .store,
                lineno: forToken.line,
                colOffset: forToken.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        try consume(.in, "Expected 'in' in for loop")
        let iter = try parseExpression()
        try consume(.colon, "Expected ':' after for clause")
        
        let body = try parseBlock()
        
        var orElse: [Statement] = []
        if currentToken().type == .else {
            advance()
            try consume(.colon, "Expected ':' after else")
            orElse = try parseBlock()
        }
        
        return .forStmt(For(
            target: target,
            iter: iter,
            body: body,
            orElse: orElse,
            typeComment: nil,
            lineno: forToken.line,
            colOffset: forToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseWhile() throws -> Statement {
        let whileToken = currentToken()
        advance() // consume 'while'
        
        let test = try parseExpression()
        try consume(.colon, "Expected ':' after while condition")
        
        let body = try parseBlock()
        
        var orElse: [Statement] = []
        if currentToken().type == .else {
            advance()
            try consume(.colon, "Expected ':' after else")
            orElse = try parseBlock()
        }
        
        return .whileStmt(While(
            test: test,
            body: body,
            orElse: orElse,
            lineno: whileToken.line,
            colOffset: whileToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseWith() throws -> Statement {
        let withToken = currentToken()
        advance() // consume 'with'
        
        var items: [WithItem] = []
        
        // Parse first with item
        let contextExpr = try parseExpression()
        var optionalVars: Expression? = nil
        
        if currentToken().type == .as {
            advance()
            optionalVars = try parseExpression()
        }
        
        items.append(WithItem(contextExpr: contextExpr, optionalVars: optionalVars))
        
        // Parse additional with items
        while currentToken().type == .comma {
            advance()
            let expr = try parseExpression()
            var vars: Expression? = nil
            if currentToken().type == .as {
                advance()
                vars = try parseExpression()
            }
            items.append(WithItem(contextExpr: expr, optionalVars: vars))
        }
        
        try consume(.colon, "Expected ':' after with clause")
        let body = try parseBlock()
        
        return .withStmt(With(
            items: items,
            body: body,
            typeComment: nil,
            lineno: withToken.line,
            colOffset: withToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseTry() throws -> Statement {
        let tryToken = currentToken()
        advance() // consume 'try'
        
        try consume(.colon, "Expected ':' after try")
        let body = try parseBlock()
        
        var handlers: [ExceptHandler] = []
        var orElse: [Statement] = []
        var finalbody: [Statement] = []
        
        // Parse except clauses
        while currentToken().type == .except {
            advance()
            
            var type: Expression? = nil
            var name: String? = nil
            
            if currentToken().type != .colon {
                type = try parseExpression()
                
                if currentToken().type == .as {
                    advance()
                    guard case .name(let excName) = currentToken().type else {
                        throw ParseError.expected(message: "Expected exception name after 'as'", line: currentToken().line)
                    }
                    name = excName
                    advance()
                }
            }
            
            try consume(.colon, "Expected ':' after except clause")
            let handlerBody = try parseBlock()
            
            handlers.append(ExceptHandler(
                type: type,
                name: name,
                body: handlerBody
            ))
        }
        
        // Parse else clause
        if currentToken().type == .else {
            advance()
            try consume(.colon, "Expected ':' after else")
            orElse = try parseBlock()
        }
        
        // Parse finally clause
        if currentToken().type == .finally {
            advance()
            try consume(.colon, "Expected ':' after finally")
            finalbody = try parseBlock()
        }
        
        return .tryStmt(Try(
            body: body,
            handlers: handlers,
            orElse: orElse,
            finalBody: finalbody,
            lineno: tryToken.line,
            colOffset: tryToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseRaise() throws -> Statement {
        let raiseToken = currentToken()
        advance() // consume 'raise'
        
        var exc: Expression? = nil
        var cause: Expression? = nil
        
        if !isNewlineOrSemicolon() && !isAtEnd() {
            exc = try parseExpression()
            
            if currentToken().type == .from {
                advance()
                cause = try parseExpression()
            }
        }
        
        consumeNewlineOrSemicolon()
        
        return .raise(Raise(
            exc: exc,
            cause: cause,
            lineno: raiseToken.line,
            colOffset: raiseToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseAssert() throws -> Statement {
        let assertToken = currentToken()
        advance() // consume 'assert'
        
        let test = try parseExpression()
        
        var msg: Expression? = nil
        if currentToken().type == .comma {
            advance()
            msg = try parseExpression()
        }
        
        consumeNewlineOrSemicolon()
        
        return .assertStmt(Assert(
            test: test,
            msg: msg,
            lineno: assertToken.line,
            colOffset: assertToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseMatch() throws -> Statement {
        let matchToken = currentToken()
        advance() // consume 'match'
        
        let subject = try parseExpression()
        try consume(.colon, "Expected ':' after match subject")
        
        try consume(.newline, "Expected newline before match cases")
        try consume(.indent, "Expected indent for match cases")
        
        var cases: [MatchCase] = []
        
        while currentToken().type != .dedent && !isAtEnd() {
            if currentToken().type == .newline {
                advance()
                continue
            }
            
            guard currentToken().type == .case else {
                throw ParseError.expected(message: "Expected 'case' in match statement", line: currentToken().line)
            }
            advance() // consume 'case'
            
            let pattern = try parsePattern()
            
            var guardExpr: Expression? = nil
            if currentToken().type == .if {
                advance()
                guardExpr = try parseExpression()
            }
            
            try consume(.colon, "Expected ':' after case pattern")
            
            let body = try parseBlock()
            
            cases.append(MatchCase(
                pattern: pattern,
                guardExpr: guardExpr,
                body: body
            ))
        }
        
        try consume(.dedent, "Expected dedent after match cases")
        
        return .match(Match(
            subject: subject,
            cases: cases,
            lineno: matchToken.line,
            colOffset: matchToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parsePattern() throws -> Pattern {
        let token = currentToken()
        
        // Wildcard pattern
        if case .name(let name) = token.type, name == "_" {
            advance()
            return .matchAs(MatchAs(
                pattern: nil,
                name: nil
            ))
        }
        
        // For now, simple pattern matching - just parse as expression
        // Full pattern syntax would need more sophisticated parsing
        let expr = try parseExpression()
        
        // Convert expression to pattern (simplified)
        return .matchValue(MatchValue(
            value: expr
        ))
    }
    
    private func parseGlobal() throws -> Statement {
        let globalToken = currentToken()
        advance() // consume 'global'
        
        var names: [String] = []
        
        guard case .name(let first) = currentToken().type else {
            throw ParseError.expected(message: "Expected name after 'global'", line: currentToken().line)
        }
        names.append(first)
        advance()
        
        while currentToken().type == .comma {
            advance()
            guard case .name(let name) = currentToken().type else {
                throw ParseError.expected(message: "Expected name after ','", line: currentToken().line)
            }
            names.append(name)
            advance()
        }
        
        consumeNewlineOrSemicolon()
        
        return .global(Global(
            names: names,
            lineno: globalToken.line,
            colOffset: globalToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseNonlocal() throws -> Statement {
        let nonlocalToken = currentToken()
        advance() // consume 'nonlocal'
        
        var names: [String] = []
        
        guard case .name(let first) = currentToken().type else {
            throw ParseError.expected(message: "Expected name after 'nonlocal'", line: currentToken().line)
        }
        names.append(first)
        advance()
        
        while currentToken().type == .comma {
            advance()
            guard case .name(let name) = currentToken().type else {
                throw ParseError.expected(message: "Expected name after ','", line: currentToken().line)
            }
            names.append(name)
            advance()
        }
        
        consumeNewlineOrSemicolon()
        
        return .nonlocal(Nonlocal(
            names: names,
            lineno: nonlocalToken.line,
            colOffset: nonlocalToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseTypeAlias() throws -> Statement {
        let typeToken = currentToken()
        advance() // consume 'type'
        
        // Parse name
        guard case .name(let name) = currentToken().type else {
            throw ParseError.expected(message: "Expected name after 'type'", line: currentToken().line)
        }
        let nameExpr = Expression.name(Name(
            id: name,
            ctx: .store,
            lineno: currentToken().line,
            colOffset: currentToken().column,
            endLineno: nil,
            endColOffset: nil
        ))
        advance()
        
        // Parse optional type parameters [T], [T, U], etc.
        var typeParams: [TypeParam] = []
        if currentToken().type == .leftbracket {
            advance() // consume '['
            
            typeParams = try parseTypeParameters()
            
            guard currentToken().type == .rightbracket else {
                throw ParseError.expected(message: "Expected ']' after type parameters", line: currentToken().line)
            }
            advance() // consume ']'
        }
        
        // Parse '='
        guard currentToken().type == .assign else {
            throw ParseError.expected(message: "Expected '=' after type alias name", line: currentToken().line)
        }
        advance() // consume '='
        
        // Parse type expression
        let value = try parseExpression()
        
        consumeNewlineOrSemicolon()
        
        return .typeAlias(TypeAlias(
            name: nameExpr,
            typeParams: typeParams,
            value: value,
            lineno: typeToken.line,
            colOffset: typeToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseDel() throws -> Statement {
        let delToken = currentToken()
        advance() // consume 'del'
        
        var targets: [Expression] = []
        
        targets.append(try parseExpression())
        
        while currentToken().type == .comma {
            advance()
            targets.append(try parseExpression())
        }
        
        consumeNewlineOrSemicolon()
        
        return .delete(Delete(
            targets: targets,
            lineno: delToken.line,
            colOffset: delToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseYield() throws -> Statement {
        let yieldToken = currentToken()
        advance() // consume 'yield'
        
        var value: Expression? = nil
        
        if currentToken().type == .from {
            advance()
            let fromValue = try parseExpression()
            consumeNewlineOrSemicolon()
            
            return .expr(Expr(
                value: .yieldFrom(YieldFrom(
                    value: fromValue,
                    lineno: yieldToken.line,
                    colOffset: yieldToken.column,
                    endLineno: nil,
                    endColOffset: nil
                )),
                lineno: yieldToken.line,
                colOffset: yieldToken.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        if !isNewlineOrSemicolon() && !isAtEnd() {
            value = try parseExpression()
        }
        
        consumeNewlineOrSemicolon()
        
        return .expr(Expr(
            value: .yield(Yield(
                value: value,
                lineno: yieldToken.line,
                colOffset: yieldToken.column,
                endLineno: nil,
                endColOffset: nil
            )),
            lineno: yieldToken.line,
            colOffset: yieldToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func isAugmentedAssignOp() -> Bool {
        switch currentToken().type {
        case .plusequal, .minusequal, .starequal, .slashequal, .doubleslashequal,
             .percentequal, .doublestarequal, .amperequal, .vbarequal, .circumflexequal,
             .leftshiftequal, .rightshiftequal, .atequal:
            return true
        default:
            return false
        }
    }
    
    private func parseAugmentedAssignOp() throws -> Operator {
        let type = currentToken().type
        advance()
        
        switch type {
        case .plusequal: return .add
        case .minusequal: return .sub
        case .starequal: return .mult
        case .slashequal: return .div
        case .doubleslashequal: return .floorDiv
        case .percentequal: return .mod
        case .doublestarequal: return .pow
        case .amperequal: return .bitAnd
        case .vbarequal: return .bitOr
        case .circumflexequal: return .bitXor
        case .leftshiftequal: return .lShift
        case .rightshiftequal: return .rShift
        case .atequal: return .matMult
        default:
            throw ParseError.expected(message: "Expected augmented assignment operator", line: currentToken().line)
        }
    }
    
    private func parseIf() throws -> Statement {
        let ifToken = currentToken()
        advance() // consume 'if'
        
        let test = try parseExpression()
        try consume(.colon, "Expected ':' after if condition")
        
        let body = try parseBlock()
        
        var orElse: [Statement] = []
        
        // Handle elif and else
        if currentToken().type == .elif {
            // Recursively parse elif as a nested if statement
            orElse = [try parseIf()]
        } else if currentToken().type == .else {
            advance()
            try consume(.colon, "Expected ':' after else")
            orElse = try parseBlock()
        }
        
        return .ifStmt(If(
            test: test,
            body: body,
            orElse: orElse,
            lineno: ifToken.line,
            colOffset: ifToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseFunctionDef(decorators: [Expression] = []) throws -> Statement {
        let defToken = currentToken()
        advance() // consume 'def'
        
        guard case .name(let name) = currentToken().type else {
            throw ParseError.expectedName(line: currentToken().line)
        }
        advance()
        
        // Parse optional type parameters [T], [T, U], etc.
        var typeParams: [TypeParam] = []
        if currentToken().type == .leftbracket {
            advance() // consume '['
            typeParams = try parseTypeParameters()
            try consume(.rightbracket, "Expected ']' after type parameters")
        }
        
        try consume(.leftparen, "Expected '(' after function name")
        let args = try parseArguments()
        try consume(.rightparen, "Expected ')' after function arguments")
        
        // Check for return type annotation
        var returns: Expression? = nil
        if currentToken().type == .arrow {
            advance()
            returns = try parseExpression()
        }
        
        try consume(.colon, "Expected ':' after function signature")
        
        let body = try parseBlock()
        
        return .functionDef(FunctionDef(
            name: name,
            args: args,
            body: body,
            decoratorList: decorators,
            returns: returns,
            typeComment: nil,
            typeParams: typeParams,
            lineno: defToken.line,
            colOffset: defToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseClassDef(decorators: [Expression] = []) throws -> Statement {
        let classToken = currentToken()
        advance() // consume 'class'
        
        guard case .name(let name) = currentToken().type else {
            throw ParseError.expectedName(line: currentToken().line)
        }
        advance()
        
        // Parse optional type parameters [T], [T, U], etc.
        var typeParams: [TypeParam] = []
        if currentToken().type == .leftbracket {
            advance() // consume '['
            typeParams = try parseTypeParameters()
            try consume(.rightbracket, "Expected ']' after type parameters")
        }
        
        var bases: [Expression] = []
        var keywords: [Keyword] = []
        
        // Parse base classes if present
        if currentToken().type == .leftparen {
            advance()
            
            if currentToken().type != .rightparen {
                // Parse base classes and keyword arguments
                while true {
                    // Check for keyword argument (like metaclass=Meta)
                    if case .name(let argName) = currentToken().type {
                        let nextPos = position + 1
                        if nextPos < tokens.count && tokens[nextPos].type == .assign {
                            // Keyword argument
                            advance() // consume name
                            advance() // consume '='
                            let value = try parseExpression()
                            keywords.append(Keyword(arg: argName, value: value))
                            
                            if currentToken().type == .comma {
                                advance()
                                if currentToken().type == .rightparen {
                                    break
                                }
                            } else {
                                break
                            }
                            continue
                        }
                    }
                    
                    // Regular base class
                    bases.append(try parseExpression())
                    
                    if currentToken().type == .comma {
                        advance()
                        if currentToken().type == .rightparen {
                            break
                        }
                    } else {
                        break
                    }
                }
            }
            
            try consume(.rightparen, "Expected ')' after class bases")
        }
        
        try consume(.colon, "Expected ':' after class name")
        
        let body = try parseBlock()
        
        return .classDef(ClassDef(
            name: name,
            bases: bases,
            keywords: keywords,
            body: body,
            decoratorList: decorators,
            typeParams: typeParams,
            lineno: classToken.line,
            colOffset: classToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseDecorated() throws -> Statement {
        var decorators: [Expression] = []
        
        // Parse all decorators
        while currentToken().type == .at {
            advance() // consume '@'
            let decorator = try parseExpression()
            consumeNewlineOrSemicolon()
            decorators.append(decorator)
        }
        
        // Now parse the function or class definition
        if currentToken().type == .def {
            return try parseFunctionDef(decorators: decorators)
        } else if currentToken().type == .class {
            return try parseClassDef(decorators: decorators)
        } else {
            throw ParseError.expected(message: "Expected 'def' or 'class' after decorator(s)", line: currentToken().line)
        }
    }
    
    private func parseAsync() throws -> Statement {
        advance() // consume 'async'
        
        if currentToken().type == .def {
            // Async function
            return try parseAsyncFunctionDef(decorators: [])
        } else if currentToken().type == .for {
            // Async for
            return try parseAsyncFor()
        } else if currentToken().type == .with {
            // Async with
            return try parseAsyncWith()
        } else {
            throw ParseError.expected(message: "Expected 'def', 'for', or 'with' after 'async'", line: currentToken().line)
        }
    }
    
    private func parseAsyncFunctionDef(decorators: [Expression]) throws -> Statement {
        let defToken = currentToken() // We're already on 'def' after consuming 'async'
        advance()
        
        guard case .name(let name) = currentToken().type else {
            throw ParseError.expectedName(line: currentToken().line)
        }
        advance()
        
        // Parse optional type parameters [T], [T, U], etc.
        var typeParams: [TypeParam] = []
        if currentToken().type == .leftbracket {
            advance() // consume '['
            typeParams = try parseTypeParameters()
            try consume(.rightbracket, "Expected ']' after type parameters")
        }
        
        try consume(.leftparen, "Expected '(' after function name")
        let args = try parseArguments()
        try consume(.rightparen, "Expected ')' after function arguments")
        
        // Check for return type annotation
        var returns: Expression? = nil
        if currentToken().type == .arrow {
            advance()
            returns = try parseExpression()
        }
        
        try consume(.colon, "Expected ':' after function signature")
        
        let body = try parseBlock()
        
        return .asyncFunctionDef(AsyncFunctionDef(
            name: name,
            args: args,
            body: body,
            decoratorList: decorators,
            returns: returns,
            typeComment: nil,
            typeParams: typeParams,
            lineno: defToken.line,
            colOffset: defToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseAsyncFor() throws -> Statement {
        let forToken = currentToken()
        advance() // We're on 'for'
        
        // Parse target (can be a tuple like: i, j)
        // Use parseBitwiseOrExpression to avoid consuming 'in' as an operator
        var targetExprs = [try parseBitwiseOrExpression()]
        while currentToken().type == .comma {
            advance()
            // Check if we've hit 'in' (trailing comma case)
            if currentToken().type == .in {
                break
            }
            targetExprs.append(try parseBitwiseOrExpression())
        }
        
        let target: Expression
        if targetExprs.count == 1 {
            target = targetExprs[0]
        } else {
            target = .tuple(Tuple(
                elts: targetExprs,
                ctx: .store,
                lineno: forToken.line,
                colOffset: forToken.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        try consume(.in, "Expected 'in' in async for loop")
        let iter = try parseExpression()
        try consume(.colon, "Expected ':' after async for clause")
        
        let body = try parseBlock()
        
        var orElse: [Statement] = []
        if currentToken().type == .else {
            advance()
            try consume(.colon, "Expected ':' after else")
            orElse = try parseBlock()
        }
        
        return .asyncFor(AsyncFor(
            target: target,
            iter: iter,
            body: body,
            orElse: orElse,
            typeComment: nil,
            lineno: forToken.line,
            colOffset: forToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseAsyncWith() throws -> Statement {
        let withToken = currentToken()
        advance() // We're on 'with'
        
        var items: [WithItem] = []
        
        // Parse first with item
        let contextExpr = try parseExpression()
        var optionalVars: Expression? = nil
        
        if currentToken().type == .as {
            advance()
            optionalVars = try parseExpression()
        }
        
        items.append(WithItem(contextExpr: contextExpr, optionalVars: optionalVars))
        
        // Parse additional with items
        while currentToken().type == .comma {
            advance()
            let expr = try parseExpression()
            var vars: Expression? = nil
            if currentToken().type == .as {
                advance()
                vars = try parseExpression()
            }
            items.append(WithItem(contextExpr: expr, optionalVars: vars))
        }
        
        try consume(.colon, "Expected ':' after async with clause")
        let body = try parseBlock()
        
        return .asyncWith(AsyncWith(
            items: items,
            body: body,
            typeComment: nil,
            lineno: withToken.line,
            colOffset: withToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseImport() throws -> Statement {
        let importToken = currentToken()
        advance() // consume 'import'
        
        var names: [Alias] = []
        
        // Parse first import name (with dotted module support)
        guard case .name(let firstName) = currentToken().type else {
            throw ParseError.expected(message: "Expected module name after 'import'", line: currentToken().line)
        }
        var moduleName = firstName
        advance()
        
        // Handle dotted module names (e.g., urllib.request)
        while currentToken().type == .dot {
            moduleName += "."
            advance()
            
            if case .name(let part) = currentToken().type {
                moduleName += part
                advance()
            } else {
                throw ParseError.expected(message: "Expected name after '.' in module path", line: currentToken().line)
            }
        }
        
        var asName: String? = nil
        if currentToken().type == .as {
            advance()
            guard case .name(let alias) = currentToken().type else {
                throw ParseError.expected(message: "Expected alias name after 'as'", line: currentToken().line)
            }
            asName = alias
            advance()
        }
        
        names.append(Alias(name: moduleName, asName: asName))
        
        // Parse additional imports separated by commas
        while currentToken().type == .comma {
            advance() // consume ','
            
            guard case .name(let firstName) = currentToken().type else {
                throw ParseError.expected(message: "Expected module name", line: currentToken().line)
            }
            var name = firstName
            advance()
            
            // Handle dotted module names for additional imports
            while currentToken().type == .dot {
                name += "."
                advance()
                
                if case .name(let part) = currentToken().type {
                    name += part
                    advance()
                } else {
                    throw ParseError.expected(message: "Expected name after '.' in module path", line: currentToken().line)
                }
            }
            
            var alias: String? = nil
            if currentToken().type == .as {
                advance()
                guard case .name(let aliasName) = currentToken().type else {
                    throw ParseError.expected(message: "Expected alias name after 'as'", line: currentToken().line)
                }
                alias = aliasName
                advance()
            }
            
            names.append(Alias(name: name, asName: alias))
        }
        
        consumeNewlineOrSemicolon()
        
        return .importStmt(Import(
            names: names,
            lineno: importToken.line,
            colOffset: importToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseFromImport() throws -> Statement {
        let fromToken = currentToken()
        advance() // consume 'from'
        
        // Parse module name (can include dots for relative imports)
        var moduleName = ""
        var level = 0
        
        // Handle relative imports (.module or ..module)
        while currentToken().type == .dot {
            level += 1
            advance()
        }
        
        // Parse module name parts (if present - can be just dots for current package)
        if case .name(let name) = currentToken().type {
            moduleName = name
            advance()
            
            // Handle dotted module names (e.g., typing.List)
            while currentToken().type == .dot {
                moduleName += "."
                advance()
                
                if case .name(let part) = currentToken().type {
                    moduleName += part
                    advance()
                } else {
                    break
                }
            }
        }
        
        try consume(.import, "Expected 'import' after module name")
        
        var names: [Alias] = []
        
        // Check for multi-line imports with parentheses
        let hasParens = currentToken().type == .leftparen
        if hasParens {
            advance() // consume '('
            // Skip any newlines after opening paren
            while currentToken().type == .newline {
                advance()
            }
        }
        
        // Check for 'import *'
        if currentToken().type == .star {
            advance()
            names.append(Alias(name: "*", asName: nil))
        } else {
            // Parse first import name
            guard case .name(let firstName) = currentToken().type else {
                throw ParseError.expected(message: "Expected name after 'import'", line: currentToken().line)
            }
            advance()
            
            var asName: String? = nil
            if currentToken().type == .as {
                advance()
                guard case .name(let alias) = currentToken().type else {
                    throw ParseError.expected(message: "Expected alias after 'as'", line: currentToken().line)
                }
                asName = alias
                advance()
            }
            
            names.append(Alias(name: firstName, asName: asName))
            
            // Parse additional imports separated by commas
            while currentToken().type == .comma {
                advance() // consume ','
                
                // Skip newlines in multi-line imports
                if hasParens {
                    while currentToken().type == .newline {
                        advance()
                    }
                }
                
                // Check for trailing comma (especially in multi-line imports)
                if hasParens && currentToken().type == .rightparen {
                    break
                }
                
                guard case .name(let name) = currentToken().type else {
                    throw ParseError.expected(message: "Expected import name", line: currentToken().line)
                }
                advance()
                
                var alias: String? = nil
                if currentToken().type == .as {
                    advance()
                    guard case .name(let aliasName) = currentToken().type else {
                        throw ParseError.expected(message: "Expected alias after 'as'", line: currentToken().line)
                    }
                    alias = aliasName
                    advance()
                }
                
                names.append(Alias(name: name, asName: alias))
            }
        }
        
        // Handle closing parenthesis for multi-line imports
        if hasParens {
            // Skip any newlines before closing paren
            while currentToken().type == .newline {
                advance()
            }
            try consume(.rightparen, "Expected ')' to close multi-line import")
        }
        
        consumeNewlineOrSemicolon()
        
        return .importFrom(ImportFrom(
            module: moduleName.isEmpty ? nil : moduleName,
            names: names,
            level: level,
            lineno: fromToken.line,
            colOffset: fromToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseArguments() throws -> Arguments {
        var posonlyArgs: [Arg] = []
        var args: [Arg] = []
        var vararg: Arg? = nil
        var kwonlyArgs: [Arg] = []
        var kwDefaults: [Expression?] = []
        var kwarg: Arg? = nil
        var defaults: [Expression] = []
        
        var seenStar = false
        
        // Parse parameters
        while currentToken().type != .rightparen && !isAtEnd() {
            // Skip newlines in multi-line parameter lists
            while currentToken().type == .newline {
                advance()
            }
            
            // Check if we've reached the closing paren after newlines
            if currentToken().type == .rightparen {
                break
            }
            // Check for /  (positional-only marker)
            if currentToken().type == .slash {
                advance()
                posonlyArgs = args
                args = []
                if currentToken().type == .comma {
                    advance()
                }
                continue
            }
            
            // Check for * (keyword-only marker) or *args
            if currentToken().type == .star {
                advance()
                seenStar = true
                
                if case .name(let paramName) = currentToken().type {
                    // *args
                    advance()
                    
                    // Check for type annotation
                    var annotation: Expression? = nil
                    if currentToken().type == .colon {
                        advance()
                        annotation = try parseExpression()
                    }
                    
                    vararg = Arg(arg: paramName, annotation: annotation, typeComment: nil)
                }
                
                if currentToken().type == .comma {
                    advance()
                }
                continue
            }
            
            // Check for **kwargs
            if currentToken().type == .doublestar {
                advance()
                guard case .name(let paramName) = currentToken().type else {
                    throw ParseError.expected(message: "Expected parameter name after '**'", line: currentToken().line)
                }
                advance()
                
                // Check for type annotation
                var annotation: Expression? = nil
                if currentToken().type == .colon {
                    advance()
                    annotation = try parseExpression()
                }
                
                kwarg = Arg(arg: paramName, annotation: annotation, typeComment: nil)
                
                if currentToken().type == .comma {
                    advance()
                }
                continue
            }
            
            // Regular parameter
            guard case .name(let paramName) = currentToken().type else {
                break
            }
            advance()
            
            // Check for type annotation
            var annotation: Expression? = nil
            if currentToken().type == .colon {
                advance()
                annotation = try parseExpression()
            }
            
            let param = Arg(arg: paramName, annotation: annotation, typeComment: nil)
            
            // Check for default value
            if currentToken().type == .assign {
                advance()
                let defaultValue = try parseExpression()
                
                if seenStar {
                    kwonlyArgs.append(param)
                    kwDefaults.append(defaultValue)
                } else {
                    args.append(param)
                    defaults.append(defaultValue)
                }
            } else {
                if seenStar {
                    kwonlyArgs.append(param)
                    kwDefaults.append(nil)
                } else {
                    args.append(param)
                }
            }
            
            if currentToken().type == .comma {
                advance()
                // Skip newlines after commas in multi-line parameter lists
                while currentToken().type == .newline {
                    advance()
                }
            } else {
                break
            }
        }
        
        return Arguments(
            posonlyArgs: posonlyArgs,
            args: args,
            vararg: vararg,
            kwonlyArgs: kwonlyArgs,
            kwDefaults: kwDefaults,
            kwarg: kwarg,
            defaults: defaults
        )
    }
    
    private func parseBlock() throws -> [Statement] {
        // Skip inline comments before the newline (e.g., def foo():  # comment)
        while case .comment = currentToken().type {
            advance()
        }
        
        try consume(.newline, "Expected newline before block")
        
        // Skip comments and blank lines between newline and indent
        while true {
            if case .comment = currentToken().type {
                advance()
                // Skip newline after comment
                if currentToken().type == .newline {
                    advance()
                }
            } else if currentToken().type == .newline {
                // Skip blank lines
                advance()
            } else {
                // Not a comment or blank line, must be indent
                break
            }
        }
        
        try consume(.indent, "Expected indent")
        
        var statements: [Statement] = []
        
        while currentToken().type != .dedent && !isAtEnd() {
            if currentToken().type == .newline {
                advance()
                continue
            }
            
            // Skip comments
            if case .comment = currentToken().type {
                advance()
                continue
            }
            
            if case .typeComment = currentToken().type {
                advance()
                continue
            }
            
            statements.append(try parseStatement())
        }
        
        try consume(.dedent, "Expected dedent")
        
        return statements
    }
    
    private func parseExpression() throws -> Expression {
        // Try lambda first
        if currentToken().type == .lambda {
            return try parseLambdaExpression()
        }
        
        // FAST PATH: Simple expressions without operators (60-70% of real-world cases)
        // Only safe when next token is DEFINITELY a terminator (not newline - could be implicit continuation)
        let token = currentToken()
        let nextPos = position + 1
        
        if nextPos < tokens.count {
            let nextToken = tokens[nextPos]
            
            // Only use fast path for SAFE terminators
            // NOTE: newline IS safe - tokenizer suppresses it inside brackets (line 88 of UTF8Tokenizer)
            // So if we see a newline token, we're definitely at statement level
            let isSafeTerminator: Bool
            switch nextToken.type {
            case .newline, .semicolon, .rightparen, .rightbrace, .rightbracket, .comma, .endmarker:
                isSafeTerminator = true
            default:
                isSafeTerminator = false
            }
            
            if isSafeTerminator {
                // Fast path for simple name
                if case .name(let name) = token.type {
                    advance()
                    return .name(Name(
                        id: name,
                        ctx: .load,
                        lineno: token.line,
                        colOffset: token.column,
                        endLineno: token.endLine,
                        endColOffset: token.endColumn
                    ))
                }
                
                // Fast path for simple literals
                switch token.type {
                case .number(let num):
                    advance()
                    let value: ConstantValue
                    if num.contains(".") || num.contains("e") || num.contains("E") {
                        value = .float(Double(num.filter { $0 != "_" }) ?? 0.0)
                    } else {
                        value = .int(Int(num.filter { $0 != "_" }) ?? 0)
                    }
                    return .constant(Constant(
                        value: value,
                        kind: nil,
                        lineno: token.line,
                        colOffset: token.column,
                        endLineno: token.endLine,
                        endColOffset: token.endColumn
                    ))
                    
                case .string(let str):
                    advance()
                    return .constant(Constant(
                        value: .string(stripQuotes(from: str)),
                        kind: nil,
                        lineno: token.line,
                        colOffset: token.column,
                        endLineno: token.endLine,
                        endColOffset: token.endColumn
                    ))
                    
                case .true:
                    advance()
                    return .constant(Constant(
                        value: .bool(true),
                        kind: nil,
                        lineno: token.line,
                        colOffset: token.column,
                        endLineno: token.endLine,
                        endColOffset: token.endColumn
                    ))
                    
                case .false:
                    advance()
                    return .constant(Constant(
                        value: .bool(false),
                        kind: nil,
                        lineno: token.line,
                        colOffset: token.column,
                        endLineno: token.endLine,
                        endColOffset: token.endColumn
                    ))
                    
                case .none:
                    advance()
                    return .constant(Constant(
                        value: .none,
                        kind: nil,
                        lineno: token.line,
                        colOffset: token.column,
                        endLineno: token.endLine,
                        endColOffset: token.endColumn
                    ))
                    
                default:
                    break
                }
            }
        }
        
        // Otherwise parse disjunction (or/and/not/comparison chain)
        let expr = try parseOrExpression()
        
        // Check for if-expression (ternary): x if condition else y
        if currentToken().type == .if {
            advance() // consume 'if'
            let test = try parseOrExpression()  // Condition
            try consume(.else, "Expected 'else' in if-expression")
            let orElse = try parseExpression()  // Else part (recursive for nesting)
            
            return .ifExp(IfExp(
                test: test,
                body: expr,
                orElse: orElse,
                lineno: currentToken().line,
                colOffset: currentToken().column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return expr
    }
    
    // Parse expression that may be starred (for assignment targets and unpacking)
    private func parseStarExpression() throws -> Expression {
        if currentToken().type == .star {
            let token = currentToken()
            advance() // consume '*'
            let value = try parseOrExpression()
            return .starred(Starred(
                value: value,
                ctx: .load,
                lineno: token.line,
                colOffset: token.column,
                endLineno: token.endLine,
                endColOffset: token.endColumn
            ))
        }
        return try parseOrExpression()
    }
    
    // Operator precedence parsing (from lowest to highest)
    
    private func parseOrExpression() throws -> Expression {
        var left = try parseAndExpression()
        
        // Skip comments before checking for 'or' operator
        skipComments()
        
        while currentToken().type == .or {
            let token = currentToken()
            advance()
            skipComments() // Skip comments after 'or' operator
            let right = try parseAndExpression()
            left = .boolOp(BoolOp(
                op: .or,
                values: [left, right],
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
            // Skip comments before checking for next 'or'
            skipComments()
        }
        
        return left
    }
    
    private func parseAndExpression() throws -> Expression {
        var left = try parseNotExpression()
        
        // Skip comments before checking for 'and' operator
        skipComments()
        
        while currentToken().type == .and {
            let token = currentToken()
            advance()
            skipComments() // Skip comments after 'and' operator
            let right = try parseNotExpression()
            left = .boolOp(BoolOp(
                op: .and,
                values: [left, right],
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
            // Skip comments before checking for next 'and'
            skipComments()
        }
        
        return left
    }
    
    private func parseNotExpression() throws -> Expression {
        if currentToken().type == .not {
            // Check if this is 'not in' (comparison operator) vs 'not' (unary operator)
            // Peek ahead to see if the next non-comment/non-newline token is 'in'
            var peekPos = position + 1
            while peekPos < tokens.count {
                let peekToken = tokens[peekPos]
                if case .comment = peekToken.type {
                    peekPos += 1
                    continue
                }
                if peekToken.type == .newline {
                    peekPos += 1
                    continue
                }
                // Found first non-trivial token
                if peekToken.type == .in {
                    // This is 'not in' - don't consume 'not', let comparison handle it
                    return try parseWalrusExpression()
                }
                break
            }
            
            // This is unary 'not'
            let token = currentToken()
            advance()
            skipComments() // Skip comments after 'not' operator
            let operand = try parseNotExpression()
            return .unaryOp(UnaryOp(
                op: .not,
                operand: operand,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        return try parseWalrusExpression()
    }
    
    private func parseWalrusExpression() throws -> Expression {
        let left = try parseLambdaExpression()
        
        // Check for walrus operator :=
        if currentToken().type == .colonequal {
            let token = currentToken()
            advance()
            let value = try parseExpression()
            
            return .namedExpr(NamedExpr(
                target: left,
                value: value,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func parseLambdaExpression() throws -> Expression {
        if currentToken().type == .lambda {
            let token = currentToken()
            advance()
            
            // Parse lambda arguments (similar to function arguments but inline)
            var args: [Arg] = []
            var defaults: [Expression] = []
            var vararg: Arg? = nil
            var kwonlyArgs: [Arg] = []
            var kwDefaults: [Expression?] = []
            var kwarg: Arg? = nil
            
            if currentToken().type != .colon {
                // Parse parameter list
                while currentToken().type != .colon && !isAtEnd() {
                    // Check for *args
                    if currentToken().type == .star {
                        advance()
                        if case .name(let name) = currentToken().type {
                            vararg = Arg(arg: name, annotation: nil, typeComment: nil)
                            advance()
                            
                            // After *args, we have keyword-only arguments
                            if currentToken().type == .comma {
                                advance()
                                // Parse keyword-only args
                                while currentToken().type != .colon && !isAtEnd() {
                                    if currentToken().type == .doublestar {
                                        advance()
                                        if case .name(let name) = currentToken().type {
                                            kwarg = Arg(arg: name, annotation: nil, typeComment: nil)
                                            advance()
                                        }
                                        break
                                    }
                                    
                                    if case .name(let name) = currentToken().type {
                                        let arg = Arg(arg: name, annotation: nil, typeComment: nil)
                                        advance()
                                        
                                        // Check for default value
                                        if currentToken().type == .assign {
                                            advance()
                                            let defaultVal = try parseBitwiseOrExpression()
                                            kwonlyArgs.append(arg)
                                            kwDefaults.append(defaultVal)
                                        } else {
                                            kwonlyArgs.append(arg)
                                            kwDefaults.append(nil)
                                        }
                                        
                                        if currentToken().type == .comma {
                                            advance()
                                        }
                                    }
                                }
                            }
                        } else {
                            // Bare * means keyword-only args follow
                            if currentToken().type == .comma {
                                advance()
                            }
                        }
                        break
                    }
                    
                    // Check for **kwargs
                    if currentToken().type == .doublestar {
                        advance()
                        if case .name(let name) = currentToken().type {
                            kwarg = Arg(arg: name, annotation: nil, typeComment: nil)
                            advance()
                        }
                        break
                    }
                    
                    // Regular parameter
                    if case .name(let param) = currentToken().type {
                        let arg = Arg(arg: param, annotation: nil, typeComment: nil)
                        advance()
                        
                        // Check for default value
                        if currentToken().type == .assign {
                            advance()
                            let defaultVal = try parseBitwiseOrExpression()
                            args.append(arg)
                            defaults.append(defaultVal)
                        } else {
                            args.append(arg)
                        }
                        
                        if currentToken().type == .comma {
                            advance()
                        } else {
                            break
                        }
                    } else {
                        break
                    }
                }
            }
            
            try consume(.colon, "Expected ':' after lambda parameters")
            let body = try parseExpression()
            
            // Convert params to Arguments structure
            let arguments = Arguments(
                posonlyArgs: [],
                args: args,
                vararg: vararg,
                kwonlyArgs: kwonlyArgs,
                kwDefaults: kwDefaults,
                kwarg: kwarg,
                defaults: defaults
            )
            
            return .lambda(Lambda(
                args: arguments,
                body: body,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        // This should never be reached since parseExpression checks for lambda first
        return try parseComparisonExpression()
    }
    
    private func parseComparisonExpression() throws -> Expression {
        let left = try parseBitwiseOrExpression()
        
        var ops: [CmpOp] = []
        var comparators: [Expression] = []
        
        while isComparisonOperator() {
            ops.append(try parseComparisonOperator())
            comparators.append(try parseBitwiseOrExpression())
        }
        
        if !ops.isEmpty {
            let token = currentToken()
            return .compare(Compare(
                left: left,
                ops: ops,
                comparators: comparators,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func isComparisonOperator() -> Bool {
        switch currentToken().type {
        case .equal, .notequal, .less, .lessequal, .greater, .greaterequal, .in, .is, .not:
            return true
        default:
            return false
        }
    }
    
    private func parseComparisonOperator() throws -> CmpOp {
        let type = currentToken().type
        advance()
        
        switch type {
        case .equal:
            return .eq
        case .notequal:
            return .notEq
        case .less:
            return .lt
        case .lessequal:
            return .ltE
        case .greater:
            return .gt
        case .greaterequal:
            return .gtE
        case .is:
            if currentToken().type == .not {
                advance()
                return .isNot
            }
            return .is
        case .not:
            if currentToken().type == .in {
                advance()
                return .notIn
            }
            throw ParseError.expected(message: "Expected 'in' after 'not'", line: currentToken().line)
        case .in:
            return .in
        default:
            throw ParseError.expected(message: "Expected comparison operator", line: currentToken().line)
        }
    }
    
    private func parseBitwiseOrExpression() throws -> Expression {
        var left = try parseBitwiseXorExpression()
        
        while currentToken().type == .vbar {
            let token = currentToken()
            advance()
            let right = try parseBitwiseXorExpression()
            left = .binOp(BinOp(
                left: left,
                op: .bitOr,
                right: right,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func parseBitwiseXorExpression() throws -> Expression {
        var left = try parseBitwiseAndExpression()
        
        while currentToken().type == .circumflex {
            let token = currentToken()
            advance()
            let right = try parseBitwiseAndExpression()
            left = .binOp(BinOp(
                left: left,
                op: .bitXor,
                right: right,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func parseBitwiseAndExpression() throws -> Expression {
        var left = try parseShiftExpression()
        
        while currentToken().type == .amper {
            let token = currentToken()
            advance()
            let right = try parseShiftExpression()
            left = .binOp(BinOp(
                left: left,
                op: .bitAnd,
                right: right,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func parseShiftExpression() throws -> Expression {
        var left = try parseArithmeticExpression()
        
        while currentToken().type == .leftshift || currentToken().type == .rightshift {
            let token = currentToken()
            let op: Operator = token.type == .leftshift ? .lShift : .rShift
            advance()
            let right = try parseArithmeticExpression()
            left = .binOp(BinOp(
                left: left,
                op: op,
                right: right,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func parseArithmeticExpression() throws -> Expression {
        var left = try parseTermExpression()
        
        while currentToken().type == .plus || currentToken().type == .minus {
            let token = currentToken()
            let op: Operator = token.type == .plus ? .add : .sub
            advance()
            let right = try parseTermExpression()
            left = .binOp(BinOp(
                left: left,
                op: op,
                right: right,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func parseTermExpression() throws -> Expression {
        var left = try parseFactorExpression()
        
        while [.star, .slash, .doubleslash, .percent, .at].contains(currentToken().type) {
            let token = currentToken()
            let op: Operator
            switch token.type {
            case .star: op = .mult
            case .slash: op = .div
            case .doubleslash: op = .floorDiv
            case .percent: op = .mod
            case .at: op = .matMult
            default: throw ParseError.unexpectedToken(token: token)
            }
            advance()
            let right = try parseFactorExpression()
            left = .binOp(BinOp(
                left: left,
                op: op,
                right: right,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func parseFactorExpression() throws -> Expression {
        // Unary operators: +, -, ~
        if [.plus, .minus, .tilde].contains(currentToken().type) {
            let token = currentToken()
            let op: UnaryOperator
            switch token.type {
            case .plus: op = .uAdd
            case .minus: op = .uSub
            case .tilde: op = .invert
            default: throw ParseError.unexpectedToken(token: token)
            }
            advance()
            let operand = try parseFactorExpression()
            return .unaryOp(UnaryOp(
                op: op,
                operand: operand,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return try parsePowerExpression()
    }
    
    private func parsePowerExpression() throws -> Expression {
        var left = try parsePostfixExpression()
        
        if currentToken().type == .doublestar {
            let token = currentToken()
            advance()
            let right = try parseFactorExpression() // Right associative
            left = .binOp(BinOp(
                left: left,
                op: .pow,
                right: right,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func parsePostfixExpression() throws -> Expression {
        var expr = try parsePrimary()
        
        while true {
            let token = currentToken()
            
            switch token.type {
            case .leftparen:
                // Function call
                advance()
                let args = try parseCallArguments()
                try consume(.rightparen, "Expected ')' after function arguments")
                expr = .call(Call(
                    fun: expr,
                    args: args.args,
                    keywords: args.keywords,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
                
            case .leftbracket:
                // Subscript or slice
                advance()
                let slice = try parseSlice()
                try consume(.rightbracket, "Expected ']' after subscript")
                expr = .subscriptExpr(Subscript(
                    value: expr,
                    slice: slice,
                    ctx: .load,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
                
            case .dot:
                // Attribute access
                advance()
                guard case .name(let attr) = currentToken().type else {
                    throw ParseError.expected(message: "Expected attribute name after '.'", line: currentToken().line)
                }
                advance()
                expr = .attribute(Attribute(
                    value: expr,
                    attr: attr,
                    ctx: .load,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
                
            default:
                return expr
            }
        }
    }
    
    private func parseCallArguments() throws -> (args: [Expression], keywords: [Keyword]) {
        var args: [Expression] = []
        var keywords: [Keyword] = []
        
        while currentToken().type != .rightparen && !isAtEnd() {
            // Skip newlines in multi-line function calls (implicit line joining)
            while currentToken().type == .newline {
                advance()
            }
            
            // Check if we've reached the closing paren after skipping newlines
            if currentToken().type == .rightparen {
                break
            }
            
            // Check for **kwargs (dictionary unpacking)
            if currentToken().type == .doublestar {
                advance() // consume '**'
                let value = try parseExpression()
                // Use None as arg name to indicate **kwargs
                keywords.append(Keyword(arg: nil, value: value))
                
                // Skip newlines after **kwargs (implicit line joining)
                while currentToken().type == .newline {
                    advance()
                }
                
                if currentToken().type == .comma {
                    advance()
                    // Skip newlines after comma
                    while currentToken().type == .newline {
                        advance()
                    }
                }
                continue
            }
            
            // Check for *args (iterable unpacking)
            if currentToken().type == .star {
                let starPos = currentToken()
                advance() // consume '*'
                let value = try parseExpression()
                let starred = Expression.starred(Starred(
                    value: value,
                    ctx: .load,
                    lineno: starPos.line,
                    colOffset: starPos.column,
                    endLineno: starPos.endLine,
                    endColOffset: starPos.endColumn
                ))
                args.append(starred)
                
                // Skip newlines after starred expression (implicit line joining)
                while currentToken().type == .newline {
                    advance()
                }
                
                if currentToken().type == .comma {
                    advance()
                    // Skip newlines after comma
                    while currentToken().type == .newline {
                        advance()
                    }
                }
                continue
            }
            
            // Check for keyword argument
            if case .name(let name) = currentToken().type {
                let nextPos = position + 1
                if nextPos < tokens.count && tokens[nextPos].type == .assign {
                    // Keyword argument
                    advance() // consume name
                    advance() // consume '='
                    let value = try parseExpression()
                    keywords.append(Keyword(arg: name, value: value))
                    
                    // Skip newlines after keyword argument (implicit line joining)
                    while currentToken().type == .newline {
                        advance()
                    }
                    
                    if currentToken().type == .comma {
                        advance()
                        // Skip newlines after comma
                        while currentToken().type == .newline {
                            advance()
                        }
                    }
                    continue
                }
            }
            
            // Positional argument
            let arg = try parseExpression()
            
            // Check for generator expression (only valid as sole argument or first argument)
            // e.g., any(x > 0 for x in items) or func(x for x in items, other_arg)
            if currentToken().type == .for || currentToken().type == .async {
                let generators = try parseComprehensionGenerators()
                let genexp = Expression.generatorExp(GeneratorExp(
                    elt: arg,
                    generators: generators,
                    lineno: currentToken().line,
                    colOffset: currentToken().column,
                    endLineno: nil,
                    endColOffset: nil
                ))
                args.append(genexp)
                
                // Skip newlines after generator expression (implicit line joining)
                while currentToken().type == .newline {
                    advance()
                }
                
                if currentToken().type == .comma {
                    advance()
                    // Skip newlines after comma
                    while currentToken().type == .newline {
                        advance()
                    }
                }
            } else {
                args.append(arg)
                
                // Skip newlines after positional argument (implicit line joining)
                while currentToken().type == .newline {
                    advance()
                }
                
                if currentToken().type == .comma {
                    advance()
                    // Skip newlines after comma
                    while currentToken().type == .newline {
                        advance()
                    }
                } else if currentToken().type != .rightparen {
                    throw ParseError.expected(message: "Expected ',' or ')' in function call", line: currentToken().line)
                }
            }
        }
        
        return (args, keywords)
    }
    
    private func parseSlice() throws -> Expression {
        // Check for empty subscript
        if currentToken().type == .rightbracket {
            return .constant(Constant(
                value: .none,
                kind: nil,
                lineno: currentToken().line,
                colOffset: currentToken().column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        // Parse first element (could be start of slice or single expression)
        let start = currentToken().type != .colon
            ? try parseBitwiseOrExpression()
            : nil
        
        if currentToken().type == .colon {
            // Slice expression (e.g., [start:stop:step])
            advance()
            let stop = currentToken().type != .colon && currentToken().type != .rightbracket
                ? try parseBitwiseOrExpression()
                : nil
            
            var step: Expression? = nil
            if currentToken().type == .colon {
                advance()
                if currentToken().type != .rightbracket {
                    step = try parseBitwiseOrExpression()
                }
            }
            
            return .slice(Slice(
                lower: start,
                upper: stop,
                step: step,
                lineno: currentToken().line,
                colOffset: currentToken().column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        // Check for tuple subscript (e.g., dict[str, int])
        if currentToken().type == .comma {
            var elements = [start!]
            
            while currentToken().type == .comma {
                advance()
                if currentToken().type == .rightbracket {
                    break
                }
                elements.append(try parseBitwiseOrExpression())
            }
            
            let token = currentToken()
            return .tuple(Tuple(
                elts: elements,
                ctx: .load,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        // Simple subscript
        return start ?? .constant(Constant(
            value: .none,
            kind: nil,
            lineno: currentToken().line,
            colOffset: currentToken().column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parsePrimary() throws -> Expression {
        let token = currentToken()
        
        // Await expression
        if token.type == .await {
            advance()
            let value = try parsePrimary()
            return .await(Await(
                value: value,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        switch token.type {
        case .name(let name):
            // Check for f-string: f"..." or f'...'
            let nextPos = position + 1
            if name == "f", nextPos < tokens.count, case .string = tokens[nextPos].type {
                // Parse first f-string
                var fstring = try parseFString(startToken: token)
                
                // Handle implicit f-string concatenation: f"str1" f"str2"
                while true {
                    // Check if next token is another f-string
                    if case .name(let nextName) = currentToken().type, nextName == "f" {
                        let peekPos = position + 1
                        if peekPos < tokens.count, case .string = tokens[peekPos].type {
                            // Parse and concatenate next f-string
                            let nextFString = try parseFString(startToken: currentToken())
                            
                            // Concatenate the f-strings by merging their values
                            if case .joinedStr(let joined1) = fstring,
                               case .joinedStr(let joined2) = nextFString {
                                // Merge the values arrays
                                fstring = .joinedStr(JoinedStr(
                                    values: joined1.values + joined2.values,
                                    lineno: joined1.lineno,
                                    colOffset: joined1.colOffset,
                                    endLineno: nil,
                                    endColOffset: nil
                                ))
                            } else {
                                // If one isn't a joinedStr, just use the second one
                                fstring = nextFString
                            }
                        } else {
                            break
                        }
                    } else if case .string(let nextStr) = currentToken().type {
                        // Handle mixed concatenation: f"..." "regular"
                        advance()
                        let regularStr = stripQuotes(from: nextStr)
                        
                        if case .joinedStr(let joined) = fstring {
                            // Append regular string as a Constant to the JoinedStr
                            let constantExpr = Expression.constant(Constant(
                                value: .string(regularStr),
                                kind: nil,
                                lineno: joined.lineno,
                                colOffset: joined.colOffset,
                                endLineno: nil,
                                endColOffset: nil
                            ))
                            fstring = .joinedStr(JoinedStr(
                                values: joined.values + [constantExpr],
                                lineno: joined.lineno,
                                colOffset: joined.colOffset,
                                endLineno: nil,
                                endColOffset: nil
                            ))
                        }
                    } else {
                        break
                    }
                }
                
                return fstring
            }
            
            advance()
            return .name(Name(
                id: name,
                ctx: .load,
                lineno: token.line,
                colOffset: token.column,
                endLineno: token.endLine,
                endColOffset: token.endColumn
            ))
            
        case .number(let num):
            advance()
            
            // Parse different number formats
            let value: ConstantValue
            
            if num.hasSuffix("j") || num.hasSuffix("J") {
                // Complex number
                let realPart = num.dropLast()
                if let floatVal = Double(realPart.filter { $0 != "_" }) {
                    value = .complex(0.0, floatVal)
                } else {
                    value = .complex(0.0, 0.0)
                }
            } else if num.hasPrefix("0x") || num.hasPrefix("0X") {
                // Hexadecimal
                let hex = String(num.dropFirst(2)).filter { $0 != "_" }
                value = .int(Int(hex, radix: 16) ?? 0)
            } else if num.hasPrefix("0o") || num.hasPrefix("0O") {
                // Octal
                let oct = String(num.dropFirst(2)).filter { $0 != "_" }
                value = .int(Int(oct, radix: 8) ?? 0)
            } else if num.hasPrefix("0b") || num.hasPrefix("0B") {
                // Binary
                let bin = String(num.dropFirst(2)).filter { $0 != "_" }
                value = .int(Int(bin, radix: 2) ?? 0)
            } else if num.contains(".") || num.contains("e") || num.contains("E") {
                // Float
                value = .float(Double(num.filter { $0 != "_" }) ?? 0.0)
            } else {
                // Integer
                value = .int(Int(num.filter { $0 != "_" }) ?? 0)
            }
            
            return .constant(Constant(
                value: value,
                kind: nil,
                lineno: token.line,
                colOffset: token.column,
                endLineno: token.endLine,
                endColOffset: token.endColumn
            ))
            
        case .string(let str):
            advance()
            // Handle implicit string concatenation: "str1" "str2" -> "str1str2"
            var concatenated = stripQuotes(from: str)
            
            // Keep concatenating adjacent string literals
            while case .string(let nextStr) = currentToken().type {
                advance()
                concatenated += stripQuotes(from: nextStr)
            }
            
            return .constant(Constant(
                value: .string(concatenated),
                kind: nil,
                lineno: token.line,
                colOffset: token.column,
                endLineno: token.endLine,
                endColOffset: token.endColumn
            ))
            
        case .true:
            advance()
            return .constant(Constant(
                value: .bool(true),
                kind: nil,
                lineno: token.line,
                colOffset: token.column,
                endLineno: token.endLine,
                endColOffset: token.endColumn
            ))
            
        case .false:
            advance()
            return .constant(Constant(
                value: .bool(false),
                kind: nil,
                lineno: token.line,
                colOffset: token.column,
                endLineno: token.endLine,
                endColOffset: token.endColumn
            ))
            
        case .none:
            advance()
            return .constant(Constant(
                value: .none,
                kind: nil,
                lineno: token.line,
                colOffset: token.column,
                endLineno: token.endLine,
                endColOffset: token.endColumn
            ))
            
        case .ellipsis:
            advance()
            return .constant(Constant(
                value: .ellipsis,
                kind: nil,
                lineno: token.line,
                colOffset: token.column,
                endLineno: token.endLine,
                endColOffset: token.endColumn
            ))
            
        case .leftparen:
            // Tuple, parenthesized expression, or generator expression
            advance()
            
            // Skip newlines after opening paren (implicit line joining)
            while currentToken().type == .newline {
                advance()
            }
            
            if currentToken().type == .rightparen {
                // Empty tuple
                advance()
                return .tuple(Tuple(
                    elts: [],
                    ctx: .load,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            // For tuples and generator expressions, we need to use parseExpression()
            // to handle conditional expressions like: (x if cond else y, ...)
            // But we also need to handle starred expressions: (*items, x)
            let first: Expression
            if currentToken().type == .star {
                // Starred expression in a tuple: (*items, ...)
                first = try parseStarExpression()
            } else {
                // Could be regular element or generator expression element
                // Use parseExpression() to support: (x if cond else y for ...)
                first = try parseExpression()
            }
            
            // Skip newlines after first element (implicit line joining)
            while currentToken().type == .newline {
                advance()
            }
            
            // Check for generator expression (including async)
            if currentToken().type == .for || currentToken().type == .async {
                let generators = try parseComprehensionGenerators()
                try consume(.rightparen, "Expected ')' after generator expression")
                return .generatorExp(GeneratorExp(
                    elt: first,
                    generators: generators,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            if currentToken().type == .comma {
                // Tuple
                var elts = [first]
                while currentToken().type == .comma {
                    advance()
                    // Skip comments and newlines after comma (implicit line joining)
                    while case .comment = currentToken().type {
                        advance()
                    }
                    while currentToken().type == .newline {
                        advance()
                    }
                    if currentToken().type == .rightparen {
                        break
                    }
                    // Parse tuple elements - support both starred and conditional expressions
                    let element: Expression
                    if currentToken().type == .star {
                        // Starred expression: (1, *items, 2)
                        element = try parseStarExpression()
                    } else {
                        // Regular or conditional expression: (a, b if c else d, e)
                        element = try parseExpression()
                    }
                    elts.append(element)
                    // Skip comments and newlines after element (implicit line joining)
                    while case .comment = currentToken().type {
                        advance()
                    }
                    while currentToken().type == .newline {
                        advance()
                    }
                }
                try consume(.rightparen, "Expected ')' after tuple")
                return .tuple(Tuple(
                    elts: elts,
                    ctx: .load,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            try consume(.rightparen, "Expected ')' after expression")
            return first
            
        case .leftbracket:
            // List or list comprehension
            advance()
            
            if currentToken().type == .rightbracket {
                // Empty list
                try consume(.rightbracket, "Expected ']'")
                return .list(List(
                    elts: [],
                    ctx: .load,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            // For list comprehensions, we need to use parseExpression() to handle
            // conditional expressions like: [x if cond else y for x in items]
            // But we also need to handle starred expressions in regular lists: [*items, x]
            // Strategy: Try parseStarExpression first, but if we see 'for'/'async', 
            // we know it's a comprehension and the expression can include if-expressions
            
            let first: Expression
            if currentToken().type == .star {
                // Starred expression in a list: [*items, ...]
                first = try parseStarExpression()
            } else {
                // Could be regular element or comprehension element
                // Use parseExpression() to support: [x if cond else y for ...]
                first = try parseExpression()
            }
            
            // Check for list comprehension (including async comprehension)
            if currentToken().type == .for || currentToken().type == .async {
                let generators = try parseComprehensionGenerators()
                try consume(.rightbracket, "Expected ']' after list comprehension")
                return .listComp(ListComp(
                    elt: first,
                    generators: generators,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            // Regular list
            var elts = [first]
            while currentToken().type == .comma {
                advance()
                // Skip comments after comma
                while case .comment = currentToken().type {
                    advance()
                }
                if currentToken().type == .rightbracket {
                    break
                }
                // Parse list elements - support both starred and conditional expressions
                let element: Expression
                if currentToken().type == .star {
                    // Starred expression: [1, *items, 2]
                    element = try parseStarExpression()
                } else {
                    // Regular or conditional expression: [a, b if c else d, e]
                    element = try parseExpression()
                }
                elts.append(element)
                // Skip comments after element
                while case .comment = currentToken().type {
                    advance()
                }
            }
            
            try consume(.rightbracket, "Expected ']' after list")
            return .list(List(
                elts: elts,
                ctx: .load,
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
            
        case .leftbrace:
            // Dict, Set, Dict comprehension, or Set comprehension
            advance()
            
            if currentToken().type == .rightbrace {
                // Empty dict
                advance()
                return .dict(Dict(
                    keys: [],
                    values: [],
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            // Check for **dict unpacking at start
            if currentToken().type == .doublestar {
                advance() // consume **
                let unpackedDict = try parseExpression()
                
                var keys: [Expression?] = [nil] // nil key indicates unpacking
                var values: [Expression] = [unpackedDict]
                
                while currentToken().type == .comma {
                    advance()
                    if currentToken().type == .rightbrace {
                        break
                    }
                    
                    // Check for another **dict unpacking
                    if currentToken().type == .doublestar {
                        advance()
                        let nextUnpack = try parseExpression()
                        keys.append(nil)
                        values.append(nextUnpack)
                    } else {
                        // Regular key-value pair
                        let key = try parseExpression()
                        try consume(.colon, "Expected ':' after dict key")
                        let value = try parseExpression()
                        keys.append(key)
                        values.append(value)
                    }
                }
                
                try consume(.rightbrace, "Expected '}' after dict")
                return .dict(Dict(
                    keys: keys,
                    values: values,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            let first = try parseStarExpression()
            
            if currentToken().type == .colon {
                // Dict or dict comprehension
                advance()
                let firstValue = try parseExpression()
                
                // Check for dict comprehension (including async)
                if currentToken().type == .for || currentToken().type == .async {
                    let generators = try parseComprehensionGenerators()
                    try consume(.rightbrace, "Expected '}' after dict comprehension")
                    return .dictComp(DictComp(
                        key: first,
                        value: firstValue,
                        generators: generators,
                        lineno: token.line,
                        colOffset: token.column,
                        endLineno: nil,
                        endColOffset: nil
                    ))
                }
                
                // Regular dict
                var keys: [Expression?] = [first]
                var values = [firstValue]
                
                while currentToken().type == .comma {
                    advance()
                    if currentToken().type == .rightbrace {
                        break
                    }
                    
                    // Check for **dict unpacking
                    if currentToken().type == .doublestar {
                        advance()
                        let unpackedDict = try parseExpression()
                        keys.append(nil) // nil key indicates unpacking
                        values.append(unpackedDict)
                    } else {
                        let key = try parseExpression()
                        try consume(.colon, "Expected ':' after dict key")
                        let value = try parseExpression()
                        keys.append(key)
                        values.append(value)
                    }
                }
                
                try consume(.rightbrace, "Expected '}' after dict")
                return .dict(Dict(
                    keys: keys,
                    values: values,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            } else {
                // Set or set comprehension
                
                // Check for set comprehension (including async)
                if currentToken().type == .for || currentToken().type == .async {
                    let generators = try parseComprehensionGenerators()
                    try consume(.rightbrace, "Expected '}' after set comprehension")
                    return .setComp(SetComp(
                        elt: first,
                        generators: generators,
                        lineno: token.line,
                        colOffset: token.column,
                        endLineno: nil,
                        endColOffset: nil
                    ))
                }
                
                // Regular set
                var elts = [first]
                while currentToken().type == .comma {
                    advance()
                    if currentToken().type == .rightbrace {
                        break
                    }
                    elts.append(try parseStarExpression())
                }
                
                try consume(.rightbrace, "Expected '}' after set")
                return .set(Set(
                    elts: elts,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
        default:
            throw ParseError.unexpectedToken(token: token)
        }
    }
    
    // MARK: - Helper Methods
    
    @inline(__always)
    private func currentToken() -> Token {
        guard position < tokens.count else {
            return Token(type: .endmarker, value: "", line: 0, column: 0, endLine: 0, endColumn: 0)
        }
        return tokens[position]
    }
    
    @inline(__always)
    private func advance() {
        if position < tokens.count {
            position += 1
        }
    }
    
    @inline(__always)
    private func isAtEnd() -> Bool {
        return position >= tokens.count || currentToken().type == .endmarker
    }
    
    @inline(__always)
    private func skipComments() {
        while case .comment = currentToken().type {
            advance()
        }
    }
    
    private func consume(_ type: TokenType, _ message: String) throws {
        if currentToken().type == type {
            advance()
        } else {
            // Try to provide better error with code context
            let token = currentToken()
            let expectedChar = getExpectedChar(for: type)
            
            if !expectedChar.isEmpty && !sourceLines.isEmpty && token.line > 0 && token.line <= sourceLines.count {
                let context = sourceLines[token.line - 1]
                throw ParseError.expectedToken(expected: expectedChar, got: token, context: context)
            } else {
                throw ParseError.expected(message: message, line: token.line)
            }
        }
    }
    
    private func getExpectedChar(for type: TokenType) -> String {
        switch type {
        case .colon: return ":"
        case .leftparen: return "("
        case .rightparen: return ")"
        case .leftbracket: return "["
        case .rightbracket: return "]"
        case .leftbrace: return "{"
        case .rightbrace: return "}"
        case .comma: return ","
        case .semicolon: return ";"
        case .assign: return "="
        case .arrow: return "->"
        case .dot: return "."
        default: return ""
        }
    }
    
    private func isNewlineOrSemicolon() -> Bool {
        let type = currentToken().type
        return type == .newline || type == .semicolon || type == .endmarker
    }
    
    private func consumeNewlineOrSemicolon() {
        if isNewlineOrSemicolon() {
            advance()
        }
    }
    
    private func parseComprehensionGenerators() throws -> [Comprehension] {
        var generators: [Comprehension] = []
        
        while currentToken().type == .async || currentToken().type == .for {
            // Check for async comprehension
            let isAsync: Bool
            if currentToken().type == .async {
                isAsync = true
                advance() // consume 'async'
                try consume(.for, "Expected 'for' after 'async' in comprehension")
            } else {
                isAsync = false
                advance() // consume 'for'
            }
            
            let forToken = currentToken()
            
            // Parse target (can be a tuple like: k, v or with starred: *k, v)
            // We need to handle starred expressions in comprehensions
            var targetExprs: [Expression] = []
            
            // Parse first target element (may be starred)
            if currentToken().type == .star {
                targetExprs.append(try parseStarExpression())
            } else {
                targetExprs.append(try parseBitwiseOrExpression())
            }
            
            // Parse additional elements if comma-separated
            while currentToken().type == .comma {
                advance()
                // Check if we've hit 'in' (trailing comma case)
                if currentToken().type == .in {
                    break
                }
                // Parse next element (may also be starred)
                if currentToken().type == .star {
                    targetExprs.append(try parseStarExpression())
                } else {
                    targetExprs.append(try parseBitwiseOrExpression())
                }
            }
            
            let target: Expression
            if targetExprs.count == 1 {
                target = targetExprs[0]
            } else {
                target = .tuple(Tuple(
                    elts: targetExprs,
                    ctx: .store,
                    lineno: forToken.line,
                    colOffset: forToken.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
            }
            
            try consume(.in, "Expected 'in' in comprehension")
            let iter = try parseBitwiseOrExpression()
            
            var ifs: [Expression] = []
            // Skip comments before checking for 'if' clauses
            skipComments()
            while currentToken().type == .if {
                advance()
                skipComments() // Skip comments after 'if'
                ifs.append(try parseOrExpression())
                // Skip comments before checking for next 'if'
                skipComments()
            }
            
            generators.append(Comprehension(
                target: target,
                iter: iter,
                ifs: ifs,
                isAsync: isAsync
            ))
        }
        
        return generators
    }
    
    // Parse type parameters: [T], [T, U], [T: int], etc.
    private func parseTypeParameters() throws -> [TypeParam] {
        var params: [TypeParam] = []
        
        // Parse first parameter
        guard case .name(let name) = currentToken().type else {
            throw ParseError.expected(message: "Expected type parameter name", line: currentToken().line)
        }
        advance()
        
        // Check for bound (T: int)
        var bound: Expression? = nil
        if currentToken().type == .colon {
            advance() // consume ':'
            bound = try parseExpression()
        }
        
        params.append(.typeVar(TypeVar(name: name, bound: bound, defaultValue: nil)))
        
        // Parse remaining parameters
        while currentToken().type == .comma {
            advance() // consume ','
            
            guard case .name(let name) = currentToken().type else {
                throw ParseError.expected(message: "Expected type parameter name", line: currentToken().line)
            }
            advance()
            
            // Check for bound
            var bound: Expression? = nil
            if currentToken().type == .colon {
                advance() // consume ':'
                bound = try parseExpression()
            }
            
            params.append(.typeVar(TypeVar(name: name, bound: bound, defaultValue: nil)))
        }
        
        return params
    }
    
    // Parse f-string: f"text {expr} more text"
    private func parseFString(startToken: Token) throws -> Expression {
        advance() // consume 'f'
        
        guard case .string(let str) = currentToken().type else {
            throw ParseError.expected(message: "Expected string after 'f'", line: currentToken().line)
        }
        
        let stringToken = currentToken()
        advance() // consume string
        
        // Strip quotes from the string
        let content = stripQuotes(from: str)
        
        // Parse the f-string content to extract expressions
        var values: [Expression] = []
        var currentText = ""
        var i = content.startIndex
        
        while i < content.endIndex {
            let char = content[i]
            
            if char == "{" {
                // Check for escaped {{
                let nextIdx = content.index(after: i)
                if nextIdx < content.endIndex && content[nextIdx] == "{" {
                    currentText.append("{")
                    i = content.index(after: nextIdx)
                    continue
                }
                
                // Save any text before the expression
                if !currentText.isEmpty {
                    values.append(.constant(Constant(
                        value: .string(currentText),
                        kind: nil,
                        lineno: stringToken.line,
                        colOffset: stringToken.column,
                        endLineno: nil,
                        endColOffset: nil
                    )))
                    currentText = ""
                }
                
                // Find the closing }, handling conversion (!r, !s, !a) and format specs (:format)
                i = content.index(after: i)
                var exprStr = ""
                var braceDepth = 1
                var conversion = -1
                var formatSpec: Expression? = nil
                
                // Extract the expression part (before ! or :)
                while i < content.endIndex && braceDepth > 0 {
                    let c = content[i]
                    if c == "{" {
                        braceDepth += 1
                        exprStr.append(c)
                        i = content.index(after: i)
                    } else if c == "}" {
                        braceDepth -= 1
                        if braceDepth == 0 {
                            break
                        }
                        exprStr.append(c)
                        i = content.index(after: i)
                    } else if (c == "!" || c == ":") && braceDepth == 1 {
                        // Handle conversion or format spec
                        if c == "!" {
                            // Conversion specifier: !r, !s, or !a
                            i = content.index(after: i)
                            if i < content.endIndex {
                                let convChar = content[i]
                                switch convChar {
                                case "r": conversion = 114 // 'r'
                                case "s": conversion = 115 // 's'
                                case "a": conversion = 97  // 'a'
                                default: break
                                }
                                i = content.index(after: i)
                            }
                        } else if c == ":" {
                            // Format specifier
                            i = content.index(after: i)
                            var formatStr = ""
                            while i < content.endIndex {
                                let fc = content[i]
                                if fc == "}" {
                                    break
                                }
                                formatStr.append(fc)
                                i = content.index(after: i)
                            }
                            if !formatStr.isEmpty {
                                formatSpec = .joinedStr(JoinedStr(
                                    values: [.constant(Constant(
                                        value: .string(formatStr),
                                        kind: nil,
                                        lineno: stringToken.line,
                                        colOffset: stringToken.column,
                                        endLineno: nil,
                                        endColOffset: nil
                                    ))],
                                    lineno: stringToken.line,
                                    colOffset: stringToken.column,
                                    endLineno: nil,
                                    endColOffset: nil
                                ))
                            }
                        }
                        // After handling ! or :, look for closing }
                        while i < content.endIndex && content[i] != "}" {
                            i = content.index(after: i)
                        }
                        break
                    } else {
                        exprStr.append(c)
                        i = content.index(after: i)
                    }
                }
                
                // Parse the expression
                if !exprStr.isEmpty {
                    // Tokenize and parse the expression
                    let tokenizer = Tokenizer(source: exprStr)
                    let exprTokens = try tokenizer.tokenize()
                    let exprParser = Parser(tokens: exprTokens)
                    let expr = try exprParser.parseExpression()
                    
                    // Wrap in FormattedValue
                    values.append(.formattedValue(FormattedValue(
                        value: expr,
                        conversion: conversion,
                        formatSpec: formatSpec,
                        lineno: stringToken.line,
                        colOffset: stringToken.column,
                        endLineno: nil,
                        endColOffset: nil
                    )))
                }
                
                i = content.index(after: i) // skip closing }
                
            } else if char == "}" {
                // Check for escaped }}
                let nextIdx = content.index(after: i)
                if nextIdx < content.endIndex && content[nextIdx] == "}" {
                    currentText.append("}")
                    i = content.index(after: nextIdx)
                    continue
                }
                
                // Unmatched }
                currentText.append(char)
                i = content.index(after: i)
            } else {
                currentText.append(char)
                i = content.index(after: i)
            }
        }
        
        // Save any remaining text
        if !currentText.isEmpty {
            values.append(.constant(Constant(
                value: .string(currentText),
                kind: nil,
                lineno: stringToken.line,
                colOffset: stringToken.column,
                endLineno: nil,
                endColOffset: nil
            )))
        }
        
        // Return JoinedStr
        return .joinedStr(JoinedStr(
            values: values,
            lineno: startToken.line,
            colOffset: startToken.column,
            endLineno: stringToken.endLine,
            endColOffset: stringToken.endColumn
        ))
    }
    
    // Strip quotes from string literals
    private func stripQuotes(from str: String) -> String {
        var result = str
        
        // Check for triple quotes
        if result.hasPrefix("\"\"\"") && result.hasSuffix("\"\"\"") {
            result = String(result.dropFirst(3).dropLast(3))
        } else if result.hasPrefix("'''") && result.hasSuffix("'''") {
            result = String(result.dropFirst(3).dropLast(3))
        } else if (result.hasPrefix("\"") && result.hasSuffix("\"")) ||
                  (result.hasPrefix("'") && result.hasSuffix("'")) {
            result = String(result.dropFirst().dropLast())
        }
        
        // Unescape common escape sequences
        result = result
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "\r")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\\\", with: "\\")
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\'", with: "'")
        
        return result
    }
}

// MARK: - Parse Errors
public enum ParseError: Error, CustomStringConvertible {
    case unexpectedToken(token: Token)
    case expectedName(line: Int)
    case expected(message: String, line: Int)
    case expectedToken(expected: String, got: Token, context: String?)
    case syntaxError(message: String, line: Int)
    
    public var description: String {
        switch self {
        case .unexpectedToken(let token):
            return "Unexpected token '\(token.value)' at line \(token.line)"
        case .expectedName(let line):
            return "Expected name at line \(line)"
        case .expected(let message, let line):
            return "\(message) at line \(line)"
        case .expectedToken(let expected, let got, let context):
            let gotDesc = got.value.isEmpty ? "newline" : "'\(got.value)'"
            var message = "Expected '\(expected)' but got \(gotDesc) at line \(got.line), column \(got.column)"
            if let ctx = context, !ctx.isEmpty {
                message += "\n\n  \(ctx)"
                // Add caret pointing to error location
                // Column is 1-indexed, so column value already points to the position after the last character
                // We need 2 spaces for prefix, plus (column - 1) spaces to reach the position
                let spaces = String(repeating: " ", count: got.column + 1)
                message += "\n\(spaces)^"
                // Show suggestion with the fix
                // Insert the expected character at the error position
                let insertPos = ctx.index(ctx.startIndex, offsetBy: min(got.column, ctx.count))
                var fixed = ctx
                fixed.insert(contentsOf: expected, at: insertPos)
                message += "\n\nDid you mean:\n  \(fixed)"
            }
            return message
        case .syntaxError(let message, let line):
            return "Syntax error: \(message) at line \(line)"
        }
    }
}
