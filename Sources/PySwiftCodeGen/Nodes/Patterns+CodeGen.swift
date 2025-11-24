import PySwiftAST

// MARK: - Pattern Code Generation

extension Pattern {
    public func toPythonCode(context: CodeGenContext) -> String {
        switch self {
        case .matchValue(let matchValue):
            return matchValue.value.toPythonCode(context: context)
            
        case .matchSingleton(let singleton):
            switch singleton.value {
            case .none:
                return "None"
            case .bool(let b):
                return b ? "True" : "False"
            default:
                return "..."
            }
            
        case .matchSequence(let sequence):
            let patterns = sequence.patterns.map { $0.toPythonCode(context: context) }
            return "[\(patterns.joined(separator: ", "))]"
            
        case .matchMapping(let mapping):
            var parts: [String] = []
            for (key, pattern) in zip(mapping.keys, mapping.patterns) {
                let keyStr = key.toPythonCode(context: context)
                let patternStr = pattern.toPythonCode(context: context)
                parts.append("\(keyStr): \(patternStr)")
            }
            if let rest = mapping.rest {
                parts.append("**\(rest)")
            }
            return "{\(parts.joined(separator: ", "))}"
            
        case .matchClass(let matchClass):
            var code = matchClass.cls.toPythonCode(context: context)
            
            var args: [String] = []
            args.append(contentsOf: matchClass.patterns.map { $0.toPythonCode(context: context) })
            
            for (attr, pattern) in zip(matchClass.kwdAttrs, matchClass.kwdPatterns) {
                args.append("\(attr)=\(pattern.toPythonCode(context: context))")
            }
            
            code += "(\(args.joined(separator: ", ")))"
            return code
            
        case .matchStar(let star):
            if let name = star.name {
                return "*\(name)"
            }
            return "*_"
            
        case .matchAs(let matchAs):
            if let pattern = matchAs.pattern, let name = matchAs.name {
                return "\(pattern.toPythonCode(context: context)) as \(name)"
            } else if let name = matchAs.name {
                return name
            } else if let pattern = matchAs.pattern {
                return pattern.toPythonCode(context: context)
            }
            return "_"
            
        case .matchOr(let matchOr):
            let patterns = matchOr.patterns.map { $0.toPythonCode(context: context) }
            return patterns.joined(separator: " | ")
        }
    }
}
