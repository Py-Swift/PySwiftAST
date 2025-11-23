import PySwiftAST

/// Code generation for Statement enum
extension Statement: PyCodeProtocol {
    public func toPythonCode(context: CodeGenContext) -> String {
        switch self {
        case .functionDef(let def):
            return def.toPythonCode(context: context)
        case .asyncFunctionDef(let def):
            return def.toPythonCode(context: context)
        case .classDef(let def):
            return def.toPythonCode(context: context)
        case .returnStmt(let ret):
            return ret.toPythonCode(context: context)
        case .delete(let del):
            return del.toPythonCode(context: context)
        case .assign(let assign):
            return assign.toPythonCode(context: context)
        case .augAssign(let aug):
            return aug.toPythonCode(context: context)
        case .annAssign(let ann):
            return ann.toPythonCode(context: context)
        case .forStmt(let forLoop):
            return forLoop.toPythonCode(context: context)
        case .asyncFor(let asyncFor):
            return asyncFor.toPythonCode(context: context)
        case .whileStmt(let whileLoop):
            return whileLoop.toPythonCode(context: context)
        case .ifStmt(let ifStmt):
            return ifStmt.toPythonCode(context: context)
        case .withStmt(let withStmt):
            return withStmt.toPythonCode(context: context)
        case .asyncWith(let asyncWith):
            return asyncWith.toPythonCode(context: context)
        case .match(let match):
            return match.toPythonCode(context: context)
        case .raise(let raise):
            return raise.toPythonCode(context: context)
        case .tryStmt(let tryStmt):
            return tryStmt.toPythonCode(context: context)
        case .tryStar(let tryStar):
            return tryStar.toPythonCode(context: context)
        case .assertStmt(let assert):
            return assert.toPythonCode(context: context)
        case .importStmt(let imp):
            return imp.toPythonCode(context: context)
        case .importFrom(let impFrom):
            return impFrom.toPythonCode(context: context)
        case .global(let global):
            return global.toPythonCode(context: context)
        case .nonlocal(let nonlocal):
            return nonlocal.toPythonCode(context: context)
        case .expr(let expr):
            return expr.toPythonCode(context: context)
        case .pass:
            return context.indent + "pass"
        case .breakStmt:
            return context.indent + "break"
        case .continueStmt:
            return context.indent + "continue"
        case .typeAlias(let typeAlias):
            return typeAlias.toPythonCode(context: context)
        }
    }
}
