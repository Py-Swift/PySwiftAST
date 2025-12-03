import PySwiftAST

// MARK: - Expression Accept

extension Expression {
    /// Accept a visitor to traverse this expression and its children
    public func accept<V: ASTVisitor>(visitor: V) {
        switch self {
        case .boolOp(let node):
            visitor.visit(node)
            for value in node.values {
                value.accept(visitor: visitor)
            }
            
        case .namedExpr(let node):
            visitor.visit(node)
            node.target.accept(visitor: visitor)
            node.value.accept(visitor: visitor)
            
        case .binOp(let node):
            visitor.visit(node)
            node.left.accept(visitor: visitor)
            node.right.accept(visitor: visitor)
            
        case .unaryOp(let node):
            visitor.visit(node)
            node.operand.accept(visitor: visitor)
            
        case .lambda(let node):
            visitor.visit(node)
            // Visit default argument values
            for defaultArg in node.args.defaults {
                defaultArg.accept(visitor: visitor)
            }
            for defaultArg in node.args.kwDefaults {
                defaultArg?.accept(visitor: visitor)
            }
            node.body.accept(visitor: visitor)
            
        case .ifExp(let node):
            visitor.visit(node)
            node.test.accept(visitor: visitor)
            node.body.accept(visitor: visitor)
            node.orElse.accept(visitor: visitor)
            
        case .dict(let node):
            visitor.visit(node)
            for key in node.keys {
                key?.accept(visitor: visitor)
            }
            for value in node.values {
                value.accept(visitor: visitor)
            }
            
        case .set(let node):
            visitor.visit(node)
            for element in node.elts {
                element.accept(visitor: visitor)
            }
            
        case .listComp(let node):
            visitor.visit(node)
            node.elt.accept(visitor: visitor)
            for generator in node.generators {
                generator.target.accept(visitor: visitor)
                generator.iter.accept(visitor: visitor)
                for condition in generator.ifs {
                    condition.accept(visitor: visitor)
                }
            }
            
        case .setComp(let node):
            visitor.visit(node)
            node.elt.accept(visitor: visitor)
            for generator in node.generators {
                generator.target.accept(visitor: visitor)
                generator.iter.accept(visitor: visitor)
                for condition in generator.ifs {
                    condition.accept(visitor: visitor)
                }
            }
            
        case .dictComp(let node):
            visitor.visit(node)
            node.key.accept(visitor: visitor)
            node.value.accept(visitor: visitor)
            for generator in node.generators {
                generator.target.accept(visitor: visitor)
                generator.iter.accept(visitor: visitor)
                for condition in generator.ifs {
                    condition.accept(visitor: visitor)
                }
            }
            
        case .generatorExp(let node):
            visitor.visit(node)
            node.elt.accept(visitor: visitor)
            for generator in node.generators {
                generator.target.accept(visitor: visitor)
                generator.iter.accept(visitor: visitor)
                for condition in generator.ifs {
                    condition.accept(visitor: visitor)
                }
            }
            
        case .await(let node):
            visitor.visit(node)
            node.value.accept(visitor: visitor)
            
        case .yield(let node):
            visitor.visit(node)
            node.value?.accept(visitor: visitor)
            
        case .yieldFrom(let node):
            visitor.visit(node)
            node.value.accept(visitor: visitor)
            
        case .compare(let node):
            visitor.visit(node)
            node.left.accept(visitor: visitor)
            for comparator in node.comparators {
                comparator.accept(visitor: visitor)
            }
            
        case .call(let node):
            visitor.visit(node)
            node.fun.accept(visitor: visitor)
            for arg in node.args {
                arg.accept(visitor: visitor)
            }
            for keyword in node.keywords {
                keyword.value.accept(visitor: visitor)
            }
            
        case .formattedValue(let node):
            visitor.visit(node)
            node.value.accept(visitor: visitor)
            node.formatSpec?.accept(visitor: visitor)
            
        case .joinedStr(let node):
            visitor.visit(node)
            for value in node.values {
                value.accept(visitor: visitor)
            }
            
        case .constant(let node):
            visitor.visit(node)
            
        case .attribute(let node):
            visitor.visit(node)
            node.value.accept(visitor: visitor)
            
        case .subscriptExpr(let node):
            visitor.visit(node)
            node.value.accept(visitor: visitor)
            node.slice.accept(visitor: visitor)
            
        case .starred(let node):
            visitor.visit(node)
            node.value.accept(visitor: visitor)
            
        case .name(let node):
            visitor.visit(node)
            
        case .list(let node):
            visitor.visit(node)
            for element in node.elts {
                element.accept(visitor: visitor)
            }
            
        case .tuple(let node):
            visitor.visit(node)
            for element in node.elts {
                element.accept(visitor: visitor)
            }
            
        case .slice(let node):
            visitor.visit(node)
            node.lower?.accept(visitor: visitor)
            node.upper?.accept(visitor: visitor)
            node.step?.accept(visitor: visitor)
        }
    }
}

// MARK: - Pattern Accept

extension Pattern {
    /// Accept a visitor to traverse this pattern
    public func accept<V: ASTVisitor>(visitor: V) {
        switch self {
        case .matchValue(let pattern):
            pattern.value.accept(visitor: visitor)
        case .matchSingleton:
            break
        case .matchSequence(let pattern):
            for subPattern in pattern.patterns {
                subPattern.accept(visitor: visitor)
            }
        case .matchMapping(let pattern):
            for key in pattern.keys {
                key.accept(visitor: visitor)
            }
            for subPattern in pattern.patterns {
                subPattern.accept(visitor: visitor)
            }
        case .matchClass(let pattern):
            pattern.cls.accept(visitor: visitor)
            for subPattern in pattern.patterns {
                subPattern.accept(visitor: visitor)
            }
        case .matchStar:
            break
        case .matchAs:
            break
        case .matchOr(let pattern):
            for subPattern in pattern.patterns {
                subPattern.accept(visitor: visitor)
            }
        }
    }
}
