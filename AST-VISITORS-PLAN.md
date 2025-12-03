Create ast vistor concept

# new target called PyAstVisitors

# Core visitor protocol:
```swift
public protocol ASTVisitor {
    // Statements
    func visit(_ node: FunctionDef)
    func visit(_ node: ClassDef)
    func visit(_ node: Assign)
    func visit(_ node: AnnAssign)
    func visit(_ node: If)
    func visit(_ node: For)
    func visit(_ node: While)
    func visit(_ node: With)
    // ... etc
    
    // Expressions
    func visit(_ node: Name)
    func visit(_ node: Constant)
    func visit(_ node: Attribute)
    func visit(_ node: Call)
    // ... etc
}
```

# With automatic traversal:
```swift
extension Module {
    func accept<V: ASTVisitor>(visitor: V) {
        for statement in body {
            statement.accept(visitor: visitor)
        }
    }
}


extension Statement {
    func accept<V: ASTVisitor>(visitor: V) {
        switch self {
        case .functionDef(let node):
            visitor.visit(node)
            for stmt in node.body {
                stmt.accept(visitor: visitor)  // auto-recurse
            }
        case .classDef(let node):
            visitor.visit(node)
            for stmt in node.body {
                stmt.accept(visitor: visitor)  // auto-recurse
            }
        case .assign(let node):
            visitor.visit(node)
        // ... etc
        }
    }
}
```

# This would let user to write:
```swift
class VariableFinder: ASTVisitor {
    let target: String
    var foundType: String?
    
    func visit(_ node: Assign) {
        // Only care about assigns, automatically called for all assigns in tree
    }
}
```
