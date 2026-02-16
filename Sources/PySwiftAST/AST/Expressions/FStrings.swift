/// Formatted value in f-string
public struct FormattedValue: ASTNode, Sendable {
    public var value: Expression
    public var conversion: Int
    public var formatSpec: Expression?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        value: Expression,
        conversion: Int,
        formatSpec: Expression?,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
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
public struct JoinedStr: ASTNode, Sendable {
    public var values: [Expression]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        values: [Expression],
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.values = values
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
