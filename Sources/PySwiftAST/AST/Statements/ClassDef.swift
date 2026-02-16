/// Class definition
public struct ClassDef: ASTNode, Sendable {
    public var name: String
    public var bases: [Expression]
    public var keywords: [Keyword]
    public var body: [Statement]
    public var decoratorList: [Expression]
    public var typeParams: [TypeParam]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        name: String,
        bases: [Expression],
        keywords: [Keyword],
        body: [Statement],
        decoratorList: [Expression],
        typeParams: [TypeParam],
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.name = name
        self.bases = bases
        self.keywords = keywords
        self.body = body
        self.decoratorList = decoratorList
        self.typeParams = typeParams
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
