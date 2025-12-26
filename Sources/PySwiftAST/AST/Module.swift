/// Python module types
public enum Module: Sendable {
    case module([Statement])
    case interactive([Statement])
    case expression(Expression)
    case functionType([Expression], Expression)

    public var body: [Statement] {
        switch self {
        case .module(let statements):
            return statements
        case .interactive(let statements):
            return statements
        case .expression(_):
            return []
        default:
            return []
        }
    }
}

// MARK: - TreeDisplayable Conformance
extension Module: TreeDisplayable {
    public func treeLines(indent: String, isLast: Bool) -> [String] {
        switch self {
        case .module(let statements):
            var lines = ["Module"]
            for (index, stmt) in statements.enumerated() {
                let stmtIsLast = index == statements.count - 1
                let stmtLines = stmt.treeLines(indent: "", isLast: stmtIsLast)
                lines.append(contentsOf: stmtLines)
            }
            return lines
            
        case .interactive(let statements):
            var lines = ["Interactive"]
            for (index, stmt) in statements.enumerated() {
                let stmtIsLast = index == statements.count - 1
                let stmtLines = stmt.treeLines(indent: "", isLast: stmtIsLast)
                lines.append(contentsOf: stmtLines)
            }
            return lines
            
        case .expression(let expr):
            var lines = ["Expression"]
            let exprLines = expr.treeLines(indent: "", isLast: true)
            lines.append(contentsOf: exprLines)
            return lines
            
        case .functionType(let argTypes, _):
            return ["FunctionType", "└── Arguments: \(argTypes.count)"]
        }
    }
}
