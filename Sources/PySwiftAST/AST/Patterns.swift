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
    public var value: Expression
    
    public init(value: Expression) {
        self.value = value
    }
}

/// Match singleton pattern
public struct MatchSingleton {
    public var value: ConstantValue
    
    public init(value: ConstantValue) {
        self.value = value
    }
}

/// Match sequence pattern
public struct MatchSequence {
    public var patterns: [Pattern]
    
    public init(patterns: [Pattern]) {
        self.patterns = patterns
    }
}

/// Match mapping pattern
public struct MatchMapping {
    public var keys: [Expression]
    public var patterns: [Pattern]
    public var rest: String?
    
    public init(
        keys: [Expression],
        patterns: [Pattern],
        rest: String?
    ) {
        self.keys = keys
        self.patterns = patterns
        self.rest = rest
    }
}

/// Match class pattern
public struct MatchClass {
    public var cls: Expression
    public var patterns: [Pattern]
    public var kwdAttrs: [String]
    public var kwdPatterns: [Pattern]
    
    public init(
        cls: Expression,
        patterns: [Pattern],
        kwdAttrs: [String],
        kwdPatterns: [Pattern]
    ) {
        self.cls = cls
        self.patterns = patterns
        self.kwdAttrs = kwdAttrs
        self.kwdPatterns = kwdPatterns
    }
}

/// Match star pattern
public struct MatchStar {
    public var name: String?
    
    public init(name: String?) {
        self.name = name
    }
}

/// Match as pattern
public struct MatchAs {
    public var pattern: Pattern?
    public var name: String?
    
    public init(
        pattern: Pattern?,
        name: String?
    ) {
        self.pattern = pattern
        self.name = name
    }
}

/// Match or pattern
public struct MatchOr {
    public var patterns: [Pattern]
    
    public init(patterns: [Pattern]) {
        self.patterns = patterns
    }
}
