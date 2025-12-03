# PyAstVisitors

Visitor pattern implementation for traversing Python AST structures.

## Overview

PyAstVisitors provides a clean, extensible visitor pattern for working with Python AST. The visitor pattern allows you to traverse the entire AST tree automatically while selectively overriding only the node types you care about.

## Features

- **Automatic Traversal**: The `accept()` methods automatically traverse child nodes
- **Selective Override**: Only implement `visit()` methods for nodes you care about
- **Type-Safe**: Strong typing ensures you handle all cases correctly
- **Zero Overhead**: Default implementations are no-ops

## Usage

### Basic Example

```swift
import PySwiftAST
import PyAstVisitors

// Create a visitor that counts function definitions
class FunctionCounter: ASTVisitor {
    var count = 0
    
    func visit(_ node: FunctionDef) {
        count += 1
    }
}

// Parse Python code
let parser = Parser()
let module = try parser.parse(source: pythonCode)

// Visit the AST
let counter = FunctionCounter()
module.accept(visitor: counter)

print("Found \(counter.count) functions")
```

### Collecting Variables

```swift
class VariableFinder: ASTVisitor {
    var variables: [String] = []
    
    func visit(_ node: Assign) {
        for target in node.targets {
            if case .name(let nameNode) = target {
                variables.append(nameNode.id)
            }
        }
    }
}

let finder = VariableFinder()
module.accept(visitor: finder)
print("Variables: \(finder.variables)")
```

### Finding Imports

```swift
class ImportCollector: ASTVisitor {
    var imports: Swift.Set<String> = []
    
    func visit(_ node: Import) {
        for alias in node.names {
            imports.insert(alias.name)
        }
    }
    
    func visit(_ node: ImportFrom) {
        if let module = node.module {
            for alias in node.names {
                imports.insert("\(module).\(alias.name)")
            }
        }
    }
}

let collector = ImportCollector()
module.accept(visitor: collector)
print("Imports: \(collector.imports)")
```

## How It Works

The visitor pattern consists of three parts:

1. **ASTVisitor Protocol**: Defines `visit()` methods for all AST node types
2. **Default Implementations**: All methods have no-op defaults so you only override what you need
3. **Accept Methods**: Extensions on `Module`, `Statement`, and `Expression` that call the visitor and recursively traverse children

### Traversal Order

The visitor performs a depth-first traversal:

1. Visit the node with the appropriate `visit()` method
2. Visit child expressions (e.g., test conditions, values)
3. Recursively visit child statements (e.g., function bodies, if blocks)

### Example: If Statement Traversal

When visiting an `If` statement:

```swift
case .ifStmt(let node):
    visitor.visit(node)           // 1. Visit the if node
    node.test.accept(visitor: visitor)  // 2. Visit the condition
    for stmt in node.body {              // 3. Visit the body
        stmt.accept(visitor: visitor)
    }
    for stmt in node.orElse {            // 4. Visit the else block
        stmt.accept(visitor: visitor)
    }
```

## Example Visitors Included

The module includes several example visitors:

- **VariableFinder**: Collects all variable assignments
- **DefinitionCounter**: Counts functions, classes, and async functions
- **ImportCollector**: Collects all import statements
- **NameCollector**: Collects all name references
- **CallFinder**: Finds all function calls

## Integration

PyAstVisitors works seamlessly with other PySwift modules:

```swift
import PySwiftAST
import PySwiftCodeGen
import PyAstVisitors

// Parse Python code
let parser = Parser()
let module = try parser.parse(source: code)

// Analyze with visitor
let analyzer = MyAnalyzer()
module.accept(visitor: analyzer)

// Generate code back
let generator = PyCodeGenerator()
let result = generator.generate(module: module)
```

## Implementation Details

### Visitor Protocol

All visitor methods are defined in the `ASTVisitor` protocol with default no-op implementations:

```swift
public protocol ASTVisitor {
    func visit(_ node: FunctionDef)
    func visit(_ node: ClassDef)
    func visit(_ node: Assign)
    // ... all other node types
}

extension ASTVisitor {
    public func visit(_ node: FunctionDef) {}  // Default no-op
    // ... all other defaults
}
```

### Accept Extensions

Extensions on AST types provide the `accept()` method:

```swift
extension Statement {
    public func accept<V: ASTVisitor>(visitor: V) {
        // Switch on statement type and handle traversal
    }
}

extension Expression {
    public func accept<V: ASTVisitor>(visitor: V) {
        // Switch on expression type and handle traversal
    }
}
```

## Performance

The visitor pattern has minimal overhead:

- No dynamic dispatch for visitor methods (protocol witnesses are optimized)
- Default implementations are inlined as no-ops
- Traversal is a simple depth-first walk with no allocations

## Requirements

- Swift 6.0+
- PySwiftAST 1.0+

## License

Same as PySwiftAST project.
