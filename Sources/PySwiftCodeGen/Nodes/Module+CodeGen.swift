import PySwiftAST

/// Code generation for Module
extension Module: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        switch self {
        case .module(let statements):
            return statements.map { $0.toPythonCode(context: context) }.joined(separator: "\n")
        case .interactive(let statements):
            return statements.map { $0.toPythonCode(context: context) }.joined(separator: "\n")
        case .expression(let expr):
            return expr.toPythonCode(context: context)
        case .functionType(let argTypes, let returnType):
            let argsCode = argTypes.map { $0.toPythonCode(context: context) }.joined(separator: ", ")
            let retCode = returnType.toPythonCode(context: context)
            return "(\(argsCode)) -> \(retCode)"
        }
    }
}
