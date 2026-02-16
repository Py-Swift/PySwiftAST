/// Function/method call
public struct Call: ASTNode, Sendable {
    public var fun: Expression
    public var args: [Expression]
    public var keywords: [Keyword]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        fun: Expression,
        args: [Expression],
        keywords: [Keyword],
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
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
public struct Attribute: ASTNode, Sendable {
    public var value: Expression
    public var attr: String
    public var ctx: ExprContext
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        value: Expression,
        attr: String,
        ctx: ExprContext,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
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
public struct Subscript: ASTNode, Sendable {
    public var value: Expression
    public var slice: Expression
    public var ctx: ExprContext
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        value: Expression,
        slice: Expression,
        ctx: ExprContext,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
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
public struct Slice: ASTNode, Sendable {
    public var lower: Expression?
    public var upper: Expression?
    public var step: Expression?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        lower: Expression?,
        upper: Expression?,
        step: Expression?,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
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
