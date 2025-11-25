import Foundation
import PySwiftAST
import MonacoApi

/// Provides Monaco Editor language features for Python code analysis
public class MonacoAnalyzer {
    private let validator: PythonValidator
    private let source: String
    private let sourceLines: [String]
    private var ast: Module?
    
    public init(source: String) {
        self.source = source
        self.sourceLines = source.components(separatedBy: .newlines)
        self.validator = PythonValidator(source: source)
    }
    
    // MARK: - Validation & Diagnostics
    
    /// Validate the source code and return diagnostics
    public func getDiagnostics() -> [Diagnostic] {
        let result = validator.validate()
        self.ast = result.ast
        return result.diagnostics
    }
    
    // MARK: - Code Actions
    
    /// Get code actions (quick fixes, refactorings) for a given range
    public func getCodeActions(for range: IDERange) -> [CodeAction] {
        let diagnostics = getDiagnostics()
        let relevantDiagnostics = diagnostics.filter { diagnostic in
            rangesOverlap(range, diagnostic.range)
        }
        
        return validator.getCodeActions(for: range, diagnostics: relevantDiagnostics)
    }
    
    // MARK: - Hover
    
    /// Get hover information for a position
    public func getHover(at position: Position) -> Hover? {
        guard let ast = ast else { return nil }
        
        // Find the node at the given position
        guard let node = findNodeAt(position: position, in: ast) else {
            return nil
        }
        
        // Generate hover content based on node type
        return generateHover(for: node, at: position)
    }
    
    // MARK: - Completion
    
    /// Get completion items at a position
    public func getCompletions(at position: Position, context: CompletionContext? = nil) -> CompletionList {
        var items: [CompletionItem] = []
        
        // Add Python keywords
        items.append(contentsOf: getPythonKeywordCompletions())
        
        // Add builtin functions
        items.append(contentsOf: getBuiltinCompletions())
        
        // If we have AST, add context-aware completions
        if let ast = ast {
            items.append(contentsOf: getContextualCompletions(at: position, in: ast))
        }
        
        return CompletionList(suggestions: items, incomplete: false)
    }
    
    /// Get inline completions (Copilot-style suggestions)
    public func getInlineCompletions(at position: Position, context: InlineCompletionContext) -> InlineCompletionList? {
        // Placeholder for AI-powered inline completions
        // This would integrate with a language model or copilot service
        return nil
    }
    
    /// Get signature help for function calls
    public func getSignatureHelp(at position: Position, context: SignatureHelpContext? = nil) -> SignatureHelpResult? {
        guard let ast = ast else { return nil }
        
        // Find if we're inside a function call
        guard let callNode = findFunctionCallAt(position: position, in: ast) else {
            return nil
        }
        
        return generateSignatureHelp(for: callNode, at: position)
    }
    
    // MARK: - Symbols
    
    /// Get document symbols (outline)
    public func getDocumentSymbols() -> [DocumentSymbol] {
        guard let ast = ast else { return [] }
        
        var symbols: [DocumentSymbol] = []
        
        // Extract top-level symbols from AST
        let statements = getStatements(from: ast)
        for statement in statements {
            if let symbol = extractSymbol(from: statement) {
                symbols.append(symbol)
            }
        }
        
        return symbols
    }
    
    // MARK: - Language Features
    
    /// Get folding ranges for code folding
    public func getFoldingRanges() -> [FoldingRange] {
        var ranges: [FoldingRange] = []
        
        // Find function definitions
        ranges.append(contentsOf: findFunctionFoldingRanges())
        
        // Find class definitions
        ranges.append(contentsOf: findClassFoldingRanges())
        
        // Find import blocks
        ranges.append(contentsOf: findImportFoldingRanges())
        
        // Find comment blocks
        ranges.append(contentsOf: findCommentFoldingRanges())
        
        return ranges
    }
    
    /// Get inlay hints (parameter names, type hints)
    public func getInlayHints(for range: IDERange) -> [InlayHint] {
        guard let ast = ast else { return [] }
        
        var hints: [InlayHint] = []
        
        // Add parameter name hints for function calls
        hints.append(contentsOf: findParameterHints(in: ast, range: range))
        
        // Add type hints for variables (if type inference available)
        hints.append(contentsOf: findTypeHints(in: ast, range: range))
        
        return hints
    }
    
