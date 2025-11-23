import PySwiftAST

/// Code generation for Expression enum
extension Expression: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        switch self {
        case .boolOp(let op):
            return op.toPythonCode(context: context)
        case .namedExpr(let named):
            return named.toPythonCode(context: context)
        case .binOp(let op):
            return op.toPythonCode(context: context)
        case .unaryOp(let op):
            return op.toPythonCode(context: context)
        case .lambda(let lambda):
            return lambda.toPythonCode(context: context)
        case .ifExp(let ifExp):
            return ifExp.toPythonCode(context: context)
        case .dict(let dict):
            return dict.toPythonCode(context: context)
        case .set(let set):
            return set.toPythonCode(context: context)
        case .listComp(let comp):
            return comp.toPythonCode(context: context)
        case .setComp(let comp):
            return comp.toPythonCode(context: context)
        case .dictComp(let comp):
            return comp.toPythonCode(context: context)
        case .generatorExp(let gen):
            return gen.toPythonCode(context: context)
        case .await(let awaitExpr):
            return awaitExpr.toPythonCode(context: context)
        case .yield(let yield):
            return yield.toPythonCode(context: context)
        case .yieldFrom(let yieldFrom):
            return yieldFrom.toPythonCode(context: context)
        case .compare(let compare):
            return compare.toPythonCode(context: context)
        case .call(let call):
            return call.toPythonCode(context: context)
        case .formattedValue(let formatted):
            return formatted.toPythonCode(context: context)
        case .joinedStr(let joined):
            return joined.toPythonCode(context: context)
        case .constant(let constant):
            return constant.toPythonCode(context: context)
        case .attribute(let attr):
            return attr.toPythonCode(context: context)
        case .subscriptExpr(let sub):
            return sub.toPythonCode(context: context)
        case .starred(let starred):
            return starred.toPythonCode(context: context)
        case .name(let name):
            return name.toPythonCode(context: context)
        case .list(let list):
            return list.toPythonCode(context: context)
        case .tuple(let tuple):
            return tuple.toPythonCode(context: context)
        case .slice(let slice):
            return slice.toPythonCode(context: context)
        }
    }
}
