/// Assignment statement
public struct Assign: ASTNode {
    public let targets: [Expression]
    public let value: Expression
    public let typeComment: String?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        targets: [Expression],
        value: Expression,
        typeComment: String?,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.targets = targets
        self.value = value
        self.typeComment = typeComment
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

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

    public init(
        target: Expression,
        op: Operator,
        value: Expression,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.target = target
        self.op = op
        self.value = value
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

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

    public init(
        target: Expression,
        annotation: Expression,
        value: Expression?,
        simple: Bool,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.target = target
        self.annotation = annotation
        self.value = value
        self.simple = simple
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Delete statement
public struct Delete: ASTNode {
    public let targets: [Expression]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        targets: [Expression],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.targets = targets
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
