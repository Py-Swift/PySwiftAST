/// Protocol for converting AST nodes back to Python source code
public protocol PyCodeProtocol {
    /// Generate Python source code for this node
    /// - Parameter context: Code generation context (indentation, options, etc.)
    /// - Returns: Generated Python source code
    func toPythonCode(context: CodeGenContext) -> String
}

/// Context for code generation, tracking indentation and formatting options
public struct CodeGenContext {
    /// Current indentation level (number of spaces)
    public var indentLevel: Int
    
    /// Number of spaces per indentation level (default: 4)
    public var indentSize: Int
    
    /// Whether to add trailing commas in multi-line structures
    public var useTrailingCommas: Bool
    
    /// Maximum line length before wrapping (0 = no limit)
    public var maxLineLength: Int
    
    /// Whether to use single quotes for strings (vs double quotes)
    public var useSingleQuotes: Bool
    
    /// Whether we're currently inside a subscript (affects tuple formatting)
    public var inSubscript: Bool
    
    public init(
        indentLevel: Int = 0,
        indentSize: Int = 4,
        useTrailingCommas: Bool = true,
        maxLineLength: Int = 88,  // Black's default
        useSingleQuotes: Bool = false,
        inSubscript: Bool = false
    ) {
        self.indentLevel = indentLevel
        self.indentSize = indentSize
        self.useTrailingCommas = useTrailingCommas
        self.maxLineLength = maxLineLength
        self.useSingleQuotes = useSingleQuotes
        self.inSubscript = inSubscript
    }
    
    /// Get the current indentation string
    public var indent: String {
        String(repeating: " ", count: indentLevel * indentSize)
    }
    
    /// Create a new context with increased indentation
    public func indented() -> CodeGenContext {
        var ctx = self
        ctx.indentLevel += 1
        return ctx
    }
    
    /// Create a new context with decreased indentation
    public func dedented() -> CodeGenContext {
        var ctx = self
        ctx.indentLevel = max(0, indentLevel - 1)
        return ctx
    }
}

/// Helper extension for joining code with separators
extension Array where Element == String {
    func joinCode(separator: String = ", ", lastSeparator: String? = nil) -> String {
        guard !isEmpty else { return "" }
        guard count > 1 else { return first! }
        
        if let lastSep = lastSeparator {
            return dropLast().joined(separator: separator) + lastSep + last!
        }
        return joined(separator: separator)
    }
}
