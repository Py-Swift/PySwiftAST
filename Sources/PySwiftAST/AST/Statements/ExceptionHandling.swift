/// Raise statement
public struct Raise: ASTNode {
    public let exc: Expression?
    public let cause: Expression?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
public struct Try: ASTNode {
    public let body: [Statement]
    public let handlers: [ExceptHandler]
    public let orElse: [Statement]
    public let finalBody: [Statement]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
public struct TryStar: ASTNode {
    public let body: [Statement]
    public let handlers: [ExceptHandler]
    public let orElse: [Statement]
    public let finalBody: [Statement]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
public struct Assert: ASTNode {
    public let test: Expression
    public let msg: Expression?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
