import PySwiftAST

/// Protocol for Python code formatters
///
/// Formatters transform Python AST modules to enforce specific code styles.
/// They can operate at different levels:
/// - Top-level only (module statements)
/// - Deep/recursive (all nested structures)
public protocol PyFormatter {
    /// Format a module's statements according to the formatter's rules
    ///
    /// This method applies formatting rules to the module-level statements only.
    /// Nested structures (function bodies, class bodies, etc.) are not formatted.
    ///
    /// - Parameter module: The module to format
    /// - Returns: A new module with formatting applied to top-level statements
    func format(_ module: Module) -> Module
    
    /// Recursively format all statements in a module and nested structures
    ///
    /// This method applies formatting rules at all nesting levels:
    /// - Module level (top-level statements)
    /// - Class bodies
    /// - Function bodies
    /// - Control flow blocks (if/while/for/try/etc.)
    ///
    /// - Parameter module: The module to format
    /// - Returns: A new module with formatting applied recursively to all levels
    func formatDeep(_ module: Module) -> Module
}

/// Default implementation for formatDeep that formats statements recursively
extension PyFormatter {
    /// Default deep formatting implementation
    ///
    /// This provides a basic recursive formatter that can be overridden by conforming types
    /// for more sophisticated formatting logic.
    public func formatDeep(_ module: Module) -> Module {
        format(module)
    }
}
