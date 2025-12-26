
public protocol PMType: Encodable, CustomStringConvertible {
    var name: String { get }
    var doc: String? { get }
}

public enum PMBasicType: PMType, Encodable, CustomStringConvertible {
    case any
    case int
    case float
    case str
    case bool
    case list(element: any PMType)
    case dict(key: String, value: any PMType)
    case none

    public var name: String {
        switch self {
            case .any:
                "Any"
            case .int:
                "int"
            case .float:
                "float"
            case .str:
                "str"
            case .bool:
                "bool"
            case .list(_):
                "list"
            case .dict(_, _):
                "dict"
            case .none:
                "None"
        }
    }
    
    public var description: String {
        switch self {
            case .any:
                "Any"
            case .int:
                "int"
            case .float:
                "float"
            case .str:
                "str"
            case .bool:
                "bool"
            case .list(let element):
                "list[\(element)]"
            case .dict(let key, let value):
                "dict[]"
            case .none:
                "None"
        }
    }

    public var doc: String? {
        return nil
    }
    
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(description)
    }
}

public struct PMImport: Codable {
    public var name: String
    public var asname: String?

    public init(name: String, asname: String?) {
        self.name = name
        self.asname = asname
    }
}

public struct PMFunction: Encodable {
    public var name: String
    public var doc: String?
    public var parameters: [String: Parameter]

    public init(name: String, doc: String?, parameters: [String: Parameter]) {
        self.name = name
        self.doc = doc
        self.parameters = parameters
    }

    public struct Parameter: Encodable {
        public var name: String
        public var type: (any PMType)?

        public init(name: String, type: (any PMType)?) {
            self.name = name
            self.type = type
        }
        
        private enum CodingKeys: CodingKey {
            case name
            case type
        }
        
        public func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(name, forKey: .name)
            try c.encode(type?.name, forKey: .type)
        }
        
        
    }
}

public struct PMClass: Codable {
    public var name: String
    public var doc: String?
    public var methods: [String: PMFunction]

    public init(name: String, doc: String?, methods: [String: PMFunction]) {
        self.name = name
        self.doc = doc
        self.methods = methods
    }
}

public class PMDump: Codable {
    public var name: String
    public var doc: String?
    public var imports: [String: PMImport]

    public init(name: String, doc: String?, imports: [String: PMImport]) {
        self.name = name
        self.doc = doc
        self.imports = imports
    }
}
