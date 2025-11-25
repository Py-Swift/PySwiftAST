/// Dictionary literal
public struct Dict: ASTNode, Sendable {
    public var keys: [Expression?]
    public var values: [Expression]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        keys: [Expression?],
        values: [Expression],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.keys = keys
        self.values = values
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Set literal
public struct Set: ASTNode, Sendable {
    public var elts: [Expression]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        elts: [Expression],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.elts = elts
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// List literal
public struct List: ASTNode, Sendable {
    public var elts: [Expression]
    public var ctx: ExprContext
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        elts: [Expression],
        ctx: ExprContext,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.elts = elts
        self.ctx = ctx
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Tuple literal
public struct Tuple: ASTNode, Sendable {
    public var elts: [Expression]
    public var ctx: ExprContext
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        elts: [Expression],
        ctx: ExprContext,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.elts = elts
        self.ctx = ctx
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
