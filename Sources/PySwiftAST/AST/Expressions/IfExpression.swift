/// Conditional expression (ternary operator)
public struct IfExp: ASTNode {
    public let test: Expression
    public let body: Expression
    public let orElse: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
