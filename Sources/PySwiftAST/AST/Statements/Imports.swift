/// Import statement
public struct Import: ASTNode {
    public let names: [Alias]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Import from statement
public struct ImportFrom: ASTNode {
    public let module: String?
    public let names: [Alias]
    public let level: Int
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
