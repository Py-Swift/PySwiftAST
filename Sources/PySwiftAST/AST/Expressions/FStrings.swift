/// Formatted value in f-string
public struct FormattedValue: ASTNode {
    public let value: Expression
    public let conversion: Int
    public let formatSpec: Expression?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Joined string (f-string)
public struct JoinedStr: ASTNode {
    public let values: [Expression]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