    // MARK: - Private Helpers - Node Finding
    
    private func findNodeAt(position: Position, in module: Module) -> Statement? {
        // Simple implementation - would need more sophisticated AST traversal
        let line = position.lineNumber
        let statements = getStatements(from: module)
        
        for statement in statements {
            if let stmtLine = getStatementLine(statement) {
                if stmtLine == line {
                    return statement
                }
            }
        }
        
        return nil
    }
    
    private func findFunctionCallAt(position: Position, in module: Module) -> Statement? {
        // Placeholder - would need to traverse AST to find function calls
        return nil
    }
    
    private func getStatementLine(_ statement: Statement) -> Int? {
        // Extract line number from statement
        return statement.lineno
    }
    
    // MARK: - Private Helpers - Hover
    
    private func generateHover(for node: Statement, at position: Position) -> Hover? {
        switch node {
        case .functionDef(let funcDef):
            let params = funcDef.args.args.map { $0.arg }.joined(separator: ", ")
            let code = "def \(funcDef.name)(\(params)):"
            return Hover.code(code, language: "python")
            
        case .classDef(let classDef):
            let code = "class \(classDef.name):"
            return Hover.code(code, language: "python")
            
        default:
            return nil
        }
    }
    
    // MARK: - Private Helpers - Completion
    
    private func getPythonKeywordCompletions() -> [CompletionItem] {
        let keywords = [
            "def", "class", "if", "elif", "else", "for", "while",
            "return", "yield", "import", "from", "as", "try", "except",
            "finally", "with", "async", "await", "lambda", "pass",
            "break", "continue", "raise", "assert", "del", "global",
            "nonlocal", "True", "False", "None", "and", "or", "not",
            "in", "is"
        ]
        
        return keywords.map { CompletionItem.keyword($0) }
    }
    
    private func getBuiltinCompletions() -> [CompletionItem] {
        let builtins = [
            ("print", ["*args", "sep=' '", "end='\\n'"]),
            ("len", ["obj"]),
            ("range", ["start", "stop", "step=1"]),
            ("str", ["object"]),
            ("int", ["x", "base=10"]),
            ("float", ["x"]),
            ("list", ["iterable"]),
            ("dict", ["**kwargs"]),
            ("set", ["iterable"]),
            ("tuple", ["iterable"]),
            ("open", ["file", "mode='r'"]),
            ("type", ["object"]),
            ("isinstance", ["obj", "classinfo"]),
            ("enumerate", ["iterable", "start=0"]),
            ("zip", ["*iterables"]),
            ("map", ["function", "iterable"]),
            ("filter", ["function", "iterable"])
        ]
        
        return builtins.map { name, params in
            CompletionItem.function(name: name, parameters: params)
        }
    }
    
    private func getContextualCompletions(at position: Position, in module: Module) -> [CompletionItem] {
        var items: [CompletionItem] = []
        let statements = getStatements(from: module)
        
        // Extract defined functions
        for statement in statements {
            if case .functionDef(let funcDef) = statement {
                let params = funcDef.args.args.map { $0.arg }
                items.append(CompletionItem.function(name: funcDef.name, parameters: params))
            }
        }
        
        // Extract defined classes
        for statement in statements {
            if case .classDef(let classDef) = statement {
                items.append(CompletionItem.class(name: classDef.name))
            }
        }
        
        return items
    }
    
    // MARK: - Private Helpers - Signature Help
    
    private func generateSignatureHelp(for callNode: Statement, at position: Position) -> SignatureHelpResult? {
        // Placeholder - would generate signature help based on function definition
        return nil
    }
    
    // MARK: - Private Helpers - Symbols
    
