/// Await expression
public struct Await: ASTNode {
    public let value: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Yield expression
public struct Yield: ASTNode {
    public let value: Expression?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Yield from expression
public struct YieldFrom: ASTNode {
    public let value: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
