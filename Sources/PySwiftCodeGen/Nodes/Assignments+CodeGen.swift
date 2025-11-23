import PySwiftAST

// MARK: - Assignment Statements

extension Assign: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let targetsCode = targets.map { $0.toPythonCode(context: context) }.joined(separator: " = ")
        let valueCode = value.toPythonCode(context: context)
        return context.indent + targetsCode + " = " + valueCode
    }
}

extension AugAssign: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let targetCode = target.toPythonCode(context: context)
        let opCode = op.toPythonCode(context: context)
        let valueCode = value.toPythonCode(context: context)
        return context.indent + targetCode + " " + opCode + "= " + valueCode
    }
}

extension AnnAssign: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let targetCode = target.toPythonCode(context: context)
        let annotationCode = annotation.toPythonCode(context: context)
        var code = context.indent + targetCode + ": " + annotationCode
        
        if let val = value {
            code += " = " + val.toPythonCode(context: context)
        }
        
        return code
    }
}
