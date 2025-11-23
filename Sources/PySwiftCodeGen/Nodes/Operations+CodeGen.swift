import PySwiftAST

// MARK: - Operation Expressions

extension BinOp: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let leftCode = left.toPythonCode(context: context)
        let opCode = op.toPythonCode(context: context)
        let rightCode = right.toPythonCode(context: context)
        return "(\(leftCode) \(opCode) \(rightCode))"
    }
}

extension UnaryOp: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let opCode = op.toPythonCode(context: context)
        let operandCode = operand.toPythonCode(context: context)
        
        if op == .not {
            return "not \(operandCode)"
        } else {
            return "\(opCode)\(operandCode)"
        }
    }
}

extension BoolOp: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let opCode = op.toPythonCode(context: context)
        let valuesCode = values.map { $0.toPythonCode(context: context) }.joined(separator: " \(opCode) ")
        return "(\(valuesCode))"
    }
}

extension Compare: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var code = left.toPythonCode(context: context)
        
        for (op, comparator) in zip(ops, comparators) {
            code += " " + op.toPythonCode(context: context) + " "
            code += comparator.toPythonCode(context: context)
        }
        
        return code
    }
}

extension NamedExpr: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let targetCode = target.toPythonCode(context: context)
        let valueCode = value.toPythonCode(context: context)
        return "(\(targetCode) := \(valueCode))"
    }
}

extension Call: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let funcCode = fun.toPythonCode(context: context)
        let argsCode = args.map { $0.toPythonCode(context: context) }.joined(separator: ", ")
        
        var allArgs: [String] = []
        if !argsCode.isEmpty {
            allArgs.append(argsCode)
        }
        
        for keyword in keywords {
            if let arg = keyword.arg {
                allArgs.append("\(arg)=\(keyword.value.toPythonCode(context: context))")
            } else {
                // **kwargs
                allArgs.append("**\(keyword.value.toPythonCode(context: context))")
            }
        }
        
        return funcCode + "(" + allArgs.joined(separator: ", ") + ")"
    }
}

extension Lambda: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let argsCode = args.toPythonCode(context: context)
        let bodyCode = body.toPythonCode(context: context)
        return "lambda \(argsCode): \(bodyCode)"
    }
}

extension IfExp: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let bodyCode = body.toPythonCode(context: context)
        let testCode = test.toPythonCode(context: context)
        let orElseCode = orElse.toPythonCode(context: context)
        return "\(bodyCode) if \(testCode) else \(orElseCode)"
    }
}

extension Await: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        return "await " + value.toPythonCode(context: context)
    }
}

extension Yield: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        if let val = value {
            return "yield " + val.toPythonCode(context: context)
        } else {
            return "yield"
        }
    }
}

extension YieldFrom: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        return "yield from " + value.toPythonCode(context: context)
    }
}
