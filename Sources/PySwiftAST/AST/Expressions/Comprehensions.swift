/// List comprehension
public struct ListComp: ASTNode {
    public let elt: Expression
    public let generators: [Comprehension]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Set comprehension
public struct SetComp: ASTNode {
    public let elt: Expression
    public let generators: [Comprehension]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Dictionary comprehension
public struct DictComp: ASTNode {
    public let key: Expression
    public let value: Expression
    public let generators: [Comprehension]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Generator expression
public struct GeneratorExp: ASTNode {
    public let elt: Expression
    public let generators: [Comprehension]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
