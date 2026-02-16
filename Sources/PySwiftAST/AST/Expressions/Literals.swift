/// Constant value
public struct Constant: ASTNode, Sendable {
    public var value: ConstantValue
    public var kind: String?
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        value: ConstantValue,
        kind: String? = nil,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
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
public enum ConstantValue: Sendable {
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
public struct Name: ASTNode, Sendable {
    public var id: String
    public var ctx: ExprContext
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        id: String,
        ctx: ExprContext = .load,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.id = id
        self.ctx = ctx
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }

}
