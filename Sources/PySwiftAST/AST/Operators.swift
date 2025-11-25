/// Expression context for loading, storing, or deleting
public enum ExprContext: Sendable {
    case load
    case store
    case del
}

/// Boolean operators
public enum BoolOperator: Sendable {
    case and
    case or
}

/// Binary operators
public enum Operator: Sendable {
    case add
    case sub
    case mult
    case matMult
    case div
    case mod
    case pow
    case lShift
    case rShift
    case bitOr
    case bitXor
    case bitAnd
    case floorDiv
}

/// Unary operators
public enum UnaryOperator: Sendable {
    case invert
    case not
    case uAdd
    case uSub
}

/// Comparison operators
public enum CmpOp: Sendable {
    case eq
    case notEq
    case lt
    case ltE
    case gt
    case gtE
    case `is`
    case isNot
    case `in`
    case notIn
}
