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
            
        case .if:
            return try parseIf()
            
        case .def:
            return try parseFunctionDef()
            
        case .class:
            return try parseClassDef()
            
        case .import:
            return try parseImport()
            
        case .from:
            return try parseFromImport()
            
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
        // Simplified expression parsing for now
        return try parsePrimary()
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
