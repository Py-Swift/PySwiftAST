/// Named expression (walrus operator :=)
public struct NamedExpr: ASTNode {
    public let target: Expression
    public let value: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        target: Expression,
        value: Expression,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.target = target
        self.value = value
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Starred expression (*args)
public struct Starred: ASTNode {
    public let value: Expression
    public let ctx: ExprContext
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        value: Expression,
        ctx: ExprContext,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.value = value
        self.ctx = ctx
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
