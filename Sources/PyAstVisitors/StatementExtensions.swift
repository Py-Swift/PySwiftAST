import PySwiftAST

// MARK: - Statement Accept

extension Statement {
    /// Accept a visitor to traverse this statement and its children
    public func accept<V: ASTVisitor>(visitor: V) {
        switch self {
        case .functionDef(let node):
            visitor.visit(node)
            // Visit decorators
            for decorator in node.decoratorList {
                decorator.accept(visitor: visitor)
            }
            // Visit return type annotation
            node.returns?.accept(visitor: visitor)
            // Recurse into body
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            
        case .asyncFunctionDef(let node):
            visitor.visit(node)
            for decorator in node.decoratorList {
                decorator.accept(visitor: visitor)
            }
            node.returns?.accept(visitor: visitor)
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            
        case .classDef(let node):
            visitor.visit(node)
            // Visit base classes
            for base in node.bases {
                base.accept(visitor: visitor)
            }
            // Visit keywords (e.g., metaclass)
            for keyword in node.keywords {
                keyword.value.accept(visitor: visitor)
            }
            // Visit decorators
            for decorator in node.decoratorList {
                decorator.accept(visitor: visitor)
            }
            // Recurse into body
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            
        case .returnStmt(let node):
            visitor.visit(node)
            node.value?.accept(visitor: visitor)
            
        case .delete(let node):
            visitor.visit(node)
            for target in node.targets {
                target.accept(visitor: visitor)
            }
            
        case .assign(let node):
            visitor.visit(node)
            for target in node.targets {
                target.accept(visitor: visitor)
            }
            node.value.accept(visitor: visitor)
            
        case .augAssign(let node):
            visitor.visit(node)
            node.target.accept(visitor: visitor)
            node.value.accept(visitor: visitor)
            
        case .annAssign(let node):
            visitor.visit(node)
            node.target.accept(visitor: visitor)
            node.annotation.accept(visitor: visitor)
            node.value?.accept(visitor: visitor)
            
        case .forStmt(let node):
            visitor.visit(node)
            node.target.accept(visitor: visitor)
            node.iter.accept(visitor: visitor)
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            for stmt in node.orElse {
                stmt.accept(visitor: visitor)
            }
            
        case .asyncFor(let node):
            visitor.visit(node)
            node.target.accept(visitor: visitor)
            node.iter.accept(visitor: visitor)
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            for stmt in node.orElse {
                stmt.accept(visitor: visitor)
            }
            
        case .whileStmt(let node):
            visitor.visit(node)
            node.test.accept(visitor: visitor)
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            for stmt in node.orElse {
                stmt.accept(visitor: visitor)
            }
            
        case .ifStmt(let node):
            visitor.visit(node)
            node.test.accept(visitor: visitor)
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            for stmt in node.orElse {
                stmt.accept(visitor: visitor)
            }
            
        case .withStmt(let node):
            visitor.visit(node)
            for item in node.items {
                item.contextExpr.accept(visitor: visitor)
                item.optionalVars?.accept(visitor: visitor)
            }
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            
        case .asyncWith(let node):
            visitor.visit(node)
            for item in node.items {
                item.contextExpr.accept(visitor: visitor)
                item.optionalVars?.accept(visitor: visitor)
            }
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            
        case .match(let node):
            visitor.visit(node)
            node.subject.accept(visitor: visitor)
            for matchCase in node.cases {
                matchCase.pattern.accept(visitor: visitor)
                matchCase.guardExpr?.accept(visitor: visitor)
                for stmt in matchCase.body {
                    stmt.accept(visitor: visitor)
                }
            }
            
        case .raise(let node):
            visitor.visit(node)
            node.exc?.accept(visitor: visitor)
            node.cause?.accept(visitor: visitor)
            
        case .tryStmt(let node):
            visitor.visit(node)
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            for handler in node.handlers {
                handler.type?.accept(visitor: visitor)
                for stmt in handler.body {
                    stmt.accept(visitor: visitor)
                }
            }
            for stmt in node.orElse {
                stmt.accept(visitor: visitor)
            }
            for stmt in node.finalBody {
                stmt.accept(visitor: visitor)
            }
            
        case .tryStar(let node):
            visitor.visit(node)
            for stmt in node.body {
                stmt.accept(visitor: visitor)
            }
            for handler in node.handlers {
                handler.type?.accept(visitor: visitor)
                for stmt in handler.body {
                    stmt.accept(visitor: visitor)
                }
            }
            for stmt in node.orElse {
                stmt.accept(visitor: visitor)
            }
            for stmt in node.finalBody {
                stmt.accept(visitor: visitor)
            }
            
        case .assertStmt(let node):
            visitor.visit(node)
            node.test.accept(visitor: visitor)
            node.msg?.accept(visitor: visitor)
            
        case .importStmt(let node):
            visitor.visit(node)
            
        case .importFrom(let node):
            visitor.visit(node)
            
        case .global(let node):
            visitor.visit(node)
            
        case .nonlocal(let node):
            visitor.visit(node)
            
        case .expr(let node):
            visitor.visit(node)
            node.value.accept(visitor: visitor)
            
        case .pass(let node):
            visitor.visit(node)
            
        case .breakStmt(let node):
            visitor.visit(node)
            
        case .continueStmt(let node):
            visitor.visit(node)
            
        case .blank(let node):
            visitor.visit(node)
            
        case .typeAlias(let node):
            visitor.visit(node)
            node.value.accept(visitor: visitor)
        }
    }
}
