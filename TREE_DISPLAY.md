# TreeDisplayable Protocol

The PySwiftAST library now uses a protocol-oriented design for tree display. All AST nodes conform to the `TreeDisplayable` protocol.

## Protocol Definition

```swift
/// Protocol for displaying AST nodes as a tree structure
public protocol TreeDisplayable {
    func treeLines(indent: String, isLast: Bool) -> [String]
}
```

## TreeDisplay Helper

```swift
/// Helper for building tree display strings
public struct TreeDisplay {
    public static let verticalLine = "│   "
    public static let branch = "├── "
    public static let lastBranch = "└── "
    public static let space = "    "
    
    public static func childIndent(for parentIndent: String, isLast: Bool) -> String {
        return parentIndent + (isLast ? space : verticalLine)
    }
}
```

## Conformance

All major AST types conform to `TreeDisplayable`:

- `Module` - Top-level module types
- `Statement` - All statement types (assignments, control flow, etc.)
- `Expression` - All expression types (names, operators, literals, etc.)

## Usage Examples

### Basic Usage

```swift
let module = try parsePython("x = 1\ny = 2")
let tree = displayAST(module)
print(tree)
```

Output:
```
Module
├── Assign
│   ├── Targets: 1
│   │   ├── Name: x
│   └── Value:
│       └── Constant: 1
└── Assign
    ├── Targets: 1
    │   ├── Name: y
    └── Value:
        └── Constant: 2
```

### Using the Protocol Directly

```swift
let module = try parsePython("def foo(): pass")

// Use the protocol method directly
let lines = module.treeLines(indent: "", isLast: true)
let treeString = lines.joined(separator: "\n")
print(treeString)
```

Output:
```
Module
└── FunctionDef: foo
    └── Body: 1 statements
        └── Pass
```

### Custom Tree Display

You can also use the `TreeDisplay` helper to build custom displays:

```swift
extension MyCustomType: TreeDisplayable {
    public func treeLines(indent: String, isLast: Bool) -> [String] {
        let connector = isLast ? TreeDisplay.lastBranch : TreeDisplay.branch
        let childIndent = TreeDisplay.childIndent(for: indent, isLast: isLast)
        
        var lines: [String] = []
        lines.append(indent + connector + "MyCustomType")
        
        for (index, child) in children.enumerated() {
            let childIsLast = index == children.count - 1
            let childLines = child.treeLines(indent: childIndent, isLast: childIsLast)
            lines.append(contentsOf: childLines)
        }
        
        return lines
    }
}
```

## Benefits

1. **Protocol-Oriented Design** - More Swift-like and extensible
2. **Composable** - Each node knows how to display itself
3. **Consistent** - All nodes use the same display logic
4. **Testable** - Easy to test tree output for individual nodes
5. **Extensible** - Easy to add custom display logic for new node types

## Tree Display Characters

The tree uses Unicode box-drawing characters:

- `├──` - Branch (non-last child)
- `└──` - Last branch (last child)
- `│   ` - Vertical line (continuation)
- `    ` - Space (indentation for last children)

This creates clear, readable tree structures that show the hierarchical relationship between AST nodes.
