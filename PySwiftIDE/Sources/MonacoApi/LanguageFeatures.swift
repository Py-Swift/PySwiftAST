import Foundation

// MARK: - Signature Help Provider Types

/// Signature help represents the signature of something callable
/// Corresponds to Monaco's `monaco.languages.SignatureHelp`
public struct SignatureHelp: Codable, Sendable {
    /// One or more signatures
    public let signatures: [SignatureInformation]
    
    /// The active signature
    public let activeSignature: Int?
    
    /// The active parameter of the active signature
    public let activeParameter: Int?
    
    public init(
        signatures: [SignatureInformation],
        activeSignature: Int? = nil,
        activeParameter: Int? = nil
    ) {
        self.signatures = signatures
        self.activeSignature = activeSignature
        self.activeParameter = activeParameter
    }
}

/// Represents the signature of a callable
/// Corresponds to Monaco's `monaco.languages.SignatureInformation`
public struct SignatureInformation: Codable, Sendable {
    /// The label of this signature
    public let label: String
    
    /// The human-readable documentation of this signature
    public let documentation: HoverContent?
    
    /// The parameters of this signature
    public let parameters: [ParameterInformation]?
    
    /// The index of the active parameter
    public let activeParameter: Int?
    
    public init(
        label: String,
        documentation: HoverContent? = nil,
        parameters: [ParameterInformation]? = nil,
        activeParameter: Int? = nil
    ) {
        self.label = label
        self.documentation = documentation
        self.parameters = parameters
        self.activeParameter = activeParameter
    }
}

/// Represents a parameter of a callable signature
/// Corresponds to Monaco's `monaco.languages.ParameterInformation`
public struct ParameterInformation: Codable, Sendable {
    /// The label of this parameter
    public let label: String
    
    /// The human-readable documentation of this parameter
    public let documentation: HoverContent?
    
    public init(label: String, documentation: HoverContent? = nil) {
        self.label = label
        self.documentation = documentation
    }
}

// MARK: - Formatting Provider Types

/// A format edit represents a text edit that should be applied during formatting
/// Corresponds to Monaco's `monaco.languages.TextEdit`
public typealias FormattingEdit = TextEdit

/// Options for document formatting
/// Corresponds to Monaco's `monaco.languages.FormattingOptions`
public struct FormattingOptions: Codable, Sendable {
    /// Size of a tab in spaces
    public let tabSize: Int
    
    /// Prefer spaces over tabs
    public let insertSpaces: Bool
    
    public init(tabSize: Int = 4, insertSpaces: Bool = true) {
        self.tabSize = tabSize
        self.insertSpaces = insertSpaces
    }
}

// MARK: - Folding Provider Types

/// A folding range represents a region that can be folded
/// Corresponds to Monaco's `monaco.languages.FoldingRange`
public struct FoldingRange: Codable, Sendable {
    /// The one-based start line of the range to fold
    public let start: Int
    
    /// The one-based end line of the range to fold
    public let end: Int
    
    /// The kind of folding range
    public let kind: FoldingRangeKind?
    
    public init(start: Int, end: Int, kind: FoldingRangeKind? = nil) {
        self.start = start
        self.end = end
        self.kind = kind
    }
}

/// Folding range kinds
/// Corresponds to Monaco's `monaco.languages.FoldingRangeKind`
public enum FoldingRangeKind: String, Codable, Sendable {
    case comment = "comment"
    case imports = "imports"
    case region = "region"
}

// MARK: - Semantic Tokens Provider Types

/// Legend for semantic tokens
/// Corresponds to Monaco's `monaco.languages.SemanticTokensLegend`
public struct SemanticTokensLegend: Codable, Sendable {
    /// The token types
    public let tokenTypes: [String]
    
    /// The token modifiers
    public let tokenModifiers: [String]
    
    public init(tokenTypes: [String], tokenModifiers: [String]) {
        self.tokenTypes = tokenTypes
        self.tokenModifiers = tokenModifiers
    }
}

/// Semantic tokens for a document
/// Corresponds to Monaco's `monaco.languages.SemanticTokens`
public struct SemanticTokens: Codable, Sendable {
    /// The result id of the tokens
    public let resultId: String?
    
