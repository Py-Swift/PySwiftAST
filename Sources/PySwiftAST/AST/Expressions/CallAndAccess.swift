/// Function/method call
public struct Call: ASTNode {
    public let fun: Expression
    public let args: [Expression]
    public let keywords: [Keyword]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        fun: Expression,
        args: [Expression],
        keywords: [Keyword],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.fun = fun
        self.args = args
        self.keywords = keywords
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Attribute access (obj.attr)
public struct Attribute: ASTNode {
    public let value: Expression
    public let attr: String
    public let ctx: ExprContext
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        value: Expression,
        attr: String,
        ctx: ExprContext,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.value = value
        self.attr = attr
        self.ctx = ctx
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Subscript access (obj[key])
public struct Subscript: ASTNode {
    public let value: Expression
    public let slice: Expression
    public let ctx: ExprContext
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        value: Expression,
        slice: Expression,
        ctx: ExprContext,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.value = value
        self.slice = slice
        self.ctx = ctx
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Slice expression
public struct Slice: ASTNode {
    public let lower: Expression?
    public let upper: Expression?
    public let step: Expression?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        lower: Expression?,
        upper: Expression?,
        step: Expression?,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.lower = lower
        self.upper = upper
        self.step = step
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
