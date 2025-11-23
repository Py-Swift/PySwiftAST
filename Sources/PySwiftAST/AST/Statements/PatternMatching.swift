/// Match statement (Python 3.10+)
public struct Match: ASTNode {
    public let subject: Expression
    public let cases: [MatchCase]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
