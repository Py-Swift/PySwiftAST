import Foundation

/// Utility for displaying AST as a tree (deprecated - use TreeDisplayable protocol instead)
public struct ASTTreeDisplay {
    
    /// Display a module as a tree
    public static func display(_ module: Module) -> String {
        return module.treeLines(indent: "", isLast: true).joined(separator: "\n")
    }
}
