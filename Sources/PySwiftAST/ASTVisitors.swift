import Foundation

/// Protocol for visiting statement nodes in the Python AST
///
/// Implement this protocol to traverse and process statement nodes.
/// The visitor pattern separates tree traversal from node-specific logic.
public protocol StatementVisitor {
    associatedtype StatementResult
    
    // Simple statements
    func visitAssign(_ node: Assign) -> StatementResult
    func visitAnnAssign(_ node: AnnAssign) -> StatementResult
    func visitAugAssign(_ node: AugAssign) -> StatementResult
    func visitAssertStmt(_ node: Assert) -> StatementResult
    func visitPass(_ node: Pass) -> StatementResult
    func visitDelete(_ node: Delete) -> StatementResult
    func visitReturn(_ node: Return) -> StatementResult
    func visitRaise(_ node: Raise) -> StatementResult
    func visitBreakStmt(_ node: Break) -> StatementResult
    func visitContinueStmt(_ node: Continue) -> StatementResult
    func visitImportStmt(_ node: Import) -> StatementResult
    func visitImportFrom(_ node: ImportFrom) -> StatementResult
    func visitGlobal(_ node: Global) -> StatementResult
    func visitNonlocal(_ node: Nonlocal) -> StatementResult
    func visitExpr(_ node: Expr) -> StatementResult
    func visitBlank(_ node: Blank) -> StatementResult
    
    // Compound statements
    func visitIf(_ node: If) -> StatementResult
    func visitWhile(_ node: While) -> StatementResult
    func visitFor(_ node: For) -> StatementResult
    func visitWith(_ node: With) -> StatementResult
    func visitTry(_ node: Try) -> StatementResult
    func visitTryStar(_ node: TryStar) -> StatementResult
    func visitFunctionDef(_ node: FunctionDef) -> StatementResult
    func visitAsyncFunctionDef(_ node: AsyncFunctionDef) -> StatementResult
    func visitClassDef(_ node: ClassDef) -> StatementResult
    func visitMatch(_ node: Match) -> StatementResult
    func visitAsyncFor(_ node: AsyncFor) -> StatementResult
    func visitAsyncWith(_ node: AsyncWith) -> StatementResult
    func visitTypeAlias(_ node: TypeAlias) -> StatementResult
}

/// Protocol for visiting expression nodes in the Python AST
///
/// Implement this protocol to traverse and process expression nodes.
/// The visitor pattern separates tree traversal from node-specific logic.
public protocol ExpressionVisitor {
    associatedtype ExpressionResult
    
    // Literals
    func visitConstant(_ node: Constant) -> ExpressionResult
    func visitList(_ node: List) -> ExpressionResult
    func visitTuple(_ node: Tuple) -> ExpressionResult
    func visitDict(_ node: Dict) -> ExpressionResult
    func visitSet(_ node: Set) -> ExpressionResult
    
    // Variables and attributes
    func visitName(_ node: Name) -> ExpressionResult
    func visitAttribute(_ node: Attribute) -> ExpressionResult
    func visitSubscript(_ node: Subscript) -> ExpressionResult
    func visitStarred(_ node: Starred) -> ExpressionResult
    
    // Operations
    func visitBinOp(_ node: BinOp) -> ExpressionResult
    func visitUnaryOp(_ node: UnaryOp) -> ExpressionResult
    func visitBoolOp(_ node: BoolOp) -> ExpressionResult
    func visitCompare(_ node: Compare) -> ExpressionResult
    
    // Function and lambda
    func visitCall(_ node: Call) -> ExpressionResult
    func visitLambda(_ node: Lambda) -> ExpressionResult
    
    // Comprehensions
    func visitListComp(_ node: ListComp) -> ExpressionResult
    func visitSetComp(_ node: SetComp) -> ExpressionResult
    func visitDictComp(_ node: DictComp) -> ExpressionResult
    func visitGeneratorExp(_ node: GeneratorExp) -> ExpressionResult
    
