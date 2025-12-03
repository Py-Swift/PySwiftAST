import Foundation
import PySwiftAST

/// PyAstVisitors - Visitor pattern for Python AST traversal
///
/// This module provides the visitor pattern implementation for traversing
/// and analyzing Python AST structures.
///
/// Version: 1.0.0
public struct PyAstVisitors {
    public static let version = "1.0.0"
}

// MARK: - ASTVisitor Protocol

/// Protocol for visiting AST nodes.
/// Implement this protocol to traverse and process Python AST.
/// All methods have default no-op implementations, so you only override what you need.
public protocol ASTVisitor {
    // MARK: Statement Visitors
    
    func visit(_ node: FunctionDef)
    func visit(_ node: AsyncFunctionDef)
    func visit(_ node: ClassDef)
    func visit(_ node: Return)
    func visit(_ node: Delete)
    func visit(_ node: Assign)
    func visit(_ node: AugAssign)
    func visit(_ node: AnnAssign)
    func visit(_ node: For)
    func visit(_ node: AsyncFor)
    func visit(_ node: While)
    func visit(_ node: If)
    func visit(_ node: With)
    func visit(_ node: AsyncWith)
    func visit(_ node: Match)
    func visit(_ node: Raise)
    func visit(_ node: Try)
    func visit(_ node: TryStar)
    func visit(_ node: Assert)
    func visit(_ node: Import)
    func visit(_ node: ImportFrom)
    func visit(_ node: Global)
    func visit(_ node: Nonlocal)
    func visit(_ node: Expr)
    func visit(_ node: Pass)
    func visit(_ node: Break)
    func visit(_ node: Continue)
    func visit(_ node: Blank)
    func visit(_ node: TypeAlias)
    
    // MARK: Expression Visitors
    
    func visit(_ node: BoolOp)
    func visit(_ node: NamedExpr)
    func visit(_ node: BinOp)
    func visit(_ node: UnaryOp)
    func visit(_ node: Lambda)
    func visit(_ node: IfExp)
    func visit(_ node: Dict)
    func visit(_ node: Set)
    func visit(_ node: ListComp)
    func visit(_ node: SetComp)
    func visit(_ node: DictComp)
    func visit(_ node: GeneratorExp)
    func visit(_ node: Await)
    func visit(_ node: Yield)
    func visit(_ node: YieldFrom)
    func visit(_ node: Compare)
    func visit(_ node: Call)
    func visit(_ node: FormattedValue)
    func visit(_ node: JoinedStr)
    func visit(_ node: Constant)
    func visit(_ node: Attribute)
    func visit(_ node: Subscript)
    func visit(_ node: Starred)
    func visit(_ node: Name)
    func visit(_ node: List)
    func visit(_ node: Tuple)
    func visit(_ node: Slice)
}

// MARK: - Default Implementations

extension ASTVisitor {
    // MARK: Statement Defaults
    
    public func visit(_ node: FunctionDef) {}
    public func visit(_ node: AsyncFunctionDef) {}
    public func visit(_ node: ClassDef) {}
    public func visit(_ node: Return) {}
    public func visit(_ node: Delete) {}
    public func visit(_ node: Assign) {}
    public func visit(_ node: AugAssign) {}
    public func visit(_ node: AnnAssign) {}
    public func visit(_ node: For) {}
    public func visit(_ node: AsyncFor) {}
    public func visit(_ node: While) {}
    public func visit(_ node: If) {}
    public func visit(_ node: With) {}
    public func visit(_ node: AsyncWith) {}
    public func visit(_ node: Match) {}
    public func visit(_ node: Raise) {}
    public func visit(_ node: Try) {}
    public func visit(_ node: TryStar) {}
    public func visit(_ node: Assert) {}
    public func visit(_ node: Import) {}
    public func visit(_ node: ImportFrom) {}
    public func visit(_ node: Global) {}
    public func visit(_ node: Nonlocal) {}
    public func visit(_ node: Expr) {}
    public func visit(_ node: Pass) {}
    public func visit(_ node: Break) {}
    public func visit(_ node: Continue) {}
    public func visit(_ node: Blank) {}
    public func visit(_ node: TypeAlias) {}
    
    // MARK: Expression Defaults
    
    public func visit(_ node: BoolOp) {}
    public func visit(_ node: NamedExpr) {}
    public func visit(_ node: BinOp) {}
    public func visit(_ node: UnaryOp) {}
    public func visit(_ node: Lambda) {}
    public func visit(_ node: IfExp) {}
    public func visit(_ node: Dict) {}
    public func visit(_ node: Set) {}
    public func visit(_ node: ListComp) {}
    public func visit(_ node: SetComp) {}
    public func visit(_ node: DictComp) {}
    public func visit(_ node: GeneratorExp) {}
    public func visit(_ node: Await) {}
    public func visit(_ node: Yield) {}
    public func visit(_ node: YieldFrom) {}
    public func visit(_ node: Compare) {}
    public func visit(_ node: Call) {}
    public func visit(_ node: FormattedValue) {}
    public func visit(_ node: JoinedStr) {}
    public func visit(_ node: Constant) {}
    public func visit(_ node: Attribute) {}
    public func visit(_ node: Subscript) {}
    public func visit(_ node: Starred) {}
    public func visit(_ node: Name) {}
    public func visit(_ node: List) {}
    public func visit(_ node: Tuple) {}
    public func visit(_ node: Slice) {}
}
