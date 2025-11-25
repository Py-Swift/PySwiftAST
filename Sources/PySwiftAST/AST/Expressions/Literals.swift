/// Constant value
public struct Constant: ASTNode {
    public var value: ConstantValue
    public var kind: String?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        value: ConstantValue,
        kind: String?,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.value = value
        self.kind = kind
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}

/// Constant value types
public enum ConstantValue {
    case none
    case bool(Bool)
    case int(Int)
    case float(Double)
    case complex(Double, Double)
    case string(String)
    case bytes([UInt8])
    case ellipsis
}

/// Variable name
public struct Name: ASTNode {
    public var id: String
    public var ctx: ExprContext
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        id: String,
        ctx: ExprContext,
        lineno: Int,
        colOffset: Int,
        endLineno: Int?,
        endColOffset: Int?
    ) {
        self.id = id
        self.ctx = ctx
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
