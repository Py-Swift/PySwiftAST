/// Token types for Python 3.13 lexical analysis
public enum TokenType: Equatable, Hashable, Sendable {
    // Literals
    case name(String)
    case number(String)
    case string(String)
    case fstringStart
    case fstringMiddle(String)
    case fstringEnd
    
    // Keywords
    case `false`
    case `await`
    case `else`
    case `import`
    case `pass`
    case `none`
    case `break`
    case `except`
    case `in`
    case `raise`
    case `true`
    case `class`
    case `finally`
    case `is`
    case `return`
    case `and`
    case `continue`
    case `for`
    case `lambda`
    case `try`
    case `as`
    case `def`
    case `from`
    case `nonlocal`
    case `while`
    case `assert`
    case `del`
    case `global`
    case `not`
    case `with`
    case `async`
    case `elif`
    case `if`
    case `or`
    case `yield`
    case `match`  // Python 3.10+
    case `case`   // Python 3.10+
    case `type`   // Python 3.12+
    
    // Soft keywords
    case softKeyword(String) // _, type, match, case
    
    // Operators
    case plus           // +
    case minus          // -
    case star           // *
    case slash          // /
    case doubleslash    // //
    case percent        // %
    case at             // @
    case doublestar     // **
    case amper          // &
    case vbar           // |
    case circumflex     // ^
    case tilde          // ~
    case leftshift      // <<
    case rightshift     // >>
    
    // Comparison operators
    case less           // <
    case greater        // >
    case lessequal      // <=
    case greaterequal   // >=
    case equal          // ==
    case notequal       // !=
    
    // Delimiters
    case leftparen      // (
    case rightparen     // )
    case leftbracket    // [
    case rightbracket   // ]
    case leftbrace      // {
    case rightbrace     // }
    case comma          // ,
    case colon          // :
    case dot            // .
    case semicolon      // ;
    case arrow          // ->
    case colonequal     // :=
    case plusequal      // +=
    case minusequal     // -=
    case starequal      // *=
    case slashequal     // /=
    case doubleslashequal // //=
    case percentequal   // %=
    case atequal        // @=
    case amperequal     // &=
    case vbarequal      // |=
    case circumflexequal // ^=
    case leftshiftequal  // <<=
    case rightshiftequal // >>=
    case doublestarequal // **=
    case assign         // =
    case ellipsis       // ...
    
    // Special tokens
    case newline
    case indent
    case dedent
    case endmarker
    case comment(String)
    case typeComment(String)
    case errorToken(String)
}

/// Represents a token with location information
public struct Token: Sendable {
    public let type: TokenType
    public let value: String
    public let line: Int
    public let column: Int
    public let endLine: Int
    public let endColumn: Int
    
    public init(type: TokenType, value: String, line: Int, column: Int, endLine: Int, endColumn: Int) {
        self.type = type
        self.value = value
        self.line = line
        self.column = column
        self.endLine = endLine
        self.endColumn = endColumn
    }
}

extension TokenType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .name(let s): return "NAME(\(s))"
        case .number(let s): return "NUMBER(\(s))"
        case .string(let s): return "STRING(\(s))"
        case .comment(let s): return "COMMENT(\(s))"
        case .typeComment(let s): return "TYPE_COMMENT(\(s))"
        case .errorToken(let s): return "ERROR(\(s))"
        case .softKeyword(let s): return "SOFT_KEYWORD(\(s))"
        case .fstringMiddle(let s): return "FSTRING_MIDDLE(\(s))"
        default: return String(describing: self).uppercased()
        }
    }
}
