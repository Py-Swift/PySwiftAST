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

    /// How the token reads in an error message: "'print'", "newline", "end of input"
    public var displayName: String {
        switch type {
        case .newline: return "newline"
        case .indent: return "indent"
        case .dedent: return "dedent"
        case .endmarker: return "end of input"
        default: return value.isEmpty ? type.description : "'\(value)'"
        }
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
        // Payload-free cases are spelled out: String(describing: self) would call back into this property
        case .fstringStart: return "FSTRINGSTART"
        case .fstringEnd: return "FSTRINGEND"
        case .false: return "FALSE"
        case .await: return "AWAIT"
        case .else: return "ELSE"
        case .import: return "IMPORT"
        case .pass: return "PASS"
        case .none: return "NONE"
        case .break: return "BREAK"
        case .except: return "EXCEPT"
        case .in: return "IN"
        case .raise: return "RAISE"
        case .true: return "TRUE"
        case .class: return "CLASS"
        case .finally: return "FINALLY"
        case .is: return "IS"
        case .return: return "RETURN"
        case .and: return "AND"
        case .continue: return "CONTINUE"
        case .for: return "FOR"
        case .lambda: return "LAMBDA"
        case .try: return "TRY"
        case .as: return "AS"
        case .def: return "DEF"
        case .from: return "FROM"
        case .nonlocal: return "NONLOCAL"
        case .while: return "WHILE"
        case .assert: return "ASSERT"
        case .del: return "DEL"
        case .global: return "GLOBAL"
        case .not: return "NOT"
        case .with: return "WITH"
        case .async: return "ASYNC"
        case .elif: return "ELIF"
        case .if: return "IF"
        case .or: return "OR"
        case .yield: return "YIELD"
        case .match: return "MATCH"
        case .case: return "CASE"
        case .type: return "TYPE"
        case .plus: return "PLUS"
        case .minus: return "MINUS"
        case .star: return "STAR"
        case .slash: return "SLASH"
        case .doubleslash: return "DOUBLESLASH"
        case .percent: return "PERCENT"
        case .at: return "AT"
        case .doublestar: return "DOUBLESTAR"
        case .amper: return "AMPER"
        case .vbar: return "VBAR"
        case .circumflex: return "CIRCUMFLEX"
        case .tilde: return "TILDE"
        case .leftshift: return "LEFTSHIFT"
        case .rightshift: return "RIGHTSHIFT"
        case .less: return "LESS"
        case .greater: return "GREATER"
        case .lessequal: return "LESSEQUAL"
        case .greaterequal: return "GREATEREQUAL"
        case .equal: return "EQUAL"
        case .notequal: return "NOTEQUAL"
        case .leftparen: return "LEFTPAREN"
        case .rightparen: return "RIGHTPAREN"
        case .leftbracket: return "LEFTBRACKET"
        case .rightbracket: return "RIGHTBRACKET"
        case .leftbrace: return "LEFTBRACE"
        case .rightbrace: return "RIGHTBRACE"
        case .comma: return "COMMA"
        case .colon: return "COLON"
        case .dot: return "DOT"
        case .semicolon: return "SEMICOLON"
        case .arrow: return "ARROW"
        case .colonequal: return "COLONEQUAL"
        case .plusequal: return "PLUSEQUAL"
        case .minusequal: return "MINUSEQUAL"
        case .starequal: return "STAREQUAL"
        case .slashequal: return "SLASHEQUAL"
        case .doubleslashequal: return "DOUBLESLASHEQUAL"
        case .percentequal: return "PERCENTEQUAL"
        case .atequal: return "ATEQUAL"
        case .amperequal: return "AMPEREQUAL"
        case .vbarequal: return "VBAREQUAL"
        case .circumflexequal: return "CIRCUMFLEXEQUAL"
        case .leftshiftequal: return "LEFTSHIFTEQUAL"
        case .rightshiftequal: return "RIGHTSHIFTEQUAL"
        case .doublestarequal: return "DOUBLESTAREQUAL"
        case .assign: return "ASSIGN"
        case .ellipsis: return "ELLIPSIS"
        case .newline: return "NEWLINE"
        case .indent: return "INDENT"
        case .dedent: return "DEDENT"
        case .endmarker: return "ENDMARKER"
        }
    }
}
