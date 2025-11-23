/// Dictionary literal
public struct Dict: ASTNode {
    public let keys: [Expression?]
    public let values: [Expression]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Set literal
public struct Set: ASTNode {
    public let elts: [Expression]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// List literal
public struct List: ASTNode {
    public let elts: [Expression]
    public let ctx: ExprContext
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Tuple literal
public struct Tuple: ASTNode {
    public let elts: [Expression]
    public let ctx: ExprContext
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
