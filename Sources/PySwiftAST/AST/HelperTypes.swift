/// Function arguments
public struct Arguments: Sendable {
    public var posonlyArgs: [Arg]
    public var args: [Arg]
    public var vararg: Arg?
    public var kwonlyArgs: [Arg]
    public var kwDefaults: [Expression?]
    public var kwarg: Arg?
    public var defaults: [Expression]
    
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
public struct Arg: Sendable {
    public var arg: String
    public var annotation: Expression?
    public var typeComment: String?
    
    public init(
        arg: String,
        annotation: Expression? = nil,
        typeComment: String? = nil
    ) {
        self.arg = arg
        self.annotation = annotation
        self.typeComment = typeComment
    }
}

extension Arg: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(arg: value)
    }
}

/// Keyword argument
public struct Keyword: Sendable {
    public var arg: String?
    public var value: Expression
    
    public init(
        arg: String?,
        value: Expression
    ) {
        self.arg = arg
        self.value = value
    }
}

/// Import alias
public struct Alias: Sendable {
    public var name: String
    public var asName: String?
    
    public init(
        name: String,
        asName: String?
    ) {
        self.name = name
        self.asName = asName
    }
}

/// With statement item
public struct WithItem: Sendable {
    public var contextExpr: Expression
    public var optionalVars: Expression?
    
    public init(
        contextExpr: Expression,
        optionalVars: Expression?
    ) {
        self.contextExpr = contextExpr
        self.optionalVars = optionalVars
    }
}

/// Match case
public struct MatchCase: Sendable {
    public var pattern: Pattern
    public var guardExpr: Expression?
    public var body: [Statement]
    
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
public struct ExceptHandler: Sendable {
    public var type: Expression?
    public var name: String?
    public var body: [Statement]
    
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
public struct Comprehension: Sendable {
    public var target: Expression
    public var iter: Expression
    public var ifs: [Expression]
    public var isAsync: Bool
    
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
