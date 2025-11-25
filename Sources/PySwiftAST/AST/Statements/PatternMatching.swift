/// Match statement (Python 3.10+)
public struct Match: ASTNode, Sendable {
    public var subject: Expression
    public var cases: [MatchCase]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        subject: Expression,
        cases: [MatchCase],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.subject = subject
        self.cases = cases
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
