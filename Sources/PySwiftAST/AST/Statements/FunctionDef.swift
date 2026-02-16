/// Function definition
public struct FunctionDef: ASTNode, Sendable {
    public var name: String
    public var args: Arguments
    public var body: [Statement]
    public var decoratorList: [Expression]
    public var returns: Expression?
    public var typeComment: String?
    public var typeParams: [TypeParam]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        name: String,
        args: Arguments,
        body: [Statement],
        decoratorList: [Expression],
        returns: Expression?,
        typeComment: String?,
        typeParams: [TypeParam],
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.name = name
        self.args = args
        self.body = body
        self.decoratorList = decoratorList
        self.returns = returns
        self.typeComment = typeComment
        self.typeParams = typeParams
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Async function definition
public struct AsyncFunctionDef: ASTNode, Sendable {
    public var name: String
    public var args: Arguments
    public var body: [Statement]
    public var decoratorList: [Expression]
    public var returns: Expression?
    public var typeComment: String?
    public var typeParams: [TypeParam]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        name: String,
        args: Arguments,
        body: [Statement],
        decoratorList: [Expression],
        returns: Expression?,
        typeComment: String?,
        typeParams: [TypeParam],
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.name = name
        self.args = args
        self.body = body
        self.decoratorList = decoratorList
        self.returns = returns
        self.typeComment = typeComment
        self.typeParams = typeParams
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
