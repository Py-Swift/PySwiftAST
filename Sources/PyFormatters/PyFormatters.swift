/// PyFormatters - Code formatting utilities for Python AST
///
/// This module provides formatters for Python code, allowing control over:
/// - Blank line insertion (PEP 8 compliance)
/// - Indentation styles
/// - Line spacing in classes and functions
/// - Import organization
///
/// All formatters conform to the `PyFormatter` protocol, providing both
/// `format(_:)` for top-level formatting and `formatDeep(_:)` for recursive formatting.
///
/// Example:
/// ```swift
/// let formatter: PyFormatter = BlackFormatter()
/// let formatted = formatter.formatDeep(module)
/// ```

public struct PyFormatters {
    public static let version = "1.0.0"
}
