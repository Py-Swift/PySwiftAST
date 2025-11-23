/// Raise statement
public struct Raise: ASTNode {
    public let exc: Expression?
    public let cause: Expression?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Try statement
public struct Try: ASTNode {
    public let body: [Statement]
    public let handlers: [ExceptHandler]
    public let orElse: [Statement]
    public let finalBody: [Statement]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Try-star statement (Python 3.11+)
public struct TryStar: ASTNode {
    public let body: [Statement]
    public let handlers: [ExceptHandler]
    public let orElse: [Statement]
    public let finalBody: [Statement]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Assert statement
public struct Assert: ASTNode {
    public let test: Expression
    public let msg: Expression?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
