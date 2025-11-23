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
}
