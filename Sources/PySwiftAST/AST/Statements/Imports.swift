/// Import statement
public struct Import: ASTNode, Sendable {
    public var names: [Alias]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        names: [Alias],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.names = names
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Import from statement
public struct ImportFrom: ASTNode, Sendable {
    public var module: String?
    public var names: [Alias]
    public var level: Int
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        module: String?,
        names: [Alias],
        level: Int,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.module = module
        self.names = names
        self.level = level
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
