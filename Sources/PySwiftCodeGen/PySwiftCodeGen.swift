import PySwiftAST

/// Convert an AST module back to Python source code
/// - Parameters:
///   - module: The AST module to convert
///   - context: Code generation context (indentation, formatting options)
/// - Returns: Python source code as a string
public func generatePythonCode(
    from module: Module,
    context: CodeGenContext = CodeGenContext()
) -> String {
    return module.toPythonCode(context: context)
}

/// Convert an AST statement to Python source code
/// - Parameters:
///   - statement: The statement to convert
///   - context: Code generation context
/// - Returns: Python source code as a string
public func generatePythonCode(
    from statement: Statement,
    context: CodeGenContext = CodeGenContext()
) -> String {
    return statement.toPythonCode(context: context)
}

/// Convert an AST expression to Python source code
/// - Parameters:
///   - expression: The expression to convert
///   - context: Code generation context
/// - Returns: Python source code as a string
public func generatePythonCode(
    from expression: Expression,
    context: CodeGenContext = CodeGenContext()
) -> String {
    return expression.toPythonCode(context: context)
}
