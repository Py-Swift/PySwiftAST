import Foundation

// MARK: - Definition Provider Types

/// Represents a location in a source file
/// Corresponds to Monaco's `monaco.languages.Location`
public struct Location: Codable, Sendable {
    /// The resource identifier of this location
    public let uri: String
    
    /// The range of this location
    public let range: IDERange
    
    public init(uri: String, range: IDERange) {
        self.uri = uri
        self.range = range
    }
}

/// A link to a source location
/// Corresponds to Monaco's `monaco.languages.LocationLink`
public struct LocationLink: Codable, Sendable {
    /// The origin of this link
    public let originSelectionRange: IDERange?
    
    /// The target resource identifier
    public let targetUri: String
    
    /// The full target range of this link
    public let targetRange: IDERange
    
    /// The span inside targetRange that is considered the target
    public let targetSelectionRange: IDERange
    
    public init(
        originSelectionRange: IDERange? = nil,
        targetUri: String,
        targetRange: IDERange,
        targetSelectionRange: IDERange
    ) {
        self.originSelectionRange = originSelectionRange
        self.targetUri = targetUri
        self.targetRange = targetRange
        self.targetSelectionRange = targetSelectionRange
    }
}

// MARK: - Symbol Provider Types

/// Represents programming constructs like variables, classes, functions, etc.
/// Corresponds to Monaco's `monaco.languages.DocumentSymbol`
public struct DocumentSymbol: Codable, Sendable {
    /// The name of this symbol
    public let name: String
    
    /// More detail for this symbol
    public let detail: String?
    
    /// The kind of this symbol
    public let kind: SymbolKind
    
    /// Tags for this symbol
    public let tags: [SymbolTag]?
    
    /// The range enclosing this symbol
    public let range: IDERange
    
    /// The range that should be selected and revealed when this symbol is being picked
    public let selectionRange: IDERange
    
    /// Children of this symbol
    public let children: [DocumentSymbol]?
    
    public init(
        name: String,
        detail: String? = nil,
        kind: SymbolKind,
        tags: [SymbolTag]? = nil,
        range: IDERange,
        selectionRange: IDERange,
        children: [DocumentSymbol]? = nil
    ) {
        self.name = name
        self.detail = detail
        self.kind = kind
        self.tags = tags
        self.range = range
        self.selectionRange = selectionRange
        self.children = children
    }
}

/// Symbol kinds
/// Corresponds to Monaco's `monaco.languages.SymbolKind`
public enum SymbolKind: Int, Codable, Sendable {
    case file = 0
    case module = 1
    case namespace = 2
    case package = 3
    case `class` = 4
    case method = 5
    case property = 6
    case field = 7
    case constructor = 8
    case `enum` = 9
    case interface = 10
    case function = 11
    case variable = 12
    case constant = 13
    case string = 14
    case number = 15
    case boolean = 16
    case array = 17
    case object = 18
    case key = 19
    case null = 20
    case enumMember = 21
    case `struct` = 22
    case event = 23
    case `operator` = 24
    case typeParameter = 25
}

/// Symbol tags
/// Corresponds to Monaco's `monaco.languages.SymbolTag`
public enum SymbolTag: Int, Codable, Sendable {
    case deprecated = 1
}

// MARK: - Reference Provider Types

/// A reference context for finding references
/// Corresponds to Monaco's `monaco.languages.ReferenceContext`
public struct ReferenceContext: Codable, Sendable {
    /// Include the declaration of the symbol in the results
    public let includeDeclaration: Bool
    
    public init(includeDeclaration: Bool) {
        self.includeDeclaration = includeDeclaration
    }
}

// MARK: - Helper Extensions

extension DocumentSymbol {
    /// Create a function symbol
    public static func function(
        name: String,
        parameters: String? = nil,
        range: IDERange,
        selectionRange: IDERange,
        children: [DocumentSymbol]? = nil
    ) -> DocumentSymbol {
        DocumentSymbol(
            name: name,
            detail: parameters.map { "(\($0))" },
            kind: .function,
            range: range,
            selectionRange: selectionRange,
            children: children
        )
    }
    
    /// Create a class symbol
    public static func `class`(
        name: String,
        bases: [String]? = nil,
        range: IDERange,
        selectionRange: IDERange,
        children: [DocumentSymbol]? = nil
    ) -> DocumentSymbol {
        let detail = bases.map { "(\($0.joined(separator: ", ")))" }
        return DocumentSymbol(
            name: name,
            detail: detail,
            kind: .class,
            range: range,
            selectionRange: selectionRange,
            children: children
        )
    }
    
    /// Create a variable symbol
    public static func variable(
        name: String,
        type: String? = nil,
        range: IDERange,
        selectionRange: IDERange
    ) -> DocumentSymbol {
        DocumentSymbol(
            name: name,
            detail: type.map { ": \($0)" },
            kind: .variable,
            range: range,
            selectionRange: selectionRange
        )
    }
    
    /// Create a method symbol
    public static func method(
        name: String,
        parameters: String? = nil,
        range: IDERange,
        selectionRange: IDERange
    ) -> DocumentSymbol {
        DocumentSymbol(
            name: name,
            detail: parameters.map { "(\($0))" },
            kind: .method,
            range: range,
            selectionRange: selectionRange
        )
    }
}

extension Location {
    /// Create a location in the current document
    public static func current(range: IDERange) -> Location {
        Location(uri: "file:///current", range: range)
    }
}