    private func extractSymbol(from statement: Statement) -> DocumentSymbol? {
        switch statement {
        case .functionDef(let funcDef):
            let params = funcDef.args.args.map { $0.arg }.joined(separator: ", ")
            return DocumentSymbol(
                name: funcDef.name,
                detail: "(\(params))",
                kind: .function,
                range: IDERange.from(line: funcDef.lineno, column: 1, length: funcDef.name.count + 10),
                selectionRange: IDERange.from(line: funcDef.lineno, column: 5, length: funcDef.name.count)
            )
            
        case .classDef(let classDef):
            return DocumentSymbol(
                name: classDef.name,
                detail: nil,
                kind: .class,
                range: IDERange.from(line: classDef.lineno, column: 1, length: classDef.name.count + 10),
                selectionRange: IDERange.from(line: classDef.lineno, column: 7, length: classDef.name.count)
            )
            
        default:
            return nil
        }
    }
    
    // MARK: - Private Helpers - Folding
    
    private func findFunctionFoldingRanges() -> [FoldingRange] {
        guard let ast = ast else { return [] }
        
        var ranges: [FoldingRange] = []
        let statements = getStatements(from: ast)
        
        for statement in statements {
            if case .functionDef(let funcDef) = statement {
                // Calculate end line from body
                if !funcDef.body.isEmpty {
                    ranges.append(FoldingRange(
                        start: funcDef.lineno,
                        end: funcDef.lineno + funcDef.body.count,
                        kind: .region
                    ))
                }
            }
        }
        
        return ranges
    }
    
    private func findClassFoldingRanges() -> [FoldingRange] {
        guard let ast = ast else { return [] }
        
        var ranges: [FoldingRange] = []
        let statements = getStatements(from: ast)
        
        for statement in statements {
            if case .classDef(let classDef) = statement {
                if !classDef.body.isEmpty {
                    ranges.append(FoldingRange(
                        start: classDef.lineno,
                        end: classDef.lineno + classDef.body.count,
                        kind: .region
                    ))
                }
            }
        }
        
        return ranges
    }
    
    private func findImportFoldingRanges() -> [FoldingRange] {
        var ranges: [FoldingRange] = []
        var importStart: Int?
        var importEnd: Int?
        
        for (index, line) in sourceLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("import ") || trimmed.hasPrefix("from ") {
                if importStart == nil {
                    importStart = index + 1
                }
                importEnd = index + 1
            } else if importStart != nil {
                // End of import block
                if let start = importStart, let end = importEnd, end > start {
                    ranges.append(FoldingRange.imports(start: start, end: end))
                }
                importStart = nil
                importEnd = nil
            }
        }
        
        // Handle imports at end of file
        if let start = importStart, let end = importEnd, end > start {
            ranges.append(FoldingRange.imports(start: start, end: end))
        }
        
        return ranges
    }
    
    private func findCommentFoldingRanges() -> [FoldingRange] {
        var ranges: [FoldingRange] = []
        var commentStart: Int?
        var commentEnd: Int?
        
        for (index, line) in sourceLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("#") {
                if commentStart == nil {
                    commentStart = index + 1
                }
                commentEnd = index + 1
            } else if commentStart != nil {
                // End of comment block
                if let start = commentStart, let end = commentEnd, end > start {
                    ranges.append(FoldingRange.comment(start: start, end: end))
                }
                commentStart = nil
                commentEnd = nil
            }
        }
        
        // Handle comments at end of file
        if let start = commentStart, let end = commentEnd, end > start {
            ranges.append(FoldingRange.comment(start: start, end: end))
        }
        
        return ranges
    }
    
    // MARK: - Private Helpers - Inlay Hints
    
    private func findParameterHints(in module: Module, range: IDERange) -> [InlayHint] {
        // Placeholder - would find function calls and add parameter name hints
        return []
    }
    
    private func findTypeHints(in module: Module, range: IDERange) -> [InlayHint] {
        // Placeholder - would infer types and add type hints
        return []
    }
    
    // MARK: - AST Helpers
    
    private func getStatements(from module: Module) -> [Statement] {
        switch module {
        case .module(let statements), .interactive(let statements):
            return statements
        default:
            return []
        }
    }
    
    // MARK: - Utility
    
    private func rangesOverlap(_ range1: IDERange, _ range2: IDERange) -> Bool {
        // Check if two ranges overlap
        if range1.endLineNumber < range2.startLineNumber {
            return false
        }
        if range2.endLineNumber < range1.startLineNumber {
            return false
        }
        return true
    }
}
