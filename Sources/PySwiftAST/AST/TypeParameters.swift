/// Type parameter (Python 3.12+)
public indirect enum TypeParam {
    case typeVar(TypeVar)
    case paramSpec(ParamSpec)
    case typeVarTuple(TypeVarTuple)
}

/// Type variable
public struct TypeVar {
    public let name: String
    public let bound: Expression?
    public let defaultValue: Expression?
}

/// Parameter specification
public struct ParamSpec {
    public let name: String
    public let defaultValue: Expression?
}

/// Type variable tuple
public struct TypeVarTuple {
    public let name: String
    public let defaultValue: Expression?
}
