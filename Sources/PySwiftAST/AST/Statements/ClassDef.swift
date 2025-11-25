/// Class definition
public struct ClassDef: ASTNode {
    public let name: String
    public let bases: [Expression]
    public let keywords: [Keyword]
    public let body: [Statement]
    public let decoratorList: [Expression]
    public let typeParams: [TypeParam]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        name: String,
        bases: [Expression],
        keywords: [Keyword],
        body: [Statement],
        decoratorList: [Expression],
        typeParams: [TypeParam],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
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
