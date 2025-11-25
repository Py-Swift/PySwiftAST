/// Type parameter (Python 3.12+)
public indirect enum TypeParam {
    case typeVar(TypeVar)
    case paramSpec(ParamSpec)
    case typeVarTuple(TypeVarTuple)
}

/// Type variable
public struct TypeVar {
    public var name: String
    public var bound: Expression?
    public var defaultValue: Expression?
    
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
    public var name: String
    public var defaultValue: Expression?
    
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
    public var name: String
    public var defaultValue: Expression?
    
    public init(
        name: String,
        defaultValue: Expression?
    ) {
        self.name = name
        self.defaultValue = defaultValue
    }
}
