import PySwiftAST

// MARK: - Module Accept

extension Module {
    /// Accept a visitor to traverse this module
    public func accept<V: ASTVisitor>(visitor: V) {
        switch self {
        case .module(let statements):
            for statement in statements {
                statement.accept(visitor: visitor)
            }
        case .interactive(let statements):
            for statement in statements {
                statement.accept(visitor: visitor)
            }
        case .expression(let expr):
            expr.accept(visitor: visitor)
        case .functionType(let argTypes, let returnType):
            for argType in argTypes {
                argType.accept(visitor: visitor)
            }
            returnType.accept(visitor: visitor)
        }
    }
}
