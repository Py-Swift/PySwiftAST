import PySwiftAST

// MARK: - Operators

extension Operator: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        switch self {
        case .add: return "+"
        case .sub: return "-"
        case .mult: return "*"
        case .matMult: return "@"
        case .div: return "/"
        case .mod: return "%"
        case .pow: return "**"
        case .lShift: return "<<"
        case .rShift: return ">>"
        case .bitOr: return "|"
        case .bitXor: return "^"
        case .bitAnd: return "&"
        case .floorDiv: return "//"
        }
    }
}

extension UnaryOperator: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        switch self {
        case .invert: return "~"
        case .not: return "not "
        case .uAdd: return "+"
        case .uSub: return "-"
        }
    }
}

extension BoolOperator: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        switch self {
        case .and: return "and"
        case .or: return "or"
        }
    }
}

extension CmpOp: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        switch self {
        case .eq: return "=="
        case .notEq: return "!="
        case .lt: return "<"
        case .ltE: return "<="
        case .gt: return ">"
        case .gtE: return ">="
        case .is: return "is"
        case .isNot: return "is not"
        case .in: return "in"
        case .notIn: return "not in"
        }
    }
}
