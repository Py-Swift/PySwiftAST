/// Global statement
public struct Global: ASTNode {
    public let names: [String]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Nonlocal statement
public struct Nonlocal: ASTNode {
    public let names: [String]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Expression statement
public struct Expr: ASTNode {
    public let value: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Type alias statement (Python 3.12+)
public struct TypeAlias: ASTNode {
    public let name: Expression
    public let typeParams: [TypeParam]
    public let value: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
