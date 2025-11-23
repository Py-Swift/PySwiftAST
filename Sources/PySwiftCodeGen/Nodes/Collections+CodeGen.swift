import PySwiftAST

// MARK: - Collection Expressions

extension List: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let elemsCode = elts.map { $0.toPythonCode(context: context) }.joined(separator: ", ")
        return "[\(elemsCode)]"
    }
}

extension Tuple: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let elemsCode = elts.map { $0.toPythonCode(context: context) }.joined(separator: ", ")
        
        // Single element tuple needs trailing comma
        if elts.count == 1 {
            return "(\(elemsCode),)"
        }
        
        return "(\(elemsCode))"
    }
}

extension Dict: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var pairs: [String] = []
        
        for (key, value) in zip(keys, values) {
            if let k = key {
                pairs.append("\(k.toPythonCode(context: context)): \(value.toPythonCode(context: context))")
            } else {
                // **dict unpacking
                pairs.append("**\(value.toPythonCode(context: context))")
            }
        }
        
        return "{\(pairs.joined(separator: ", "))}"
    }
}

extension Set: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let elemsCode = elts.map { $0.toPythonCode(context: context) }.joined(separator: ", ")
        return "{\(elemsCode)}"
    }
}

// MARK: - Comprehensions

extension ListComp: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let eltCode = elt.toPythonCode(context: context)
        let gensCode = generators.map { $0.toPythonCode(context: context) }.joined(separator: " ")
        return "[\(eltCode) \(gensCode)]"
    }
}

extension SetComp: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let eltCode = elt.toPythonCode(context: context)
        let gensCode = generators.map { $0.toPythonCode(context: context) }.joined(separator: " ")
        return "{\(eltCode) \(gensCode)}"
    }
}

extension DictComp: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let keyCode = key.toPythonCode(context: context)
        let valueCode = value.toPythonCode(context: context)
        let gensCode = generators.map { $0.toPythonCode(context: context) }.joined(separator: " ")
        return "{\(keyCode): \(valueCode) \(gensCode)}"
    }
}

extension GeneratorExp: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let eltCode = elt.toPythonCode(context: context)
        let gensCode = generators.map { $0.toPythonCode(context: context) }.joined(separator: " ")
        return "(\(eltCode) \(gensCode))"
    }
}

extension Comprehension: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var code = "for \(target.toPythonCode(context: context)) in \(iter.toPythonCode(context: context))"
        
        for ifExpr in ifs {
            code += " if \(ifExpr.toPythonCode(context: context))"
        }
        
        return code
    }
}

// MARK: - F-Strings

extension JoinedStr: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let parts = values.map { $0.toPythonCode(context: context) }.joined()
        return "f\"\(parts)\""
    }
}

extension FormattedValue: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var code = "{\(value.toPythonCode(context: context))"
        
        if conversion != -1 {
            switch conversion {
            case 115: code += "!s"  // str
            case 114: code += "!r"  // repr
            case 97: code += "!a"   // ascii
            default: break
            }
        }
        
        if let spec = formatSpec {
            code += ":" + spec.toPythonCode(context: context)
        }
        
        code += "}"
        return code
    }
}
