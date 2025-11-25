import Foundation
import PySwiftAST
import MonacoApi

/// Validates Python code and collects diagnostics for IDE integration
public class PythonValidator {
    private let source: String
    private let sourceLines: [String]
    
    public init(source: String) {
        self.source = source
        self.sourceLines = source.components(separatedBy: .newlines)
    }
    
    /// Validate the Python source and return diagnostics
    public func validate() -> ValidationResult {
        var diagnostics: [Diagnostic] = []
        var ast: Module? = nil
        
        do {
            ast = try parsePythonFast(source)
        } catch let error as ParseError {
            // Convert ParseError to Diagnostic
            diagnostics.append(convertParseError(error))
            
            // Quick fixes will be provided separately via code actions
        } catch {
            // Unknown error
            diagnostics.append(Diagnostic(
                severity: .error,
                message: "Unexpected parsing error: \(error)",
                range: IDERange.from(line: 1, column: 1)
            ))
        }
        
        return ValidationResult(ast: ast, diagnostics: diagnostics)
    }
    
    /// Get code actions (quick fixes) for a given range
    public func getCodeActions(for range: IDERange, diagnostics: [Diagnostic]) -> [CodeAction] {
        var actions: [CodeAction] = []
        
        for diagnostic in diagnostics {
            // Check if this diagnostic has a quick fix
            if let action = generateCodeAction(for: diagnostic) {
                actions.append(action)
            }
        }
        
        return actions
    }
    
    // MARK: - Private Helpers
    
    private func convertParseError(_ error: ParseError) -> Diagnostic {
        switch error {
        case .expectedToken(let expected, let got, let context):
            let range = IDERange.from(
                line: got.line,
                column: got.column,
                length: got.value.isEmpty ? 1 : got.value.count
            )
            
            var message = "Expected '\(expected)' but got "
            message += got.value.isEmpty ? "newline" : "'\(got.value)'"
            
            if let ctx = context, !ctx.isEmpty {
                message += "\n\n\(ctx)"
            }
            
            return Diagnostic(
                severity: .error,
                message: message,
                range: range,
                code: "syntax-error"
            )
            
        case .expected(let msg, let line):
            return Diagnostic(
                severity: .error,
                message: msg,
                range: IDERange.from(line: line, column: 1),
                code: "syntax-error"
            )
            
        case .expectedName(let line):
            return Diagnostic(
                severity: .error,
                message: "Expected name",
                range: IDERange.from(line: line, column: 1),
                code: "expected-name"
            )
            
        case .unexpectedToken(let token):
            return Diagnostic(
                severity: .error,
                message: "Unexpected token '\(token.value)'",
                range: IDERange.from(
                    line: token.line,
                    column: token.column,
                    length: token.value.count
                ),
                code: "unexpected-token"
            )
            
        case .syntaxError(let msg, let line):
            return Diagnostic(
                severity: .error,
                message: "Syntax error: \(msg)",
                range: IDERange.from(line: line, column: 1),
                code: "syntax-error"
            )
        }
    }
    
    private func generateQuickFix(for error: ParseError) -> CodeAction? {
        switch error {
        case .expectedToken(let expected, let got, let context):
            // Generate a quick fix to insert the missing character
            guard let ctx = context, !ctx.isEmpty else { return nil }
            
            let range = IDERange(
                startLineNumber: got.line,
                startColumn: got.column,
                endLineNumber: got.line,
                endColumn: got.column
            )
            
            let edit = TextEdit(range: range, newText: expected)
            
            return CodeAction(
                title: "Insert '\(expected)'",
                kind: .quickfix,
                edit: WorkspaceEdit(changes: ["document": [edit]]),
                isPreferred: true
            )
            
        default:
            return nil
        }
    }
    
    private func generateCodeAction(for diagnostic: Diagnostic) -> CodeAction? {
        // Check if this is an expected token error that we can fix
        if diagnostic.code == "syntax-error",
           diagnostic.message.contains("Expected") {
            
            // Extract the expected character from the message
            if let expectedChar = extractExpectedChar(from: diagnostic.message) {
                let range = diagnostic.range
                let insertRange = IDERange(
                    startLineNumber: range.startLineNumber,
                    startColumn: range.startColumn,
                    endLineNumber: range.startLineNumber,
                    endColumn: range.startColumn
                )
                
                let edit = TextEdit(range: insertRange, newText: expectedChar)
                
                return CodeAction(
                    title: "Insert '\(expectedChar)'",
                    kind: .quickfix,
                    diagnostics: [diagnostic],
                    edit: WorkspaceEdit(changes: ["document": [edit]]),
                    isPreferred: true
                )
            }
        }
        
        return nil
    }
    
    private func extractExpectedChar(from message: String) -> String? {
        // Extract character between single quotes after "Expected"
        let pattern = "Expected '([^']+)'"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
              let range = Range(match.range(at: 1), in: message) else {
            return nil
        }
        return String(message[range])
    }
}

/// Result of validation containing AST (if successful) and diagnostics
public struct ValidationResult: Sendable {
    /// The parsed AST, if parsing succeeded
    public let ast: Module?
    
    /// All diagnostics found during validation
    public let diagnostics: [Diagnostic]
    
    /// Whether validation found any errors
    public var hasErrors: Bool {
        diagnostics.contains { $0.severity == .error }
    }
    
    public init(ast: Module?, diagnostics: [Diagnostic]) {
        self.ast = ast
        self.diagnostics = diagnostics
    }
}
