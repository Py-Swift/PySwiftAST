import PySwiftAST

// MARK: - Placeholder implementations for complex types
// These will be fully implemented in subsequent files

extension ClassDef: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var lines: [String] = []
        
        // Decorators
        for decorator in decoratorList {
            lines.append(context.indent + "@" + decorator.toPythonCode(context: context))
        }
        
        // Class signature
        var signature = context.indent + "class " + name
        
        if !bases.isEmpty || !keywords.isEmpty {
            signature += "("
            var parts: [String] = []
            parts.append(contentsOf: bases.map { $0.toPythonCode(context: context) })
            parts.append(contentsOf: keywords.map { "\($0.arg ?? "")=\($0.value.toPythonCode(context: context))" })
            signature += parts.joined(separator: ", ")
            signature += ")"
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

extension For: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var lines: [String] = []
        
        let targetCode = target.toPythonCode(context: context)
        let iterCode = iter.toPythonCode(context: context)
        lines.append(context.indent + "for \(targetCode) in \(iterCode):")
        
        let bodyContext = context.indented()
        for stmt in body {
            lines.append(stmt.toPythonCode(context: bodyContext))
        }
        
        if !orElse.isEmpty {
            lines.append(context.indent + "else:")
            for stmt in orElse {
                lines.append(stmt.toPythonCode(context: bodyContext))
            }
        }
        
        return lines.joined(separator: "\n")
    }
}

extension AsyncFor: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var lines: [String] = []
        
        let targetCode = target.toPythonCode(context: context)
        let iterCode = iter.toPythonCode(context: context)
        lines.append(context.indent + "async for \(targetCode) in \(iterCode):")
        
        let bodyContext = context.indented()
        for stmt in body {
            lines.append(stmt.toPythonCode(context: bodyContext))
        }
        
        if !orElse.isEmpty {
            lines.append(context.indent + "else:")
            for stmt in orElse {
                lines.append(stmt.toPythonCode(context: bodyContext))
            }
        }
        
        return lines.joined(separator: "\n")
    }
}

extension While: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var lines: [String] = []
        
        let testCode = test.toPythonCode(context: context)
        lines.append(context.indent + "while \(testCode):")
        
        let bodyContext = context.indented()
        for stmt in body {
            lines.append(stmt.toPythonCode(context: bodyContext))
        }
        
        if !orElse.isEmpty {
            lines.append(context.indent + "else:")
            for stmt in orElse {
                lines.append(stmt.toPythonCode(context: bodyContext))
            }
        }
        
        return lines.joined(separator: "\n")
    }
}

extension If: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var lines: [String] = []
        
        let testCode = test.toPythonCode(context: context)
        lines.append(context.indent + "if \(testCode):")
        
        let bodyContext = context.indented()
        for stmt in body {
            lines.append(stmt.toPythonCode(context: bodyContext))
        }
        
        // Handle elif/else chains
        if !orElse.isEmpty {
            // Check if orElse is a single if statement (elif case)
            if orElse.count == 1, case .ifStmt(let elifStmt) = orElse[0] {
                // Recursively generate elif/else chain
                let elifCode = elifStmt.toPythonCode(context: context)
                // Replace "if" with "elif"
                let elifLines = elifCode.split(separator: "\n", omittingEmptySubsequences: false)
                for (index, line) in elifLines.enumerated() {
                    let lineStr = String(line)
                    if index == 0 && lineStr.trimmingCharacters(in: .whitespaces).hasPrefix("if ") {
                        let replaced = lineStr.replacingOccurrences(of: "if ", with: "elif ", options: [], range: lineStr.range(of: "if "))
                        lines.append(replaced)
                    } else {
                        lines.append(lineStr)
                    }
                }
            } else {
                // Regular else block
                lines.append(context.indent + "else:")
                for stmt in orElse {
                    lines.append(stmt.toPythonCode(context: bodyContext))
                }
            }
        }
        
        return lines.joined(separator: "\n")
    }
}

extension With: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        // TODO: Implement
        return context.indent + "# with statement"
    }
}

extension AsyncWith: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        // TODO: Implement
        return context.indent + "# async with statement"
    }
}

extension Match: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        // TODO: Implement
        return context.indent + "# match statement"
    }
}

extension Try: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        // TODO: Implement
        return context.indent + "# try statement"
    }
}

extension TryStar: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        // TODO: Implement
        return context.indent + "# try* statement"
    }
}

extension TypeAlias: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        // TODO: Implement
        return context.indent + "# type alias"
    }
}

extension Import: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        let names = names.map { alias in
            if let asName = alias.asName {
                return "\(alias.name) as \(asName)"
            } else {
                return alias.name
            }
        }.joined(separator: ", ")
        
        return context.indent + "import " + names
    }
}

extension ImportFrom: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        var code = context.indent + "from "
        
        // Handle relative imports
        if level > 0 {
            code += String(repeating: ".", count: level)
        }
        
        if let mod = module {
            code += mod
        }
        
        code += " import "
        
        let nameList = names.map { alias in
            if let asName = alias.asName {
                return "\(alias.name) as \(asName)"
            } else {
                return alias.name
            }
        }.joined(separator: ", ")
        
        code += nameList
        
        return code
    }
}

// Placeholder for Break and Continue
extension Break: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        return context.indent + "break"
    }
}

extension Continue: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        return context.indent + "continue"
    }
}
