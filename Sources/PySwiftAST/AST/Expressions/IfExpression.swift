/// Conditional expression (ternary operator)
public struct IfExp: ASTNode, Sendable {
    public var test: Expression
    public var body: Expression
    public var orElse: Expression
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

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