    /// The actual tokens data
    /// Array of 5n integers: deltaLine, deltaStartChar, length, tokenType, tokenModifiers
    public let data: [Int]
    
    public init(resultId: String? = nil, data: [Int]) {
        self.resultId = resultId
        self.data = data
    }
}

// MARK: - Inlay Hints Provider Types

/// Inlay hints provide additional information inline with the code
/// Corresponds to Monaco's `monaco.languages.InlayHint`
public struct InlayHint: Codable, Sendable {
    /// The position of this hint
    public let position: Position
    
    /// The label of this hint
    public let label: String
    
    /// The kind of this hint
    public let kind: InlayHintKind?
    
    /// Tooltip text when hovering over this hint
    public let tooltip: String?
    
    /// Render padding before the hint
    public let paddingLeft: Bool?
    
    /// Render padding after the hint
    public let paddingRight: Bool?
    
    public init(
        position: Position,
        label: String,
        kind: InlayHintKind? = nil,
        tooltip: String? = nil,
        paddingLeft: Bool? = nil,
        paddingRight: Bool? = nil
    ) {
        self.position = position
        self.label = label
        self.kind = kind
        self.tooltip = tooltip
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
    }
}

/// Position in a text document
/// Corresponds to Monaco's `monaco.IPosition`
public struct Position: Codable, Sendable {
    /// Line position in a document (one-based)
    public let lineNumber: Int
    
    /// Character offset on a line in a document (one-based)
    public let column: Int
    
    public init(lineNumber: Int, column: Int) {
        self.lineNumber = lineNumber
        self.column = column
    }
}

/// Inlay hint kinds
/// Corresponds to Monaco's `monaco.languages.InlayHintKind`
public enum InlayHintKind: Int, Codable, Sendable {
    case type = 1
    case parameter = 2
}

// MARK: - Helper Extensions

extension SignatureHelp {
    /// Create signature help for a Python function
    public static func function(
        name: String,
        parameters: [(name: String, type: String?, doc: String?)],
        activeParameter: Int? = nil,
        documentation: String? = nil
    ) -> SignatureHelp {
        let paramInfo = parameters.map { param in
            let label = param.type.map { "\(param.name): \($0)" } ?? param.name
            return ParameterInformation(
                label: label,
                documentation: param.doc.map { .plainText($0) }
            )
        }
        
        let paramLabels = paramInfo.map { $0.label }.joined(separator: ", ")
        let signature = SignatureInformation(
            label: "\(name)(\(paramLabels))",
            documentation: documentation.map { .plainText($0) },
            parameters: paramInfo,
            activeParameter: activeParameter
        )
        
        return SignatureHelp(
            signatures: [signature],
            activeSignature: 0,
            activeParameter: activeParameter
        )
    }
}

extension InlayHint {
    /// Create a type hint
    public static func typeHint(
        at position: Position,
        type: String,
        tooltip: String? = nil
    ) -> InlayHint {
        InlayHint(
            position: position,
            label: ": \(type)",
            kind: .type,
            tooltip: tooltip,
            paddingLeft: false,
            paddingRight: true
        )
    }
    
    /// Create a parameter name hint
    public static func parameterHint(
        at position: Position,
        name: String,
        tooltip: String? = nil
    ) -> InlayHint {
        InlayHint(
            position: position,
            label: "\(name): ",
            kind: .parameter,
            tooltip: tooltip,
            paddingLeft: false,
            paddingRight: false
        )
    }
}

extension FoldingRange {
    /// Create a folding range for a function or class
    public static func block(start: Int, end: Int) -> FoldingRange {
        FoldingRange(start: start, end: end)
    }
    
    /// Create a folding range for comments
    public static func comment(start: Int, end: Int) -> FoldingRange {
        FoldingRange(start: start, end: end, kind: .comment)
    }
    
    /// Create a folding range for imports
    public static func imports(start: Int, end: Int) -> FoldingRange {
        FoldingRange(start: start, end: end, kind: .imports)
    }
}