    // Other expressions
    func visitIfExp(_ node: IfExp) -> ExpressionResult
    func visitNamedExpr(_ node: NamedExpr) -> ExpressionResult
    func visitYield(_ node: Yield) -> ExpressionResult
    func visitYieldFrom(_ node: YieldFrom) -> ExpressionResult
    func visitAwait(_ node: Await) -> ExpressionResult
    func visitFormattedValue(_ node: FormattedValue) -> ExpressionResult
    func visitJoinedStr(_ node: JoinedStr) -> ExpressionResult
    func visitSlice(_ node: Slice) -> ExpressionResult
}

/// Extension to provide default implementations for statement visitors
public extension StatementVisitor {
    func visitStatement(_ stmt: Statement) -> StatementResult {
        switch stmt {
        case .assign(let node): return visitAssign(node)
        case .annAssign(let node): return visitAnnAssign(node)
        case .augAssign(let node): return visitAugAssign(node)
        case .assertStmt(let node): return visitAssertStmt(node)
        case .pass(let node): return visitPass(node)
        case .delete(let node): return visitDelete(node)
        case .returnStmt(let node): return visitReturn(node)
        case .raise(let node): return visitRaise(node)
        case .breakStmt(let node): return visitBreakStmt(node)
        case .continueStmt(let node): return visitContinueStmt(node)
        case .importStmt(let node): return visitImportStmt(node)
        case .importFrom(let node): return visitImportFrom(node)
        case .global(let node): return visitGlobal(node)
        case .nonlocal(let node): return visitNonlocal(node)
        case .expr(let node): return visitExpr(node)
        case .blank(let node): return visitBlank(node)
        case .ifStmt(let node): return visitIf(node)
        case .whileStmt(let node): return visitWhile(node)
        case .forStmt(let node): return visitFor(node)
        case .withStmt(let node): return visitWith(node)
        case .tryStmt(let node): return visitTry(node)
        case .tryStar(let node): return visitTryStar(node)
        case .functionDef(let node): return visitFunctionDef(node)
        case .asyncFunctionDef(let node): return visitAsyncFunctionDef(node)
        case .classDef(let node): return visitClassDef(node)
        case .match(let node): return visitMatch(node)
        case .asyncFor(let node): return visitAsyncFor(node)
        case .asyncWith(let node): return visitAsyncWith(node)
        case .typeAlias(let node): return visitTypeAlias(node)
        }
    }
}

/// Extension to provide default implementations for expression visitors
public extension ExpressionVisitor {
    func visitExpression(_ expr: Expression) -> ExpressionResult {
        switch expr {
        case .constant(let node): return visitConstant(node)
        case .list(let node): return visitList(node)
        case .tuple(let node): return visitTuple(node)
        case .dict(let node): return visitDict(node)
        case .set(let node): return visitSet(node)
        case .name(let node): return visitName(node)
        case .attribute(let node): return visitAttribute(node)
        case .subscriptExpr(let node): return visitSubscript(node)
        case .starred(let node): return visitStarred(node)
        case .binOp(let node): return visitBinOp(node)
        case .unaryOp(let node): return visitUnaryOp(node)
        case .boolOp(let node): return visitBoolOp(node)
        case .compare(let node): return visitCompare(node)
        case .call(let node): return visitCall(node)
        case .lambda(let node): return visitLambda(node)
        case .listComp(let node): return visitListComp(node)
        case .setComp(let node): return visitSetComp(node)
        case .dictComp(let node): return visitDictComp(node)
        case .generatorExp(let node): return visitGeneratorExp(node)
        case .ifExp(let node): return visitIfExp(node)
        case .namedExpr(let node): return visitNamedExpr(node)
        case .yield(let node): return visitYield(node)
        case .yieldFrom(let node): return visitYieldFrom(node)
        case .await(let node): return visitAwait(node)
        case .formattedValue(let node): return visitFormattedValue(node)
        case .joinedStr(let node): return visitJoinedStr(node)
        case .slice(let node): return visitSlice(node)
        }
    }
}
