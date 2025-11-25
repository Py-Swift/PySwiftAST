/// Return statement
public struct Return: ASTNode {
    public let value: Expression?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
public struct If: ASTNode {
    public let test: Expression
    public let body: [Statement]
    public let orElse: [Statement]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
public struct While: ASTNode {
    public let test: Expression
    public let body: [Statement]
    public let orElse: [Statement]
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
public struct For: ASTNode {
    public let target: Expression
    public let iter: Expression
    public let body: [Statement]
    public let orElse: [Statement]
    public let typeComment: String?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
public struct AsyncFor: ASTNode {
    public let target: Expression
    public let iter: Expression
    public let body: [Statement]
    public let orElse: [Statement]
    public let typeComment: String?
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
public struct Break: ASTNode {
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
public struct Continue: ASTNode {
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
public struct Pass: ASTNode {
    public let lineno: Int
    public let colOffset: Int
    public let endLineno: Int?
    public let endColOffset: Int?

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
