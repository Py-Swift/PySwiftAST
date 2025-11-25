/// List comprehension
public struct ListComp: ASTNode, Sendable {
    public var elt: Expression
    public var generators: [Comprehension]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

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
public struct SetComp: ASTNode, Sendable {
    public var elt: Expression
    public var generators: [Comprehension]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

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
public struct DictComp: ASTNode, Sendable {
    public var key: Expression
    public var value: Expression
    public var generators: [Comprehension]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

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
public struct GeneratorExp: ASTNode, Sendable {
    public var elt: Expression
    public var generators: [Comprehension]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

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
