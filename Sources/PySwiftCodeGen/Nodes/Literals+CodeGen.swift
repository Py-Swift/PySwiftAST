import PySwiftAST

// MARK: - Basic Expressions

extension Name: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        return id
    }
}

extension Constant: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        switch value {
        case .none:
            return "None"
        case .bool(let b):
            return b ? "True" : "False"
        case .int(let i):
            return String(i)
        case .float(let f):
            return String(f)
        case .complex(let real, let imag):
            if real == 0.0 {
                return "\(imag)j"
            } else {
                return "(\(real)+\(imag)j)"
            }
        case .string(let s):
            let quote = context.useSingleQuotes ? "'" : "\""
            // Escape the quotes and special characters
            let escaped = s
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: quote, with: "\\\(quote)")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")
            return quote + escaped + quote
        case .bytes(let data):
            let hexStr = data.map { String(format: "%02x", $0) }.joined()
            return "b'\\x" + hexStr.split(every: 2).joined(separator: "\\x") + "'"
        case .ellipsis:
            return "..."
        }
    }
}

extension Attribute: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let valueCode = value.toPythonCode(context: context)
        return valueCode + "." + attr
    }
}

extension Subscript: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let valueCode = value.toPythonCode(context: context)
        let sliceCode = slice.toPythonCode(context: context)
        return valueCode + "[" + sliceCode + "]"
    }
}

extension Starred: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        return "*" + value.toPythonCode(context: context)
    }
}

extension Slice: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var parts: [String] = []
        
        if let lower = lower {
            parts.append(lower.toPythonCode(context: context))
        } else {
            parts.append("")
        }
        
        parts.append("")  // The colon
        
        if let upper = upper {
            parts.append(upper.toPythonCode(context: context))
        }
        
        if let step = step {
            parts.append("")  // Second colon
            parts.append(step.toPythonCode(context: context))
        }
        
        if step != nil {
            return parts[0] + ":" + (parts.count > 2 ? parts[2] : "") + ":" + (parts.count > 4 ? parts[4] : "")
        } else {
            return parts[0] + ":" + (parts.count > 2 ? parts[2] : "")
        }
    }
}

// Helper extension for splitting strings
private extension String {
    func split(every n: Int) -> [String] {
        var result: [String] = []
        var current = ""
        for (i, char) in enumerated() {
            current.append(char)
            if (i + 1) % n == 0 {
                result.append(current)
                current = ""
            }
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}
