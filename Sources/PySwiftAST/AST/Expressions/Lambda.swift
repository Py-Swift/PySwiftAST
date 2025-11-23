/// Lambda expression
public struct Lambda: ASTNode {
    public let args: Arguments
    public let body: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
