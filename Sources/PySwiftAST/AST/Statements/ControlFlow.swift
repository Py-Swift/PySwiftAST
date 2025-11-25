/// Return statement
public struct Return: ASTNode, Sendable {
    public var value: Expression?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        value: Expression?,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.value = value
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// If statement
public struct If: ASTNode, Sendable {
    public var test: Expression
    public var body: [Statement]
    public var orElse: [Statement]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        test: Expression,
        body: [Statement],
        orElse: [Statement],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.test = test
        self.body = body
        self.orElse = orElse
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// While loop
public struct While: ASTNode, Sendable {
    public var test: Expression
    public var body: [Statement]
    public var orElse: [Statement]
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        test: Expression,
        body: [Statement],
        orElse: [Statement],
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.test = test
        self.body = body
        self.orElse = orElse
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// For loop
public struct For: ASTNode, Sendable {
    public var target: Expression
    public var iter: Expression
    public var body: [Statement]
    public var orElse: [Statement]
    public var typeComment: String?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        target: Expression,
        iter: Expression,
        body: [Statement],
        orElse: [Statement],
        typeComment: String?,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.target = target
        self.iter = iter
        self.body = body
        self.orElse = orElse
        self.typeComment = typeComment
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Async for loop
public struct AsyncFor: ASTNode, Sendable {
    public var target: Expression
    public var iter: Expression
    public var body: [Statement]
    public var orElse: [Statement]
    public var typeComment: String?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        target: Expression,
        iter: Expression,
        body: [Statement],
        orElse: [Statement],
        typeComment: String?,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.target = target
        self.iter = iter
        self.body = body
        self.orElse = orElse
        self.typeComment = typeComment
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Break statement
public struct Break: ASTNode, Sendable {
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Continue statement
public struct Continue: ASTNode, Sendable {
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Pass statement
public struct Pass: ASTNode, Sendable {
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
