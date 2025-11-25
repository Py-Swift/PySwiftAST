/// Boolean operation (and, or)
public struct BoolOp: ASTNode {
    public let op: BoolOperator
    public let values: [Expression]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        op: BoolOperator,
        values: [Expression],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.op = op
        self.values = values
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Binary operation (+, -, *, etc.)
public struct BinOp: ASTNode {
    public let left: Expression
    public let op: Operator
    public let right: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        left: Expression,
        op: Operator,
        right: Expression,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.left = left
        self.op = op
        self.right = right
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Unary operation (-, ~, not)
public struct UnaryOp: ASTNode {
    public let op: UnaryOperator
    public let operand: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        op: UnaryOperator,
        operand: Expression,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.op = op
        self.operand = operand
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Comparison operation
public struct Compare: ASTNode {
    public let left: Expression
    public let ops: [CmpOp]
    public let comparators: [Expression]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

    public init(
        left: Expression,
        ops: [CmpOp],
        comparators: [Expression],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.left = left
        self.ops = ops
        self.comparators = comparators
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
