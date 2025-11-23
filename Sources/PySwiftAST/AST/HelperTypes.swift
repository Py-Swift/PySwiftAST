/// Function arguments
public struct Arguments {
    public let posonlyArgs: [Arg]
    public let args: [Arg]
    public let vararg: Arg?
    public let kwonlyArgs: [Arg]
    public let kwDefaults: [Expression?]
    public let kwarg: Arg?
    public let defaults: [Expression]
}

/// Function argument
public struct Arg {
    public let arg: String
    public let annotation: Expression?
    public let typeComment: String?
}

/// Keyword argument
public struct Keyword {
    public let arg: String?
    public let value: Expression
}

/// Import alias
public struct Alias {
    public let name: String
    public let asName: String?
}

/// With statement item
public struct WithItem {
    public let contextExpr: Expression
    public let optionalVars: Expression?
}

/// Match case
public struct MatchCase {
    public let pattern: Pattern
    public let guardExpr: Expression?
    public let body: [Statement]
}

/// Exception handler
public struct ExceptHandler {
    public let type: Expression?
    public let name: String?
    public let body: [Statement]
}

/// Comprehension clause
public struct Comprehension {
    public let target: Expression
    public let iter: Expression
    public let ifs: [Expression]
    public let isAsync: Bool
}
