/// With statement
public struct With: ASTNode {
    public let items: [WithItem]
    public let body: [Statement]
    public let typeComment: String?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Async with statement
public struct AsyncWith: ASTNode {
    public let items: [WithItem]
    public let body: [Statement]
    public let typeComment: String?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
