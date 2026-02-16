/// Global statement
public struct Global: ASTNode, Sendable {
    public var names: [String]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        names: [String],
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.names = names
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Nonlocal statement
public struct Nonlocal: ASTNode, Sendable {
    public var names: [String]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        names: [String],
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.names = names
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Expression statement
public struct Expr: ASTNode, Sendable {
    public var value: Expression
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        value: Expression,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.value = value
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Type alias statement (Python 3.12+)
public struct TypeAlias: ASTNode, Sendable {
    public var name: Expression
    public var typeParams: [TypeParam]
    public var value: Expression
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        name: Expression,
        typeParams: [TypeParam],
        value: Expression,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.name = name
        self.typeParams = typeParams
        self.value = value
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
