import Foundation

/// Python tokenizer that converts source code into tokens
/// Handles Python's indentation-based syntax with INDENT/DEDENT tokens  
public class Tokenizer {
    private let source: String
    private let chars: [Character]     // O(1) indexed character array
    private var position: Int           // Integer index for O(1) access
    private var line: Int = 1
    private var column: Int = 1
    private var indentStack: [Int] = [0]
    private var pendingTokens: [Token] = []
    private var atLineStart = true
    
    // Track bracket depth for implicit line joining (PEP 8)
    private var parenDepth: Int = 0
    private var bracketDepth: Int = 0
    private var braceDepth: Int = 0
    
    public init(source: String) {
        self.source = source
        self.chars = Array(source)     // Convert once at init for O(1) access
        self.position = 0
    }
    
    /// Tokenize the entire source and return all tokens
    public func tokenize() throws -> [Token] {
        var tokens: [Token] = []
        
        while true {
            let token = try nextToken()
            tokens.append(token)
            if token.type == .endmarker {
                break
            }
        }
        
        return tokens
    }
    
    /// Get the next token from the source
    public func nextToken() throws -> Token {
        // Return pending tokens first (DEDENT tokens)
        if !pendingTokens.isEmpty {
            return pendingTokens.removeFirst()
        }
        
        // Handle end of file
        if position >= chars.count {
            // Emit DEDENT tokens for remaining indentation
            if indentStack.count > 1 {
                indentStack.removeLast()
                return Token(type: .dedent, value: "", line: line, column: column, endLine: line, endColumn: column)
            }
            return Token(type: .endmarker, value: "", line: line, column: column, endLine: line, endColumn: column)
        }
        
        // Handle indentation at start of line
        if atLineStart {
            return try handleIndentation()
        }
        
        skipWhitespace()
        
        if position >= chars.count {
            return Token(type: .endmarker, value: "", line: line, column: column, endLine: line, endColumn: column)
        }
        
        let char = chars[position]
        
        // Comments
        if char == "#" {
            return scanComment()
        }
        
        // Newlines (skip if inside brackets/parens - implicit line joining)
        if char == "\n" || char == "\r" {
            if parenDepth > 0 || bracketDepth > 0 || braceDepth > 0 {
                // Skip newline inside brackets
                if chars[position] == "\r" {
                    advance()
                    if position < chars.count && chars[position] == "\n" {
                        advance()
                    }
                } else {
                    advance()
                }
                // Continue to next token without emitting NEWLINE
                return try nextToken()
            }
            return scanNewline()
        }
        
        // String literals
        if char == "\"" || char == "'" {
            return try scanString()
        }
        
        // Numbers
        if char.isNumber {
            return scanNumber()
        }
        
        // Names and keywords
        if char.isLetter || char == "_" {
            return scanNameOrKeyword()
        }
        
        // Operators and delimiters
        return try scanOperatorOrDelimiter()
    }
    
    // MARK: - Helper Methods
    
    private func handleIndentation() throws -> Token {
        atLineStart = false
        
        var indent = 0
        while position < chars.count {
            let char = chars[position]
            if char == " " {
                indent += 1
                advance()
            } else if char == "\t" {
                indent += 8
                advance()
            } else {
                break
            }
        }
        
        // Skip blank lines and comments
        if position < chars.count && (chars[position] == "\n" || chars[position] == "\r" || chars[position] == "#") {
            if chars[position] == "#" {
                return scanComment()
            }
            return scanNewline()
        }
        
        // Check if end of file
        if position >= chars.count {
            if indentStack.count > 1 {
                indentStack.removeLast()
                return Token(type: .dedent, value: "", line: line, column: column, endLine: line, endColumn: column)
            }
            return Token(type: .endmarker, value: "", line: line, column: column, endLine: line, endColumn: column)
        }
        
        let currentIndent = indentStack.last!
        
        if indent > currentIndent {
            indentStack.append(indent)
            return Token(type: .indent, value: "", line: line, column: 1, endLine: line, endColumn: indent + 1)
        } else if indent < currentIndent {
            // Generate DEDENT tokens
            var dedents: [Token] = []
            while indentStack.count > 1 && indentStack.last! > indent {
                indentStack.removeLast()
                dedents.append(Token(type: .dedent, value: "", line: line, column: column, endLine: line, endColumn: column))
            }
            
            if indentStack.last! != indent {
                throw TokenError.indentationError(line: line, column: column)
            }
            
            if dedents.count > 1 {
                pendingTokens.append(contentsOf: dedents.dropFirst())
            }
            return dedents[0]
        }
        
        // Same indentation, continue parsing
        return try nextToken()
    }
    
    private func scanComment() -> Token {
        let startLine = line
        let startColumn = column
        var value = ""
        
        advance() // skip '#'
        
        while position < chars.count && chars[position] != "\n" && chars[position] != "\r" {
            value.append(chars[position])
            advance()
        }
        
        return Token(type: .comment(value.trimmingCharacters(in: .whitespaces)), 
                     value: "#\(value)", 
                     line: startLine, 
                     column: startColumn, 
                     endLine: line, 
                     endColumn: column)
    }
    
