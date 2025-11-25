/// Assignment statement
public struct Assign: ASTNode, Sendable {
    public var targets: [Expression]
    public var value: Expression
    public var typeComment: String?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

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
public struct AugAssign: ASTNode, Sendable {
    public var target: Expression
    public var op: Operator
    public var value: Expression
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

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
public struct AnnAssign: ASTNode, Sendable {
    public var target: Expression
    public var annotation: Expression
    public var value: Expression?
    public var simple: Bool
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

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
public struct Delete: ASTNode, Sendable {
    public var targets: [Expression]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

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
