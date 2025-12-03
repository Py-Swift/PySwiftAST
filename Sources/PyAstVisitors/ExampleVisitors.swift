import PySwiftAST

// MARK: - Example Visitor: Variable Finder

/// Example visitor that finds all variable assignments
public class VariableFinder: ASTVisitor {
    /// Variables found with their assigned values
    public private(set) var variables: [String: String] = [:]
    
    public init() {}
    
    /// Visit assignment statements to collect variable names
    public func visit(_ node: Assign) {
        // Extract variable names from targets
        for target in node.targets {
            if case .name(let nameNode) = target {
                variables[nameNode.id] = "assigned"
            }
        }
    }
    
    /// Visit annotated assignments
    public func visit(_ node: AnnAssign) {
        if case .name(let nameNode) = node.target {
            variables[nameNode.id] = "annotated"
        }
    }
    
    /// Visit augmented assignments (+=, -=, etc.)
    public func visit(_ node: AugAssign) {
        if case .name(let nameNode) = node.target {
            variables[nameNode.id] = "augmented"
        }
    }
}

// MARK: - Example Visitor: Function Counter

/// Example visitor that counts functions and classes
public class DefinitionCounter: ASTVisitor {
    public private(set) var functionCount = 0
    public private(set) var classCount = 0
    public private(set) var asyncFunctionCount = 0
    
    public init() {}
    
    public func visit(_ node: FunctionDef) {
        functionCount += 1
    }
    
    public func visit(_ node: AsyncFunctionDef) {
        asyncFunctionCount += 1
    }
    
    public func visit(_ node: ClassDef) {
        classCount += 1
    }
}

// MARK: - Example Visitor: Import Collector

/// Example visitor that collects all imports
public class ImportCollector: ASTVisitor {
    public private(set) var imports: Swift.Set<String> = []
    
    public init() {}
    
    public func visit(_ node: Import) {
        for alias in node.names {
            imports.insert(alias.name)
        }
    }
    
    public func visit(_ node: ImportFrom) {
        if let module = node.module {
            for alias in node.names {
                let fullName = "\(module).\(alias.name)"
                imports.insert(fullName)
            }
        }
    }
}

// MARK: - Example Visitor: Name Collector

/// Example visitor that collects all name references
public class NameCollector: ASTVisitor {
    public private(set) var names: [String] = []
    
    public init() {}
    
    public func visit(_ node: Name) {
        names.append(node.id)
    }
}

// MARK: - Example Visitor: Call Finder

/// Example visitor that finds all function calls
public class CallFinder: ASTVisitor {
    public private(set) var calls: [String] = []
    
    public init() {}
    
    public func visit(_ node: Call) {
        // Try to extract function name
        if case .name(let nameNode) = node.fun {
            calls.append(nameNode.id)
        } else if case .attribute(let attrNode) = node.fun {
            calls.append(attrNode.attr)
        }
    }
}
