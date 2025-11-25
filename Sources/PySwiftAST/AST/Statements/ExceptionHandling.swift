/// Raise statement
public struct Raise: ASTNode, Sendable {
    public var exc: Expression?
    public var cause: Expression?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        exc: Expression?,
        cause: Expression?,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.exc = exc
        self.cause = cause
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Try statement
public struct Try: ASTNode, Sendable {
    public var body: [Statement]
    public var handlers: [ExceptHandler]
    public var orElse: [Statement]
    public var finalBody: [Statement]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        body: [Statement],
        handlers: [ExceptHandler],
        orElse: [Statement],
        finalBody: [Statement],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.body = body
        self.handlers = handlers
        self.orElse = orElse
        self.finalBody = finalBody
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Try-star statement (Python 3.11+)
public struct TryStar: ASTNode, Sendable {
    public var body: [Statement]
    public var handlers: [ExceptHandler]
    public var orElse: [Statement]
    public var finalBody: [Statement]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        body: [Statement],
        handlers: [ExceptHandler],
        orElse: [Statement],
        finalBody: [Statement],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.body = body
        self.handlers = handlers
        self.orElse = orElse
        self.finalBody = finalBody
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Assert statement
public struct Assert: ASTNode, Sendable {
    public var test: Expression
    public var msg: Expression?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        test: Expression,
        msg: Expression?,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.test = test
        self.msg = msg
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
