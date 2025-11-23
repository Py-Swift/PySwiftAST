/// Named expression (walrus operator :=)
public struct NamedExpr: ASTNode {
    public let target: Expression
    public let value: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Starred expression (*args)
public struct Starred: ASTNode {
    public let value: Expression
    public let ctx: ExprContext
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