    private func scanNewline() -> Token {
        let startLine = line
        let startColumn = column
        
        if chars[position] == "\r" {
            advance()
            if position < chars.count && chars[position] == "\n" {
                advance()
            }
        } else {
            advance()
        }
        
        atLineStart = true
        return Token(type: .newline, value: "", line: startLine, column: startColumn, endLine: line, endColumn: column)
    }
    
    private func scanString() throws -> Token {
        let startLine = line
        let startColumn = column
        let quote = chars[position]
        var value = ""
        value.append(quote)
        advance()
        
        // Check for triple-quoted strings
        var tripleQuote = false
        if position < chars.count && chars[position] == quote {
            value.append(quote)
            advance()
            if position < chars.count && chars[position] == quote {
                value.append(quote)
                advance()
                tripleQuote = true
            } else {
                // Empty string
                return Token(type: .string(value), value: value, line: startLine, column: startColumn, endLine: line, endColumn: column)
            }
        }
        
        while position < chars.count {
            let char = chars[position]
            
            if char == "\\" && !tripleQuote {
                value.append(char)
                advance()
                if position < chars.count {
                    value.append(chars[position])
                    advance()
                }
            } else if char == quote {
                value.append(char)
                advance()
                
                if tripleQuote {
                    if position < chars.count && chars[position] == quote {
                        value.append(quote)
                        advance()
                        if position < chars.count && chars[position] == quote {
                            value.append(quote)
                            advance()
                            break
                        }
                    }
                } else {
                    break
                }
            } else {
                value.append(char)
                advance()
            }
        }
        
        return Token(type: .string(value), value: value, line: startLine, column: startColumn, endLine: line, endColumn: column)
    }
    
    private func scanNumber() -> Token {
        let startLine = line
        let startColumn = column
        var value = ""
        
        // Handle hex, octal, binary
        if chars[position] == "0" && position < (chars.count - 1) {
            let nextPos = position + 1
            let nextChar = chars[nextPos]
            if nextChar == "x" || nextChar == "X" || nextChar == "o" || nextChar == "O" || nextChar == "b" || nextChar == "B" {
                value.append(chars[position])
                advance()
                value.append(chars[position])
                advance()
                
                while position < chars.count && (chars[position].isHexDigit || chars[position] == "_") {
                    value.append(chars[position])
                    advance()
                }
                
                return Token(type: .number(value), value: value, line: startLine, column: startColumn, endLine: line, endColumn: column)
            }
        }
        
        // Regular number
        while position < chars.count && (chars[position].isNumber || chars[position] == "_") {
            value.append(chars[position])
            advance()
        }
        
        // Decimal point
        if position < chars.count && chars[position] == "." {
            let nextPos = position + 1
            if nextPos < chars.count && chars[nextPos].isNumber {
                value.append(chars[position])
                advance()
                
                while position < chars.count && (chars[position].isNumber || chars[position] == "_") {
                    value.append(chars[position])
                    advance()
                }
            }
        }
        
        // Exponent
        if position < chars.count && (chars[position] == "e" || chars[position] == "E") {
            value.append(chars[position])
            advance()
            
            if position < chars.count && (chars[position] == "+" || chars[position] == "-") {
                value.append(chars[position])
                advance()
            }
            
            while position < chars.count && (chars[position].isNumber || chars[position] == "_") {
                value.append(chars[position])
                advance()
            }
        }
        
        // Imaginary suffix
        if position < chars.count && (chars[position] == "j" || chars[position] == "J") {
            value.append(chars[position])
            advance()
        }
        
        return Token(type: .number(value), value: value, line: startLine, column: startColumn, endLine: line, endColumn: column)
    }
    
    private func scanNameOrKeyword() -> Token {
        let startLine = line
        let startColumn = column
        var value = ""
        
        while position < chars.count && (chars[position].isLetter || chars[position].isNumber || chars[position] == "_") {
            value.append(chars[position])
            advance()
        }
        
        let type = keywordType(for: value) ?? .name(value)
        return Token(type: type, value: value, line: startLine, column: startColumn, endLine: line, endColumn: column)
    }
    
