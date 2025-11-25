/// Conditional expression (ternary operator)
public struct IfExp: ASTNode {
    public let test: Expression
    public let body: Expression
    public let orElse: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        test: Expression,
        body: Expression,
        orElse: Expression,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.test = test
        self.body = body
        self.orElse = orElse
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
