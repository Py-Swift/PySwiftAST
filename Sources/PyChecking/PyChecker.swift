import PySwiftAST

/// Protocol for Python code checkers that analyze AST
///
/// Checkers perform static analysis on Python AST to detect issues,
/// perform type checking, or analyze code quality.
///
/// Example implementations:
/// - TypeChecker: Static type checking with type inference
/// - UnusedVariableChecker: Detects unused variables
/// - ComplexityChecker: Analyzes code complexity
public protocol PyChecker {
    /// The unique identifier for this checker
    var id: String { get }
    
    /// Human-readable name of the checker
    var name: String { get }
    
    /// Description of what this checker analyzes
    var description: String { get }
    
    /// Check a module and return any issues found
    /// - Parameter module: The Python module to check
    /// - Returns: Array of diagnostic issues found
    func check(_ module: Module) -> [Diagnostic]
}

/// Represents a diagnostic issue found by a checker
public struct Diagnostic: Sendable {
    /// Severity level of the diagnostic
    public enum Severity: String, Sendable {
        case error      // Critical issue that must be fixed
        case warning    // Potential problem that should be reviewed
        case info       // Informational message
        case hint       // Suggestion for improvement
    }
    
    /// The checker that generated this diagnostic
    public let checkerId: String
    
    /// Severity level
    public let severity: Severity
    
    /// Diagnostic message
    public let message: String
    
    /// Location in source code
    public let line: Int
    public let column: Int
    public let endLine: Int?
    public let endColumn: Int?
    
    /// Optional suggestion for fixing the issue
    public let suggestion: String?
    
    public init(
        checkerId: String,
        severity: Severity,
        message: String,
        line: Int,
        column: Int,
        endLine: Int? = nil,
        endColumn: Int? = nil,
        suggestion: String? = nil
    ) {
        self.checkerId = checkerId
        self.severity = severity
        self.message = message
        self.line = line
        self.column = column
        self.endLine = endLine
        self.endColumn = endColumn
        self.suggestion = suggestion
    }
}

// MARK: - Diagnostic Helpers

extension Diagnostic {
    /// Create an error diagnostic
    public static func error(
        checkerId: String,
        message: String,
        line: Int,
        column: Int,
        endLine: Int? = nil,
        endColumn: Int? = nil,
        suggestion: String? = nil
    ) -> Diagnostic {
        Diagnostic(
            checkerId: checkerId,
            severity: .error,
            message: message,
            line: line,
            column: column,
            endLine: endLine,
            endColumn: endColumn,
            suggestion: suggestion
        )
    }
    
    /// Create a warning diagnostic
    public static func warning(
        checkerId: String,
        message: String,
        line: Int,
        column: Int,
        endLine: Int? = nil,
        endColumn: Int? = nil,
        suggestion: String? = nil
    ) -> Diagnostic {
        Diagnostic(
            checkerId: checkerId,
            severity: .warning,
            message: message,
            line: line,
            column: column,
            endLine: endLine,
            endColumn: endColumn,
            suggestion: suggestion
        )
    }
    
    /// Create an info diagnostic
    public static func info(
        checkerId: String,
        message: String,
        line: Int,
        column: Int,
        endLine: Int? = nil,
        endColumn: Int? = nil,
        suggestion: String? = nil
    ) -> Diagnostic {
        Diagnostic(
            checkerId: checkerId,
            severity: .info,
            message: message,
            line: line,
            column: column,
            endLine: endLine,
            endColumn: endColumn,
            suggestion: suggestion
        )
    }
    
    /// Create a hint diagnostic
    public static func hint(
        checkerId: String,
        message: String,
        line: Int,
        column: Int,
        endLine: Int? = nil,
        endColumn: Int? = nil,
        suggestion: String? = nil
    ) -> Diagnostic {
        Diagnostic(
            checkerId: checkerId,
            severity: .hint,
            message: message,
            line: line,
            column: column,
            endLine: endLine,
            endColumn: endColumn,
            suggestion: suggestion
        )
    }
}

// MARK: - CustomStringConvertible

extension Diagnostic: CustomStringConvertible {
    public var description: String {
        var result = "\(line):\(column): \(severity.rawValue): \(message) [\(checkerId)]"
        if let suggestion = suggestion {
            result += "\n  Suggestion: \(suggestion)"
        }
        return result
    }
}

extension Diagnostic.Severity: Comparable {
    public static func < (lhs: Diagnostic.Severity, rhs: Diagnostic.Severity) -> Bool {
        let order: [Diagnostic.Severity] = [.hint, .info, .warning, .error]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
