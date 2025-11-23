import Foundation

/// Main parser class that converts tokens into an AST
/// This will be generated/expanded from Python's PEG grammar
public class Parser {
    private let tokens: [Token]
    private var position: Int = 0
    
    public init(tokens: [Token]) {
        self.tokens = tokens
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
            return try parseFunctionDef()
            
        case .class:
            return try parseClassDef()
            
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
            
        default:
            // Try to parse as expression statement or assignment
            let expr = try parseExpression()
            
            // Check for assignment
            if currentToken().type == .assign {
                advance() // consume '='
                let value = try parseExpression()
                consumeNewlineOrSemicolon()
                return .assign(Assign(
                    targets: [expr],
                    value: value,
                    typeComment: nil,
                    lineno: token.line,
                    colOffset: token.column,
                    endLineno: nil,
                    endColOffset: nil
                ))
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
        
        var value: Expression? = nil
        if !isNewlineOrSemicolon() && !isAtEnd() {
            value = try parseExpression()
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
        
        let target = try parseExpression()
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
        if currentToken().type == .else {
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
    
    private func parseFunctionDef() throws -> Statement {
        let defToken = currentToken()
        advance() // consume 'def'
        
        guard case .name(let name) = currentToken().type else {
            throw ParseError.expectedName(line: currentToken().line)
        }
        advance()
        
        try consume(.leftparen, "Expected '(' after function name")
        let args = try parseArguments()
        try consume(.rightparen, "Expected ')' after function arguments")
        
        try consume(.colon, "Expected ':' after function signature")
        
        let body = try parseBlock()
        
        return .functionDef(FunctionDef(
            name: name,
            args: args,
            body: body,
            decoratorList: [],
            returns: nil,
            typeComment: nil,
            typeParams: [],
            lineno: defToken.line,
            colOffset: defToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseClassDef() throws -> Statement {
        let classToken = currentToken()
        advance() // consume 'class'
        
        guard case .name(let name) = currentToken().type else {
            throw ParseError.expectedName(line: currentToken().line)
        }
        advance()
        
        try consume(.colon, "Expected ':' after class name")
        
        let body = try parseBlock()
        
        return .classDef(ClassDef(
            name: name,
            bases: [],
            keywords: [],
            body: body,
            decoratorList: [],
            typeParams: [],
            lineno: classToken.line,
            colOffset: classToken.column,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
    private func parseImport() throws -> Statement {
        let importToken = currentToken()
        advance() // consume 'import'
        
        var names: [Alias] = []
        
        // Parse first import name
        guard case .name(let moduleName) = currentToken().type else {
            throw ParseError.expected(message: "Expected module name after 'import'", line: currentToken().line)
        }
        advance()
        
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
            
            guard case .name(let name) = currentToken().type else {
                throw ParseError.expected(message: "Expected module name", line: currentToken().line)
            }
            advance()
            
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
            moduleName += "."
            advance()
        }
        
        // Parse module name parts
        if case .name(let name) = currentToken().type {
            moduleName += name
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
        // Simplified for now
        return Arguments(
            posonlyArgs: [],
            args: [],
            vararg: nil,
            kwonlyArgs: [],
            kwDefaults: [],
            kwarg: nil,
            defaults: []
        )
    }
    
    private func parseBlock() throws -> [Statement] {
        try consume(.newline, "Expected newline before block")
        try consume(.indent, "Expected indent")
        
        var statements: [Statement] = []
        
        while currentToken().type != .dedent && !isAtEnd() {
            if currentToken().type == .newline {
                advance()
                continue
            }
            statements.append(try parseStatement())
        }
        
        try consume(.dedent, "Expected dedent")
        
        return statements
    }
    
    private func parseExpression() throws -> Expression {
        return try parseOrExpression()
    }
    
    // Operator precedence parsing (from lowest to highest)
    
    private func parseOrExpression() throws -> Expression {
        var left = try parseAndExpression()
        
        while currentToken().type == .or {
            let token = currentToken()
            advance()
            let right = try parseAndExpression()
            left = .boolOp(BoolOp(
                op: .or,
                values: [left, right],
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func parseAndExpression() throws -> Expression {
        var left = try parseNotExpression()
        
        while currentToken().type == .and {
            let token = currentToken()
            advance()
            let right = try parseNotExpression()
            left = .boolOp(BoolOp(
                op: .and,
                values: [left, right],
                lineno: token.line,
                colOffset: token.column,
                endLineno: nil,
                endColOffset: nil
            ))
        }
        
        return left
    }
    
    private func parseNotExpression() throws -> Expression {
        if currentToken().type == .not {
            let token = currentToken()
            advance()
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
            // Check for keyword argument
            if case .name(let name) = currentToken().type {
                let nextPos = position + 1
                if nextPos < tokens.count && tokens[nextPos].type == .assign {
                    // Keyword argument
                    advance() // consume name
                    advance() // consume '='
                    let value = try parseExpression()
                    keywords.append(Keyword(arg: name, value: value))
                    
                    if currentToken().type == .comma {
                        advance()
                    }
                    continue
                }
            }
            
            // Positional argument
            let arg = try parseExpression()
            args.append(arg)
            
            if currentToken().type == .comma {
                advance()
            } else if currentToken().type != .rightparen {
                throw ParseError.expected(message: "Expected ',' or ')' in function call", line: currentToken().line)
            }
        }
        
        return (args, keywords)
    }
    
    private func parseSlice() throws -> Expression {
        let start = currentToken().type != .colon && currentToken().type != .rightbracket
            ? try parseExpression()
            : nil
        
        if currentToken().type == .colon {
            // Slice
            advance()
            let stop = currentToken().type != .colon && currentToken().type != .rightbracket
                ? try parseExpression()
                : nil
            
            var step: Expression? = nil
            if currentToken().type == .colon {
                advance()
                if currentToken().type != .rightbracket {
                    step = try parseExpression()
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
        
        switch token.type {
        case .name(let name):
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
            return .constant(Constant(
                value: .int(Int(num) ?? 0),
                kind: nil,
                lineno: token.line,
                colOffset: token.column,
                endLineno: token.endLine,
                endColOffset: token.endColumn
            ))
            
        case .string(let str):
            advance()
            return .constant(Constant(
                value: .string(str),
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
            
        case .leftparen:
            // Tuple or parenthesized expression
            advance()
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
            
            let first = try parseExpression()
            
            if currentToken().type == .comma {
                // Tuple
                var elts = [first]
                while currentToken().type == .comma {
                    advance()
                    if currentToken().type == .rightparen {
                        break
                    }
                    elts.append(try parseExpression())
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
            // List
            advance()
            var elts: [Expression] = []
            
            while currentToken().type != .rightbracket && !isAtEnd() {
                elts.append(try parseExpression())
                if currentToken().type == .comma {
                    advance()
                } else if currentToken().type != .rightbracket {
                    throw ParseError.expected(message: "Expected ',' or ']' in list", line: currentToken().line)
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
            // Dict or Set
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
            
            let first = try parseExpression()
            
            if currentToken().type == .colon {
                // Dict
                advance()
                let firstValue = try parseExpression()
                var keys = [first]
                var values = [firstValue]
                
                while currentToken().type == .comma {
                    advance()
                    if currentToken().type == .rightbrace {
                        break
                    }
                    let key = try parseExpression()
                    try consume(.colon, "Expected ':' after dict key")
                    let value = try parseExpression()
                    keys.append(key)
                    values.append(value)
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
                // Set
                var elts = [first]
                while currentToken().type == .comma {
                    advance()
                    if currentToken().type == .rightbrace {
                        break
                    }
                    elts.append(try parseExpression())
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
    
    private func currentToken() -> Token {
        guard position < tokens.count else {
            return Token(type: .endmarker, value: "", line: 0, column: 0, endLine: 0, endColumn: 0)
        }
        return tokens[position]
    }
    
    private func advance() {
        if position < tokens.count {
            position += 1
        }
    }
    
    private func isAtEnd() -> Bool {
        return position >= tokens.count || currentToken().type == .endmarker
    }
    
    private func consume(_ type: TokenType, _ message: String) throws {
        if currentToken().type == type {
            advance()
        } else {
            throw ParseError.expected(message: message, line: currentToken().line)
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
}

// MARK: - Parse Errors
public enum ParseError: Error, CustomStringConvertible {
    case unexpectedToken(token: Token)
    case expectedName(line: Int)
    case expected(message: String, line: Int)
    case syntaxError(message: String, line: Int)
    
    public var description: String {
        switch self {
        case .unexpectedToken(let token):
            return "Unexpected token '\(token.value)' at line \(token.line)"
        case .expectedName(let line):
            return "Expected name at line \(line)"
        case .expected(let message, let line):
            return "\(message) at line \(line)"
        case .syntaxError(let message, let line):
            return "Syntax error: \(message) at line \(line)"
        }
    }
}
