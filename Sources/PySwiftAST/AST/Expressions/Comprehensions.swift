/// List comprehension
public struct ListComp: ASTNode {
    public let elt: Expression
    public let generators: [Comprehension]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        elt: Expression,
        generators: [Comprehension],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.elt = elt
        self.generators = generators
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Set comprehension
public struct SetComp: ASTNode {
    public let elt: Expression
    public let generators: [Comprehension]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        elt: Expression,
        generators: [Comprehension],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.elt = elt
        self.generators = generators
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

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

    public init(
        key: Expression,
        value: Expression,
        generators: [Comprehension],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.key = key
        self.value = value
        self.generators = generators
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Generator expression
public struct GeneratorExp: ASTNode {
    public let elt: Expression
    public let generators: [Comprehension]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        elt: Expression,
        generators: [Comprehension],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.elt = elt
        self.generators = generators
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
