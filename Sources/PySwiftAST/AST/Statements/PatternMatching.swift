/// Match statement (Python 3.10+)
public struct Match: ASTNode {
    public let subject: Expression
    public let cases: [MatchCase]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
