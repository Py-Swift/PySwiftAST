/// Boolean operation (and, or)
public struct BoolOp: ASTNode {
    public let op: BoolOperator
    public let values: [Expression]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
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
}

/// Unary operation (-, ~, not)
public struct UnaryOp: ASTNode {
    public let op: UnaryOperator
    public let operand: Expression
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?
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
}