    private func scanOperatorOrDelimiter() throws -> Token {
        let startLine = line
        let startColumn = column
        let char = chars[position]
        
        // Three character operators (check first - they're longer!)
        if let threeChar = peekString(3), let type = threeCharOperator(threeChar) {
            advance()
            advance()
            advance()
            return Token(type: type, value: threeChar, line: startLine, column: startColumn, endLine: line, endColumn: column)
        }
        
        if let threeChar = peekString(3), threeChar == "..." {
            advance()
            advance()
            advance()
            return Token(type: .ellipsis, value: "...", line: startLine, column: startColumn, endLine: line, endColumn: column)
        }
        
        // Two character operators
        if let twoChar = peekString(2), let type = twoCharOperator(twoChar) {
            advance()
            advance()
            return Token(type: type, value: twoChar, line: startLine, column: startColumn, endLine: line, endColumn: column)
        }
        
        // Single character operators
        let type = singleCharOperator(char)
        let value = String(char)
        advance()
        
        // Track bracket depth for implicit line joining
        switch type {
        case .leftparen:
            parenDepth += 1
        case .rightparen:
            parenDepth = max(0, parenDepth - 1)
        case .leftbracket:
            bracketDepth += 1
        case .rightbracket:
            bracketDepth = max(0, bracketDepth - 1)
        case .leftbrace:
            braceDepth += 1
        case .rightbrace:
            braceDepth = max(0, braceDepth - 1)
        default:
            break
        }
        
        return Token(type: type, value: value, line: startLine, column: startColumn, endLine: line, endColumn: column)
    }
    
    private func keywordType(for word: String) -> TokenType? {
        switch word {
        case "False": return .false
        case "await": return .await
        case "else": return .else
        case "import": return .import
        case "pass": return .pass
        case "None": return TokenType.none
        case "break": return .break
        case "except": return .except
        case "in": return .in
        case "raise": return .raise
        case "True": return .true
        case "class": return .class
        case "finally": return .finally
        case "is": return .is
        case "return": return .return
        case "and": return .and
        case "continue": return .continue
        case "for": return .for
        case "lambda": return .lambda
        case "try": return .try
        case "as": return .as
        case "def": return .def
        case "from": return .from
        case "nonlocal": return .nonlocal
        case "while": return .while
        case "assert": return .assert
        case "del": return .del
        case "global": return .global
        case "not": return .not
        case "with": return .with
        case "async": return .async
        case "elif": return .elif
        case "if": return .if
        case "or": return .or
        case "yield": return .yield
        case "match": return .match
        case "case": return .case
        // Note: "type" is a soft keyword in Python 3.12+, treated as name here
        default: return nil
        }
    }
    
    private func twoCharOperator(_ str: String) -> TokenType? {
        switch str {
        case "==": return .equal
        case "!=": return .notequal
        case "<=": return .lessequal
        case ">=": return .greaterequal
        case "<<": return .leftshift
        case ">>": return .rightshift
        case "**": return .doublestar
        case "//": return .doubleslash
        case "->": return .arrow
        case ":=": return .colonequal
        case "+=": return .plusequal
        case "-=": return .minusequal
        case "*=": return .starequal
        case "/=": return .slashequal
        case "%=": return .percentequal
        case "@=": return .atequal
        case "&=": return .amperequal
        case "|=": return .vbarequal
        case "^=": return .circumflexequal
        default: return nil
        }
    }
    
    private func threeCharOperator(_ str: String) -> TokenType? {
        switch str {
        case "<<=": return .leftshiftequal
        case ">>=": return .rightshiftequal
        case "**=": return .doublestarequal
        case "//=": return .doubleslashequal
        default: return nil
        }
    }
    
    private func singleCharOperator(_ char: Character) -> TokenType {
        switch char {
        case "+": return .plus
        case "-": return .minus
        case "*": return .star
        case "/": return .slash
        case "%": return .percent
        case "@": return .at
        case "&": return .amper
        case "|": return .vbar
        case "^": return .circumflex
        case "~": return .tilde
        case "<": return .less
        case ">": return .greater
        case "(": return .leftparen
        case ")": return .rightparen
        case "[": return .leftbracket
        case "]": return .rightbracket
        case "{": return .leftbrace
        case "}": return .rightbrace
        case ",": return .comma
        case ":": return .colon
        case ".": return .dot
        case ";": return .semicolon
        case "=": return .assign
        default: return .errorToken(String(char))
        }
    }
    
    private func skipWhitespace() {
        while position < chars.count {
            let char = chars[position]
            if char == " " || char == "\t" {
                advance()
            } else {
                break
            }
        }
    }
    
    @inline(__always)
    private func advance() {
        if position < chars.count {
            if chars[position] == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
            position += 1  // Simple integer increment - O(1)
        }
    }
    
    private func peekString(_ count: Int) -> String? {
        var result = ""
        var pos = position
        
        for _ in 0..<count {
            if pos >= chars.count {
                return nil
            }
            result.append(chars[pos])
            pos += 1  // Simple integer increment
        }
        
        return result
    }
}

public enum TokenError: Error, CustomStringConvertible {
    case indentationError(line: Int, column: Int)
    case unterminatedString(line: Int, column: Int)
    case invalidCharacter(char: Character, line: Int, column: Int)
    
    public var description: String {
        switch self {
        case .indentationError(let line, let column):
            return "IndentationError at line \(line), column \(column)"
        case .unterminatedString(let line, let column):
            return "Unterminated string at line \(line), column \(column)"
        case .invalidCharacter(let char, let line, let column):
            return "Invalid character '\(char)' at line \(line), column \(column)"
        }
    }
}
