/// Return statement
public struct Return: ASTNode {
    public let value: Expression?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// If statement
public struct If: ASTNode {
    public let test: Expression
    public let body: [Statement]
    public let orElse: [Statement]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// While loop
public struct While: ASTNode {
    public let test: Expression
    public let body: [Statement]
    public let orElse: [Statement]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// For loop
public struct For: ASTNode {
    public let target: Expression
    public let iter: Expression
    public let body: [Statement]
    public let orElse: [Statement]
    public let typeComment: String?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Async for loop
public struct AsyncFor: ASTNode {
    public let target: Expression
    public let iter: Expression
    public let body: [Statement]
    public let orElse: [Statement]
    public let typeComment: String?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Break statement
public struct Break: ASTNode {
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Continue statement
public struct Continue: ASTNode {
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Pass statement
public struct Pass: ASTNode {
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
