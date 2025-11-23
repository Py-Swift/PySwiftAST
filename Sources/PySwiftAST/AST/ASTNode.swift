/// Base protocol for all AST nodes
public protocol ASTNode {
    var lineno: Int { get }
    var colOffset: Int { get }
    var endLineno: Int? { get }
    var endColOffset: Int? { get }
}

/// Protocol for displaying AST nodes as a tree structure
public protocol TreeDisplayable {
    func treeLines(indent: String, isLast: Bool) -> [String]
}

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
