/// Formatted value in f-string
public struct FormattedValue: ASTNode {
    public let value: Expression
    public let conversion: Int
    public let formatSpec: Expression?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        value: Expression,
        conversion: Int,
        formatSpec: Expression?,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.value = value
        self.conversion = conversion
        self.formatSpec = formatSpec
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Joined string (f-string)
public struct JoinedStr: ASTNode {
    public let values: [Expression]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        values: [Expression],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.values = values
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
