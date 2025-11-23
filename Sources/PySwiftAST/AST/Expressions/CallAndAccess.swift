/// Function/method call
public struct Call: ASTNode {
    public let fun: Expression
    public let args: [Expression]
    public let keywords: [Keyword]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
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
}
