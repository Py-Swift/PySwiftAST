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
    
    public init(
        name: String,
        bound: Expression?,
        defaultValue: Expression?
    ) {
        self.name = name
        self.bound = bound
        self.defaultValue = defaultValue
    }
}

/// Parameter specification
public struct ParamSpec {
    public let name: String
    public let defaultValue: Expression?
    
    public init(
        name: String,
        defaultValue: Expression?
    ) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

/// Type variable tuple
public struct TypeVarTuple {
    public let name: String
    public let defaultValue: Expression?
    
    public init(
        name: String,
        defaultValue: Expression?
    ) {
        self.name = name
        self.defaultValue = defaultValue
    }
}
