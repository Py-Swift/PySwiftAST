/// With statement
public struct With: ASTNode, Sendable {
    public var items: [WithItem]
    public var body: [Statement]
    public var typeComment: String?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        items: [WithItem],
        body: [Statement],
        typeComment: String?,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.items = items
        self.body = body
        self.typeComment = typeComment
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Async with statement
public struct AsyncWith: ASTNode, Sendable {
    public var items: [WithItem]
    public var body: [Statement]
    public var typeComment: String?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        items: [WithItem],
        body: [Statement],
        typeComment: String?,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.items = items
        self.body = body
        self.typeComment = typeComment
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
