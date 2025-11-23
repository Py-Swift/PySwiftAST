/// Assignment statement
public struct Assign: ASTNode {
    public let targets: [Expression]
    public let value: Expression
    public let typeComment: String?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Augmented assignment (+=, -=, etc.)
public struct AugAssign: ASTNode {
    public let target: Expression
    public let op: Operator
    public let value: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Annotated assignment
public struct AnnAssign: ASTNode {
    public let target: Expression
    public let annotation: Expression
    public let value: Expression?
    public let simple: Bool
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}

/// Delete statement
public struct Delete: ASTNode {
    public let targets: [Expression]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
}
