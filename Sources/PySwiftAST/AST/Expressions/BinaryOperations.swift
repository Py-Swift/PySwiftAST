/// Boolean operation (and, or)
public struct BoolOp: ASTNode, Sendable {
    public var op: BoolOperator
    public var values: [Expression]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        op: BoolOperator,
        values: [Expression],
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
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
public struct BinOp: ASTNode, Sendable {
    public var left: Expression
    public var op: Operator
    public var right: Expression
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        left: Expression,
        op: Operator,
        right: Expression,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
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
public struct UnaryOp: ASTNode, Sendable {
    public var op: UnaryOperator
    public var operand: Expression
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        op: UnaryOperator,
        operand: Expression,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
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
public struct Compare: ASTNode, Sendable {
    public var left: Expression
    public var ops: [CmpOp]
    public var comparators: [Expression]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        left: Expression,
        ops: [CmpOp],
        comparators: [Expression],
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
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
