/// Expression context for loading, storing, or deleting
public enum ExprContext {
    case load
    case store
    case del
}

/// Boolean operators
public enum BoolOperator {
    case and
    case or
}

/// Binary operators
public enum Operator {
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
public enum UnaryOperator {
    case invert
    case not
    case uAdd
    case uSub
}

/// Comparison operators
public enum CmpOp {
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
