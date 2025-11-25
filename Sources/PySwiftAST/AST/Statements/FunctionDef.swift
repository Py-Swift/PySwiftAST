/// Function definition
public struct FunctionDef: ASTNode {
    public let name: String
    public let args: Arguments
    public let body: [Statement]
    public let decoratorList: [Expression]
    public let returns: Expression?
    public let typeComment: String?
    public let typeParams: [TypeParam]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        name: String,
        args: Arguments,
        body: [Statement],
        decoratorList: [Expression],
        returns: Expression?,
        typeComment: String?,
        typeParams: [TypeParam],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
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
public struct AsyncFunctionDef: ASTNode {
    public let name: String
    public let args: Arguments
    public let body: [Statement]
    public let decoratorList: [Expression]
    public let returns: Expression?
    public let typeComment: String?
    public let typeParams: [TypeParam]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        name: String,
        args: Arguments,
        body: [Statement],
        decoratorList: [Expression],
        returns: Expression?,
        typeComment: String?,
        typeParams: [TypeParam],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
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
