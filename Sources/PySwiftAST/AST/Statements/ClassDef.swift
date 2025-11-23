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
}
