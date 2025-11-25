/// Function arguments
public struct Arguments {
    public let posonlyArgs: [Arg]
    public let args: [Arg]
    public let vararg: Arg?
    public let kwonlyArgs: [Arg]
    public let kwDefaults: [Expression?]
    public let kwarg: Arg?
    public let defaults: [Expression]
    
    public init(
        posonlyArgs: [Arg],
        args: [Arg],
        vararg: Arg?,
        kwonlyArgs: [Arg],
        kwDefaults: [Expression?],
        kwarg: Arg?,
        defaults: [Expression]
    ) {
        self.posonlyArgs = posonlyArgs
        self.args = args
        self.vararg = vararg
        self.kwonlyArgs = kwonlyArgs
        self.kwDefaults = kwDefaults
        self.kwarg = kwarg
        self.defaults = defaults
    }
}

/// Function argument
public struct Arg {
    public let arg: String
    public let annotation: Expression?
    public let typeComment: String?
    
    public init(
        arg: String,
        annotation: Expression?,
        typeComment: String?
    ) {
        self.arg = arg
        self.annotation = annotation
        self.typeComment = typeComment
    }
}

/// Keyword argument
public struct Keyword {
    public let arg: String?
    public let value: Expression
    
    public init(
        arg: String?,
        value: Expression
    ) {
        self.arg = arg
        self.value = value
    }
}

/// Import alias
public struct Alias {
    public let name: String
    public let asName: String?
    
    public init(
        name: String,
        asName: String?
    ) {
        self.name = name
        self.asName = asName
    }
}

/// With statement item
public struct WithItem {
    public let contextExpr: Expression
    public let optionalVars: Expression?
    
    public init(
        contextExpr: Expression,
        optionalVars: Expression?
    ) {
        self.contextExpr = contextExpr
        self.optionalVars = optionalVars
    }
}

/// Match case
public struct MatchCase {
    public let pattern: Pattern
    public let guardExpr: Expression?
    public let body: [Statement]
    
    public init(
        pattern: Pattern,
        guardExpr: Expression?,
        body: [Statement]
    ) {
        self.pattern = pattern
        self.guardExpr = guardExpr
        self.body = body
    }
}

/// Exception handler
public struct ExceptHandler {
    public let type: Expression?
    public let name: String?
    public let body: [Statement]
    
    public init(
        type: Expression?,
        name: String?,
        body: [Statement]
    ) {
        self.type = type
        self.name = name
        self.body = body
    }
}

/// Comprehension clause
public struct Comprehension {
    public let target: Expression
    public let iter: Expression
    public let ifs: [Expression]
    public let isAsync: Bool
    
    public init(
        target: Expression,
        iter: Expression,
        ifs: [Expression],
        isAsync: Bool
    ) {
        self.target = target
        self.iter = iter
        self.ifs = ifs
        self.isAsync = isAsync
    }
}
