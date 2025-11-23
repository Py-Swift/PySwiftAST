/// Pattern matching patterns (Python 3.10+)
public indirect enum Pattern {
    case matchValue(MatchValue)
    case matchSingleton(MatchSingleton)
    case matchSequence(MatchSequence)
    case matchMapping(MatchMapping)
    case matchClass(MatchClass)
    case matchStar(MatchStar)
    case matchAs(MatchAs)
    case matchOr(MatchOr)
}

/// Match value pattern
public struct MatchValue {
    public let value: Expression
}

/// Match singleton pattern
public struct MatchSingleton {
    public let value: ConstantValue
}

/// Match sequence pattern
public struct MatchSequence {
    public let patterns: [Pattern]
}

/// Match mapping pattern
public struct MatchMapping {
    public let keys: [Expression]
    public let patterns: [Pattern]
    public let rest: String?
}

/// Match class pattern
public struct MatchClass {
    public let cls: Expression
    public let patterns: [Pattern]
    public let kwdAttrs: [String]
    public let kwdPatterns: [Pattern]
}

/// Match star pattern
public struct MatchStar {
    public let name: String?
}

/// Match as pattern
public struct MatchAs {
    public let pattern: Pattern?
    public let name: String?
}

/// Match or pattern
public struct MatchOr {
    public let patterns: [Pattern]
}
