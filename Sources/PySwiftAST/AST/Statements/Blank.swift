/// Blank line(s) - formatting control for code generation
/// Not part of Python's AST, but useful for controlling output formatting
public struct Blank: ASTNode, Sendable {
    public var count: Int // Number of blank lines
    public var lineno: Int
    public var colOffset: Int
    public var endLineno: Int?
    public var endColOffset: Int?

    public init(
        count: Int = 1,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) {
        self.count = count
        self.lineno = lineno
        self.colOffset = colOffset
        self.endLineno = endLineno
        self.endColOffset = endColOffset
    }
}

// MARK: - Convenience constructors
extension Statement {
    /// Create a blank line statement
    public static func blank(_ count: Int = 1) -> Statement {
        return .blank(Blank(count: count))
    }
}
