import PySwiftAST

// MARK: - Simple Statements

extension Expr: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        return context.indent + value.toPythonCode(context: context)
    }
}

extension Return: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        if let val = value {
            return context.indent + "return " + val.toPythonCode(context: context)
        } else {
            return context.indent + "return"
        }
    }
}

extension Delete: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let targets = targets.map { $0.toPythonCode(context: context) }.joined(separator: ", ")
        return context.indent + "del " + targets
    }
}

extension Global: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        return context.indent + "global " + names.joined(separator: ", ")
    }
}

extension Nonlocal: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        return context.indent + "nonlocal " + names.joined(separator: ", ")
    }
}

extension Assert: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var code = context.indent + "assert " + test.toPythonCode(context: context)
        if let msg = msg {
            code += ", " + msg.toPythonCode(context: context)
        }
        return code
    }
}

extension Raise: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var code = context.indent + "raise"
        if let exc = exc {
            code += " " + exc.toPythonCode(context: context)
            if let cause = cause {
                code += " from " + cause.toPythonCode(context: context)
            }
        }
        return code
    }
}
