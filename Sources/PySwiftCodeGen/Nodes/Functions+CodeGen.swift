import PySwiftAST

// MARK: - Function Definitions

extension FunctionDef: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var lines: [String] = []
        
        // Decorators
        for decorator in decoratorList {
            lines.append(context.indent + "@" + decorator.toPythonCode(context: context))
        }
        
        // Function signature
        var signature = context.indent + "def " + name + "("
        signature += args.toPythonCode(context: context)
        signature += ")"
        
        // Return type annotation
        if let ret = returns {
            signature += " -> " + ret.toPythonCode(context: context)
        }
        
        signature += ":"
        lines.append(signature)
        
        // Body
        let bodyContext = context.indented()
        if body.isEmpty {
            lines.append(bodyContext.indent + "pass")
        } else {
            for stmt in body {
                lines.append(stmt.toPythonCode(context: bodyContext))
            }
        }
        
        return lines.joined(separator: "\n")
    }
}

extension AsyncFunctionDef: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var lines: [String] = []
        
        // Decorators
        for decorator in decoratorList {
            lines.append(context.indent + "@" + decorator.toPythonCode(context: context))
        }
        
        // Function signature
        var signature = context.indent + "async def " + name + "("
        signature += args.toPythonCode(context: context)
        signature += ")"
        
        // Return type annotation
        if let ret = returns {
            signature += " -> " + ret.toPythonCode(context: context)
        }
        
        signature += ":"
        lines.append(signature)
        
        // Body
        let bodyContext = context.indented()
        if body.isEmpty {
            lines.append(bodyContext.indent + "pass")
        } else {
            for stmt in body {
                lines.append(stmt.toPythonCode(context: bodyContext))
            }
        }
        
        return lines.joined(separator: "\n")
    }
}

extension Arguments: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var params: [String] = []
        
        // Positional-only args
        for arg in posonlyArgs {
            params.append(arg.toPythonCode(context: context))
        }
        
        if !posonlyArgs.isEmpty {
            params.append("/")
        }
        
        // Regular args with defaults
        let regularCount = args.count
        let defaultsCount = defaults.count
        let noDefaultCount = regularCount - defaultsCount
        
        for (i, arg) in args.enumerated() {
            var paramStr = arg.toPythonCode(context: context)
            
            // Add default if present
            if i >= noDefaultCount {
                let defaultIdx = i - noDefaultCount
                paramStr += " = " + defaults[defaultIdx].toPythonCode(context: context)
            }
            
            params.append(paramStr)
        }
        
        // *args
        if let varg = vararg {
            params.append("*" + varg.toPythonCode(context: context))
        } else if !kwonlyArgs.isEmpty {
            params.append("*")
        }
        
        // Keyword-only args
        for (i, arg) in kwonlyArgs.enumerated() {
            var paramStr = arg.toPythonCode(context: context)
            
            if let defaultVal = kwDefaults[i] {
                paramStr += " = " + defaultVal.toPythonCode(context: context)
            }
            
            params.append(paramStr)
        }
        
        // **kwargs
        if let kwarg = kwarg {
            params.append("**" + kwarg.toPythonCode(context: context))
        }
        
        return params.joined(separator: ", ")
    }
}

extension Arg: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var code = arg
        if let annot = annotation {
            code += ": " + annot.toPythonCode(context: context)
        }
        return code
    }
}
