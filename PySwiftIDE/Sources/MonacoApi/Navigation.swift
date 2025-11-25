import Foundation

// MARK: - Definition Provider Types

/// A location represents a location inside a resource
/// Corresponds to Monaco's `monaco.languages.Location`
public struct Location: Codable, Sendable {
    /// The resource identifier
    public let uri: String
    
    /// The range inside the text document
    public let range: IDERange
    
    public init(uri: String, range: IDERange) {
        self.uri = uri
        self.range = range
    }
}

/// A link in a document
/// Corresponds to Monaco's `monaco.languages.LocationLink`
public struct LocationLink: Codable, Sendable {
    /// Span of the origin of the link (e.g. name of identifier)
    public let originSelectionRange: IDERange?
    
    /// The target resource
    public let targetUri: String
    
    /// The full range being pointed to
    public let targetRange: IDERange
    
    /// The span of the symbol definition at the target
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

// MARK: - References Provider Types

/// Reference context for finding references
/// Corresponds to Monaco's `monaco.languages.ReferenceContext`
public struct ReferenceContext: Codable, Sendable {
    /// Include the declaration of the current symbol
    public let includeDeclaration: Bool
    
    public init(includeDeclaration: Bool) {
        self.includeDeclaration = includeDeclaration
    }
}

// MARK: - Rename Provider Types

/// A workspace edit represents changes to many resources
/// Corresponds to Monaco's `monaco.languages.WorkspaceEdit`
public struct WorkspaceEdit: Codable, Sendable {
    /// Holds changes to existing resources
    public let changes: [String: [TextEdit]]
    
    public init(changes: [String: [TextEdit]]) {
        self.changes = changes
    }
}

/// A text edit represents an edit to a text document
/// Corresponds to Monaco's `monaco.languages.TextEdit`
public struct TextEdit: Codable, Sendable {
    /// The range to replace
    public let range: IDERange
    
    /// The new text
    public let text: String
    
    public init(range: IDERange, text: String) {
        self.range = range
        self.text = text
    }
}

/// Result of a rename operation
/// Corresponds to Monaco's `monaco.languages.RenameLocation`
public struct RenameLocation: Codable, Sendable {
    /// The range to rename
    public let range: IDERange
    
    /// The text to display
    public let text: String
    
    public init(range: IDERange, text: String) {
        self.range = range
        self.text = text
    }
}

// MARK: - Document Highlights Provider Types

/// A document highlight represents a range inside a text document
/// which deserves special attention. Usually a document highlight is
/// visualized by changing the background color of its range.
/// Corresponds to Monaco's `monaco.languages.DocumentHighlight`
public struct DocumentHighlight: Codable, Sendable {
    /// The range this highlight applies to
    public let range: IDERange
    
    /// The highlight kind, default is text
    public let kind: DocumentHighlightKind?
    
    public init(range: IDERange, kind: DocumentHighlightKind? = nil) {
        self.range = range
        self.kind = kind
    }
}

/// A document highlight kind
/// Corresponds to Monaco's `monaco.languages.DocumentHighlightKind`
public enum DocumentHighlightKind: Int, Codable, Sendable {
    /// A textual occurrence
    case text = 0
    /// Read-access of a symbol, like reading a variable
    case read = 1
    /// Write-access of a symbol, like writing to a variable
    case write = 2
}

// MARK: - Selection Range Provider Types

/// A selection range represents a range around the cursor
/// that the user might be interested in selecting.
/// Corresponds to Monaco's `monaco.languages.SelectionRange`
public struct SelectionRange: Codable, Sendable {
    /// The range of this selection range
    public let range: IDERange
    
    /// The parent selection range containing this range
    public let parent: SelectionRange?
    
    private enum CodingKeys: String, CodingKey {
        case range, parent
    }
    
    public init(range: IDERange, parent: SelectionRange? = nil) {
        self.range = range
        self.parent = parent
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        range = try container.decode(IDERange.self, forKey: .range)
        parent = try container.decodeIfPresent(SelectionRange.self, forKey: .parent)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(range, forKey: .range)
        try container.encodeIfPresent(parent, forKey: .parent)
    }
}

// MARK: - Helper Extensions

extension Location {
    /// Create a location for the current document
    public static func here(range: IDERange) -> Location {
        Location(uri: "document", range: range)
    }
}

extension DocumentHighlight {
    /// Create a text highlight
    public static func text(at range: IDERange) -> DocumentHighlight {
        DocumentHighlight(range: range, kind: .text)
    }
    
    /// Create a read highlight
    public static func read(at range: IDERange) -> DocumentHighlight {
        DocumentHighlight(range: range, kind: .read)
    }
    
    /// Create a write highlight
    public static func write(at range: IDERange) -> DocumentHighlight {
        DocumentHighlight(range: range, kind: .write)
    }
}

extension SelectionRange {
    /// Create a selection range hierarchy from ranges (innermost to outermost)
    public static func hierarchy(_ ranges: [IDERange]) -> SelectionRange? {
        guard !ranges.isEmpty else { return nil }
        
        var result: SelectionRange?
        for range in ranges.reversed() {
            result = SelectionRange(range: range, parent: result)
        }
        return result
    }
}
