import PySwiftAST

/// Represents Python types for static type checking
public indirect enum PythonType: Sendable, Equatable {
    // Basic types
    case int
    case float
    case str
    case bool
    case bytes
    case none
    
    // Container types
    case list(PythonType)
    case dict(key: PythonType, value: PythonType)
    case set(PythonType)
    case tuple([PythonType])
    
    // Function type
    case function(parameters: [PythonType], returnType: PythonType)
    
    // Class/Instance type
    case classType(String)
    case instance(String)
    
    // Union type (for Optional, unions)
    case union([PythonType])
    
    // Generic/Any
    case any
    case unknown
    
    /// Create an optional type (Union[T, None])
    public static func optional(_ type: PythonType) -> PythonType {
        .union([type, .none])
    }
    
    /// Check if this type is optional (contains None in union)
    public var isOptional: Bool {
        if case .union(let types) = self {
            return types.contains(.none)
        }
        return self == .none
    }
    
    /// Get the non-None type from an optional
    public var unwrapOptional: PythonType? {
        if case .union(let types) = self {
            let nonNone = types.filter { $0 != .none }
            if nonNone.count == 1 {
                return nonNone[0]
            } else if nonNone.count > 1 {
                return .union(nonNone)
            }
        }
        return nil
    }
    
    /// Check if this type is compatible with another type
    public func isCompatible(with other: PythonType) -> Bool {
        // Exact match
        if self == other { return true }
        
        // Any type accepts everything
        if self == .any || other == .any { return true }
        
        // Unknown can be assigned from anything
        if self == .unknown || other == .unknown { return true }
        
        // None compatibility
        if other == .none {
            return self.isOptional
        }
        
        // Union compatibility
        if case .union(let types) = self {
            return types.contains(where: { $0.isCompatible(with: other) })
        }
        
        if case .union(let types) = other {
            return types.allSatisfy { self.isCompatible(with: $0) }
        }
        
        // Container compatibility (covariant for now)
        switch (self, other) {
        case (.list(let t1), .list(let t2)):
            return t1.isCompatible(with: t2)
        case (.set(let t1), .set(let t2)):
            return t1.isCompatible(with: t2)
        case (.dict(let k1, let v1), .dict(let k2, let v2)):
            return k1.isCompatible(with: k2) && v1.isCompatible(with: v2)
        case (.tuple(let types1), .tuple(let types2)):
            guard types1.count == types2.count else { return false }
            return zip(types1, types2).allSatisfy { $0.isCompatible(with: $1) }
        default:
            return false
        }
    }
}

// MARK: - CustomStringConvertible

extension PythonType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .int: return "int"
        case .float: return "float"
        case .str: return "str"
        case .bool: return "bool"
        case .bytes: return "bytes"
        case .none: return "None"
        case .list(let type): return "list[\(type)]"
        case .dict(let key, let value): return "dict[\(key), \(value)]"
        case .set(let type): return "set[\(type)]"
        case .tuple(let types): return "tuple[\(types.map(\.description).joined(separator: ", "))]"
        case .function(let params, let ret): return "(\(params.map(\.description).joined(separator: ", "))) -> \(ret)"
        case .classType(let name): return "type[\(name)]"
        case .instance(let name): return name
        case .union(let types): return types.map(\.description).joined(separator: " | ")
        case .any: return "Any"
        case .unknown: return "?"
        }
    }
}

/// Type annotation parser - converts Python type expressions to PythonType
public struct TypeAnnotationParser {
    
    /// Parse a type annotation expression
    public static func parse(_ expr: Expression) -> PythonType {
        switch expr {
        case .name(let name):
            return parseSimpleType(name.id)
            
        case .constant(let constant):
            // Handle None
            if case .none = constant.value {
                return .none
            }
            return .unknown
            
        case .subscriptExpr(let sub):
            // Handle generics like List[int], Dict[str, int]
            return parseGenericType(sub)
            
        case .binOp(let binOp):
            // Handle union types with | operator (Python 3.10+)
            if case .bitOr = binOp.op {
                let left = parse(binOp.left)
                let right = parse(binOp.right)
                return .union([left, right])
            }
            return .unknown
            
        default:
            return .unknown
        }
    }
    
    private static func parseSimpleType(_ name: String) -> PythonType {
        switch name {
        case "int": return .int
        case "float": return .float
        case "str": return .str
        case "bool": return .bool
        case "bytes": return .bytes
        case "None": return .none
        case "list": return .list(.any)
        case "dict": return .dict(key: .any, value: .any)
        case "set": return .set(.any)
        case "tuple": return .tuple([.any])
        case "Any": return .any
        default:
            // Assume it's a class name
            return .instance(name)
        }
    }
    
    private static func parseGenericType(_ sub: Subscript) -> PythonType {
        guard case .name(let baseName) = sub.value else {
            return .unknown
        }
        
        switch baseName.id {
        case "List", "list":
            if case .tuple(let elements) = sub.slice,
               let first = elements.elts.first {
                return .list(parse(first))
            }
            return .list(.any)
            
        case "Dict", "dict":
            if case .tuple(let elements) = sub.slice,
               elements.elts.count == 2 {
                return .dict(
                    key: parse(elements.elts[0]),
                    value: parse(elements.elts[1])
                )
            }
            return .dict(key: .any, value: .any)
            
        case "Set", "set":
            if case .tuple(let elements) = sub.slice,
               let first = elements.elts.first {
                return .set(parse(first))
            }
            return .set(.any)
            
        case "Tuple", "tuple":
            if case .tuple(let elements) = sub.slice {
                return .tuple(elements.elts.map(parse))
            }
            return .tuple([.any])
            
        case "Optional":
            if case .tuple(let elements) = sub.slice,
               let first = elements.elts.first {
                return .optional(parse(first))
            }
            return .optional(.any)
            
        case "Union":
            if case .tuple(let elements) = sub.slice {
                return .union(elements.elts.map(parse))
            }
            return .unknown
            
        default:
            return .unknown
        }
    }
}
