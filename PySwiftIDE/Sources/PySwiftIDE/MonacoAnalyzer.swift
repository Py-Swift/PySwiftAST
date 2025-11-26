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
        
        // Add math module completions
        items.append(contentsOf: getMathModuleCompletions())
        
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
    
    // MARK: - Navigation Features
    
    /// Get definition location for symbol at position
    public func getDefinition(at position: Position) -> [Location] {
        guard let ast = ast else { return [] }
        
        // Find symbol at position
        guard let symbol = findSymbolAt(position: position, in: ast) else {
            return []
        }
        
        // Find the definition of this symbol
        if let location = findDefinitionOf(symbol: symbol, in: ast) {
            return [location]
        }
        
        return []
    }
    
    /// Find all references to symbol at position
    public func getReferences(at position: Position, includeDeclaration: Bool = true) -> [Location] {
        guard let ast = ast else { return [] }
        
        // Find symbol at position
        guard let symbol = findSymbolAt(position: position, in: ast) else {
            return []
        }
        
        // Find all references
        var locations: [Location] = []
        locations.append(contentsOf: findReferencesOf(symbol: symbol, in: ast, includeDeclaration: includeDeclaration))
        
        return locations
    }
    
    /// Get edits to rename symbol at position
    public func getRenameEdits(at position: Position, newName: String) -> WorkspaceEdit? {
        guard let ast = ast else { return nil }
        
        // Find symbol at position
        guard let symbol = findSymbolAt(position: position, in: ast) else {
            return nil
        }
        
        // Find all references including declaration
        let locations = findReferencesOf(symbol: symbol, in: ast, includeDeclaration: true)
        
        // Create text edits for each location
        let edits = locations.map { location in
            TextEdit(range: location.range, newText: newName)
        }
        
        // Group by URI (all in same document for now)
        return WorkspaceEdit(changes: ["document": edits])
    }
    
    /// Get document highlights for symbol at position
    public func getDocumentHighlights(at position: Position) -> [DocumentHighlight] {
        guard let ast = ast else { return [] }
        
        // Find symbol at position
        guard let symbol = findSymbolAt(position: position, in: ast) else {
            return []
        }
        
        // Find all references
        let locations = findReferencesOf(symbol: symbol, in: ast, includeDeclaration: true)
        
        // Convert to document highlights
        return locations.map { location in
            // Determine if this is read or write access
            let kind = determineAccessKind(for: symbol, at: location)
            return DocumentHighlight(range: location.range, kind: kind)
        }
    }
    
    /// Get selection range at position (for smart expand/shrink selection)
    public func getSelectionRange(at position: Position) -> SelectionRange? {
        guard let ast = ast else { return nil }
        
        // Build hierarchy from innermost to outermost
        var ranges: [IDERange] = []
        
        // Start with word at position
        if let wordRange = getWordRangeAt(position: position) {
            ranges.append(wordRange)
        }
        
        // Add expression range if inside expression
        if let exprRange = getExpressionRangeAt(position: position, in: ast) {
            ranges.append(exprRange)
        }
        
        // Add statement range
        if let stmtRange = getStatementRangeAt(position: position, in: ast) {
            ranges.append(stmtRange)
        }
        
        // Add function/class range if inside one
        if let blockRange = getBlockRangeAt(position: position, in: ast) {
            ranges.append(blockRange)
        }
        
        return SelectionRange.hierarchy(ranges)
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
    
    private func getMathModuleCompletions() -> [CompletionItem] {
        var items: [CompletionItem] = []
        
        // Math module constants
        let constants = [
            ("pi", "3.141592653589793", "The mathematical constant π"),
            ("e", "2.718281828459045", "The mathematical constant e"),
            ("tau", "6.283185307179586", "The mathematical constant τ = 2π"),
            ("inf", "Positive infinity", "Floating-point positive infinity"),
            ("nan", "Not a number", "Floating-point 'not a number' (NaN)")
        ]
        
        for (name, value, doc) in constants {
            items.append(CompletionItem.constant(name: "math.\(name)", value: value, documentation: doc))
        }
        
        // Number-theoretic and representation functions
        let numberTheory: [(String, [String], String)] = [
            ("ceil", ["x"], "Return the ceiling of x, the smallest integer >= x"),
            ("comb", ["n", "k"], "Return n! / (k! * (n-k)!), the number of ways to choose k items from n"),
            ("copysign", ["x", "y"], "Return a float with the magnitude of x and the sign of y"),
            ("fabs", ["x"], "Return the absolute value of x"),
            ("factorial", ["n"], "Return n factorial as an integer"),
            ("floor", ["x"], "Return the floor of x, the largest integer <= x"),
            ("fmod", ["x", "y"], "Return x modulo y as defined by the platform C library"),
            ("frexp", ["x"], "Return the mantissa and exponent of x as the pair (m, e)"),
            ("fsum", ["iterable"], "Return an accurate floating point sum of values in the iterable"),
            ("gcd", ["*integers"], "Return the greatest common divisor of the specified integer arguments"),
            ("isclose", ["a", "b", "rel_tol=1e-09", "abs_tol=0.0"], "Return True if a is close in value to b"),
            ("isfinite", ["x"], "Return True if x is neither an infinity nor a NaN"),
            ("isinf", ["x"], "Return True if x is a positive or negative infinity"),
            ("isnan", ["x"], "Return True if x is a NaN (not a number)"),
            ("isqrt", ["n"], "Return the integer square root of n"),
            ("lcm", ["*integers"], "Return the least common multiple of the specified integer arguments"),
            ("ldexp", ["x", "i"], "Return x * (2**i), the inverse of frexp()"),
            ("modf", ["x"], "Return the fractional and integer parts of x"),
            ("nextafter", ["x", "y"], "Return the next floating-point value after x towards y"),
            ("perm", ["n", "k=None"], "Return n! / (n-k)!, the number of ways to choose and arrange k items from n"),
            ("remainder", ["x", "y"], "Return the IEEE 754-style remainder of x with respect to y"),
            ("trunc", ["x"], "Return x truncated to an Integral")
        ]
        
        // Power and logarithmic functions
        let powerLog: [(String, [String], String)] = [
            ("cbrt", ["x"], "Return the cube root of x"),
            ("exp", ["x"], "Return e raised to the power x"),
            ("exp2", ["x"], "Return 2 raised to the power x"),
            ("expm1", ["x"], "Return e**x - 1, computed in a way that is accurate for small x"),
            ("log", ["x", "base=e"], "Return the logarithm of x to the given base"),
            ("log1p", ["x"], "Return the natural logarithm of 1+x (base e)"),
            ("log2", ["x"], "Return the base-2 logarithm of x"),
            ("log10", ["x"], "Return the base-10 logarithm of x"),
            ("pow", ["x", "y"], "Return x raised to the power y"),
            ("sqrt", ["x"], "Return the square root of x")
        ]
        
        // Trigonometric functions
        let trig: [(String, [String], String)] = [
            ("acos", ["x"], "Return the arc cosine of x, in radians"),
            ("asin", ["x"], "Return the arc sine of x, in radians"),
            ("atan", ["x"], "Return the arc tangent of x, in radians"),
            ("atan2", ["y", "x"], "Return atan(y / x), in radians"),
            ("cos", ["x"], "Return the cosine of x radians"),
            ("dist", ["p", "q"], "Return the Euclidean distance between two points p and q"),
            ("hypot", ["*coordinates"], "Return the Euclidean norm, sqrt(sum(x**2 for x in coordinates))"),
            ("sin", ["x"], "Return the sine of x radians"),
            ("tan", ["x"], "Return the tangent of x radians")
        ]
        
        // Hyperbolic functions
        let hyperbolic: [(String, [String], String)] = [
            ("acosh", ["x"], "Return the inverse hyperbolic cosine of x"),
            ("asinh", ["x"], "Return the inverse hyperbolic sine of x"),
            ("atanh", ["x"], "Return the inverse hyperbolic tangent of x"),
            ("cosh", ["x"], "Return the hyperbolic cosine of x"),
            ("sinh", ["x"], "Return the hyperbolic sine of x"),
            ("tanh", ["x"], "Return the hyperbolic tangent of x")
        ]
        
        // Angular conversion
        let angular: [(String, [String], String)] = [
            ("degrees", ["x"], "Convert angle x from radians to degrees"),
            ("radians", ["x"], "Convert angle x from degrees to radians")
        ]
        
        // Special functions
        let special: [(String, [String], String)] = [
            ("erf", ["x"], "Return the error function at x"),
            ("erfc", ["x"], "Return the complementary error function at x"),
            ("gamma", ["x"], "Return the Gamma function at x"),
            ("lgamma", ["x"], "Return the natural logarithm of the absolute value of the Gamma function at x")
        ]
        
        // Combine all function groups
        let allFunctions = numberTheory + powerLog + trig + hyperbolic + angular + special
        
        for (name, params, doc) in allFunctions {
            items.append(CompletionItem.function(
                name: "math.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        return items
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
    
    // MARK: - Private Helpers - Symbol Finding
    
    /// Symbol information for navigation
    private struct SymbolInfo {
        let name: String
        let kind: SymbolKind
        let range: IDERange
    }
    
    private enum SymbolKind {
        case function
        case `class`
        case variable
        case parameter
    }
    
    private func findSymbolAt(position: Position, in module: Module) -> SymbolInfo? {
        let statements = getStatements(from: module)
        
        // Find which statement contains this position
        for statement in statements {
            if let symbol = findSymbolInStatement(statement, at: position) {
                return symbol
            }
        }
        
        return nil
    }
    
    private func findSymbolInStatement(_ statement: Statement, at position: Position) -> SymbolInfo? {
        // Check if this is a function definition
        if case .functionDef(let funcDef) = statement {
            if isPositionInRange(position, funcDef.lineno, funcDef.name.count) {
                return SymbolInfo(
                    name: funcDef.name,
                    kind: .function,
                    range: IDERange.from(line: funcDef.lineno, column: 5, length: funcDef.name.count)
                )
            }
        }
        
        // Check if this is a class definition
        if case .classDef(let classDef) = statement {
            if isPositionInRange(position, classDef.lineno, classDef.name.count) {
                return SymbolInfo(
                    name: classDef.name,
                    kind: .class,
                    range: IDERange.from(line: classDef.lineno, column: 7, length: classDef.name.count)
                )
            }
        }
        
        // TODO: Check for variable references, parameters, etc.
        
        return nil
    }
    
    private func isPositionInRange(_ position: Position, _ line: Int, _ length: Int) -> Bool {
        return position.lineNumber == line
    }
    
    // MARK: - Private Helpers - Definition Finding
    
    private func findDefinitionOf(symbol: SymbolInfo, in module: Module) -> Location? {
        let statements = getStatements(from: module)
        
        for statement in statements {
            // Check for function definition
            if case .functionDef(let funcDef) = statement, funcDef.name == symbol.name {
                return Location(
                    uri: "document",
                    range: IDERange.from(line: funcDef.lineno, column: 5, length: funcDef.name.count)
                )
            }
            
            // Check for class definition
            if case .classDef(let classDef) = statement, classDef.name == symbol.name {
                return Location(
                    uri: "document",
                    range: IDERange.from(line: classDef.lineno, column: 7, length: classDef.name.count)
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Private Helpers - Reference Finding
    
    private func findReferencesOf(symbol: SymbolInfo, in module: Module, includeDeclaration: Bool) -> [Location] {
        var locations: [Location] = []
        let statements = getStatements(from: module)
        
        // Add declaration if requested
        if includeDeclaration {
            if let defLocation = findDefinitionOf(symbol: symbol, in: module) {
                locations.append(defLocation)
            }
        }
        
        // Find all references in statements
        for statement in statements {
            locations.append(contentsOf: findReferencesInStatement(statement, symbol: symbol))
        }
        
        return locations
    }
    
    private func findReferencesInStatement(_ statement: Statement, symbol: SymbolInfo) -> [Location] {
        var locations: [Location] = []
        
        // TODO: Traverse AST to find all name references matching symbol.name
        // This would need proper expression traversal to find all Name nodes
        
        return locations
    }
    
    // MARK: - Private Helpers - Access Kind
    
    private func determineAccessKind(for symbol: SymbolInfo, at location: Location) -> DocumentHighlightKind {
        // Simple heuristic: function/class definitions are text, variables could be read/write
        switch symbol.kind {
        case .function, .class:
            return .text
        case .variable, .parameter:
            // TODO: Analyze context to determine if read or write
            return .read
        }
    }
    
    // MARK: - Private Helpers - Selection Ranges
    
    private func getWordRangeAt(position: Position) -> IDERange? {
        // Get the word at the current position
        let line = position.lineNumber
        guard line > 0 && line <= sourceLines.count else { return nil }
        
        let lineText = sourceLines[line - 1]
        let column = position.column - 1
        
        guard column >= 0 && column < lineText.count else { return nil }
        
        // Find word boundaries
        let chars = Array(lineText)
        var start = column
        var end = column
        
        while start > 0 && isWordChar(chars[start - 1]) {
            start -= 1
        }
        
        while end < chars.count && isWordChar(chars[end]) {
            end += 1
        }
        
        return IDERange(
            startLineNumber: line,
            startColumn: start + 1,
            endLineNumber: line,
            endColumn: end + 1
        )
    }
    
    private func isWordChar(_ char: Character) -> Bool {
        return char.isLetter || char.isNumber || char == "_"
    }
    
    private func getExpressionRangeAt(position: Position, in module: Module) -> IDERange? {
        // Placeholder - would find the expression containing this position
        return nil
    }
    
    private func getStatementRangeAt(position: Position, in module: Module) -> IDERange? {
        let statements = getStatements(from: module)
        
        for statement in statements {
            if statement.lineno == position.lineNumber {
                // Return range for this statement
                return IDERange.from(line: statement.lineno, column: 1, length: 50)
            }
        }
        
        return nil
    }
    
    private func getBlockRangeAt(position: Position, in module: Module) -> IDERange? {
        let statements = getStatements(from: module)
        
        for statement in statements {
            // Check if inside a function
            if case .functionDef(let funcDef) = statement {
                if position.lineNumber >= funcDef.lineno {
                    return IDERange(
                        startLineNumber: funcDef.lineno,
                        startColumn: 1,
                        endLineNumber: funcDef.lineno + funcDef.body.count,
                        endColumn: 1
                    )
                }
            }
            
            // Check if inside a class
            if case .classDef(let classDef) = statement {
                if position.lineNumber >= classDef.lineno {
                    return IDERange(
                        startLineNumber: classDef.lineno,
                        startColumn: 1,
                        endLineNumber: classDef.lineno + classDef.body.count,
                        endColumn: 1
                    )
                }
            }
        }
        
        return nil
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
    
    // MARK: - Semantic Tokens Provider
    
    /// Get semantic tokens for syntax highlighting
    public func getSemanticTokens() -> SemanticTokens? {
        guard let ast = ast else { return nil }
        
        let builder = SemanticTokensBuilder()
        
        // Walk the AST and generate tokens
        let statements = getStatements(from: ast)
        for statement in statements {
            classifyStatement(statement, builder: builder)
        }
        
        return SemanticTokens(resultId: nil, data: builder.build())
    }
    
    private func classifyStatement(_ statement: Statement, builder: SemanticTokensBuilder) {
        switch statement {
        case .functionDef(let funcDef):
            // Function name as function token
            let line = funcDef.lineno
            builder.push(
                line: line,
                startChar: funcDef.colOffset,
                length: funcDef.name.count,
                tokenType: .function,
                tokenModifiers: [.definition]
            )
            
            // Parameters (Arg doesn't have lineno/colOffset, skip for now)
            // TODO: Add parameter token classification when we have proper AST traversal
            
        case .classDef(let classDef):
            // Class name as class token
            let line = classDef.lineno
            builder.push(
                line: line,
                startChar: classDef.colOffset,
                length: classDef.name.count,
                tokenType: .class,
                tokenModifiers: [.definition]
            )
            
        case .assign(let assign):
            // Variables
            for target in assign.targets {
                if case .name(let name) = target {
                    let line = name.lineno
                    builder.push(
                        line: line,
                        startChar: name.colOffset,
                        length: name.id.count,
                        tokenType: .variable,
                        tokenModifiers: []
                    )
                }
            }
            
        default:
            break
        }
        
        // TODO: Add more token classification for expressions, imports, etc.
    }
    
    // MARK: - Document Formatting Provider
    
    /// Format the entire document
    public func formatDocument(options: FormattingOptions) -> [TextEdit] {
        // TODO: Implement PEP 8 formatting
        // This would integrate with Black, autopep8, or yapf
        var edits: [TextEdit] = []
        
        // Example: Fix indentation issues
        for (index, line) in sourceLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // Calculate expected indentation
            let expectedIndent = calculateIndentation(at: index + 1)
            let currentIndent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            
            if currentIndent != expectedIndent {
                let newIndent = String(repeating: options.insertSpaces ? " " : "\t", 
                                      count: options.insertSpaces ? expectedIndent : expectedIndent / options.tabSize)
                
                edits.append(TextEdit(
                    range: IDERange(
                        startLineNumber: index + 1,
                        startColumn: 1,
                        endLineNumber: index + 1,
                        endColumn: currentIndent + 1
                    ),
                    newText: newIndent
                ))
            }
        }
        
        return edits
    }
    
    /// Format a range of the document
    public func formatRange(_ range: IDERange, options: FormattingOptions) -> [TextEdit] {
        // TODO: Implement range formatting
        // Similar to formatDocument but only for selected lines
        let startLine = range.startLineNumber - 1
        let endLine = min(range.endLineNumber, sourceLines.count) - 1
        
        var edits: [TextEdit] = []
        
        for lineIndex in startLine...endLine {
            guard lineIndex < sourceLines.count else { break }
            let line = sourceLines[lineIndex]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // Apply formatting to this line
            let expectedIndent = calculateIndentation(at: lineIndex + 1)
            let currentIndent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            
            if currentIndent != expectedIndent {
                let newIndent = String(repeating: options.insertSpaces ? " " : "\t",
                                      count: options.insertSpaces ? expectedIndent : expectedIndent / options.tabSize)
                
                edits.append(TextEdit(
                    range: IDERange(
                        startLineNumber: lineIndex + 1,
                        startColumn: 1,
                        endLineNumber: lineIndex + 1,
                        endColumn: currentIndent + 1
                    ),
                    newText: newIndent
                ))
            }
        }
        
        return edits
    }
    
    /// Format on typing (auto-format after certain characters)
    public func formatOnType(at position: Position, character: String, options: FormattingOptions) -> [TextEdit] {
        // Auto-format after typing colon, newline, etc.
        var edits: [TextEdit] = []
        
        if character == ":" {
            // After colon in function def, class def, if/for/while, etc.
            // Ensure proper spacing
            let lineIndex = position.lineNumber - 1
            guard lineIndex < sourceLines.count else { return [] }
            
            let line = sourceLines[lineIndex]
            if line.hasSuffix(":") && !line.hasSuffix(" :") {
                // TODO: Add spacing before colon if needed
            }
        } else if character == "\n" {
            // Auto-indent new line
            let indent = calculateIndentation(at: position.lineNumber)
            let indentString = String(repeating: options.insertSpaces ? " " : "\t",
                                     count: options.insertSpaces ? indent : indent / options.tabSize)
            
            edits.append(TextEdit(
                range: IDERange(
                    startLineNumber: position.lineNumber,
                    startColumn: 1,
                    endLineNumber: position.lineNumber,
                    endColumn: 1
                ),
                newText: indentString
            ))
        }
        
        return edits
    }
    
    private func calculateIndentation(at line: Int) -> Int {
        // TODO: Calculate expected indentation based on AST structure
        // For now, use simple heuristic
        guard line > 1 && line <= sourceLines.count else { return 0 }
        
        let prevLine = sourceLines[line - 2]
        let prevIndent = prevLine.prefix(while: { $0 == " " || $0 == "\t" }).count
        
        if prevLine.trimmingCharacters(in: .whitespaces).hasSuffix(":") {
            return prevIndent + 4 // Increase indent after colon
        }
        
        return prevIndent
    }
    
    // MARK: - Document Link Provider
    
    /// Get document links (clickable imports)
    public func getLinks() -> [DocumentLink] {
        var links: [DocumentLink] = []
        
        guard let ast = ast else { return [] }
        
        let statements = getStatements(from: ast)
        for statement in statements {
            switch statement {
            case .importStmt(let imp):
                for alias in imp.names {
                    let line = imp.lineno
                    let range = IDERange(
                        startLineNumber: line,
                        startColumn: imp.colOffset + 7, // After "import "
                        endLineNumber: line,
                        endColumn: imp.colOffset + 7 + alias.name.count
                    )
                    
                    links.append(DocumentLink(
                        range: range,
                        url: "file://\(alias.name.replacingOccurrences(of: ".", with: "/")).py",
                        tooltip: "Open \(alias.name)"
                    ))
                }
                
            case .importFrom(let impFrom):
                if let moduleName = impFrom.module {
                    let line = impFrom.lineno
                    let range = IDERange(
                        startLineNumber: line,
                        startColumn: impFrom.colOffset + 5, // After "from "
                        endLineNumber: line,
                        endColumn: impFrom.colOffset + 5 + moduleName.count
                    )
                    
                    links.append(DocumentLink(
                        range: range,
                        url: "file://\(moduleName.replacingOccurrences(of: ".", with: "/")).py",
                        tooltip: "Open \(moduleName)"
                    ))
                }
                
            default:
                break
            }
        }
        
        return links
    }
    
    // MARK: - Color Provider
    
    /// Get color information from the document
    public func getColors() -> [ColorInformation] {
        var colors: [ColorInformation] = []
        
        // Find color literals in the source (hex colors, RGB, etc.)
        for (index, line) in sourceLines.enumerated() {
            // Match hex colors like "#FF0000" or "#FF0000FF"
            let hexPattern = #"#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?"#
            if let regex = try? NSRegularExpression(pattern: hexPattern) {
                let nsLine = line as NSString
                let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
                
                for match in matches {
                    let hexString = nsLine.substring(with: match.range)
                    if let color = Color.fromHex(hexString) {
                        colors.append(ColorInformation(
                            range: IDERange(
                                startLineNumber: index + 1,
                                startColumn: match.range.location + 1,
                                endLineNumber: index + 1,
                                endColumn: match.range.location + match.range.length + 1
                            ),
                            color: color
                        ))
                    }
                }
            }
        }
        
        // TODO: Also match rgb(), rgba(), color names, etc.
        
        return colors
    }
    
    /// Get color presentations for a color at a given range
    public func getColorPresentations(color: Color, at range: IDERange) -> [ColorPresentation] {
        var presentations: [ColorPresentation] = []
        
        // Hex format
        presentations.append(ColorPresentation(
            label: color.toHex(includeAlpha: false),
            textEdit: TextEdit(range: range, newText: color.toHex(includeAlpha: false))
        ))
        
        // Hex with alpha
        if color.alpha < 1.0 {
            presentations.append(ColorPresentation(
                label: color.toHex(includeAlpha: true),
                textEdit: TextEdit(range: range, newText: color.toHex(includeAlpha: true))
            ))
        }
        
        // RGB format
        let r = Int(color.red * 255)
        let g = Int(color.green * 255)
        let b = Int(color.blue * 255)
        presentations.append(ColorPresentation(
            label: "rgb(\(r), \(g), \(b))",
            textEdit: TextEdit(range: range, newText: "rgb(\(r), \(g), \(b))")
        ))
        
        // RGBA format if alpha < 1
        if color.alpha < 1.0 {
            presentations.append(ColorPresentation(
                label: "rgba(\(r), \(g), \(b), \(color.alpha))",
                textEdit: TextEdit(range: range, newText: "rgba(\(r), \(g), \(b), \(color.alpha))")
            ))
        }
        
        return presentations
    }
    
    // MARK: - Call Hierarchy Provider
    
    /// Prepare call hierarchy for a position
    public func prepareCallHierarchy(at position: Position) -> [CallHierarchyItem]? {
        guard let ast = ast else { return nil }
        
        // Find the function at the given position
        let statements = getStatements(from: ast)
        for statement in statements {
            if case .functionDef(let funcDef) = statement {
                let line = funcDef.lineno
                if line == position.lineNumber {
                    let range = IDERange(
                        startLineNumber: line,
                        startColumn: funcDef.colOffset,
                        endLineNumber: line + funcDef.body.count,
                        endColumn: 1
                    )
                    
                    return [CallHierarchyItem(
                        name: funcDef.name,
                        kind: .function,
                        detail: "def \(funcDef.name)(...)",
                        uri: "document",
                        range: range,
                        selectionRange: IDERange(
                            startLineNumber: line,
                            startColumn: funcDef.colOffset,
                            endLineNumber: line,
                            endColumn: funcDef.colOffset + funcDef.name.count
                        )
                    )]
                }
            }
        }
        
        return nil
    }
    
    /// Get incoming calls (who calls this function)
    public func getIncomingCalls(for item: CallHierarchyItem) -> [CallHierarchyIncomingCall] {
        // TODO: Implement call graph analysis
        // Would need to scan entire codebase for calls to this function
        return []
    }
    
    /// Get outgoing calls (what this function calls)
    public func getOutgoingCalls(for item: CallHierarchyItem) -> [CallHierarchyOutgoingCall] {
        // TODO: Implement call analysis
        // Would need to analyze function body for function calls
        return []
    }
    
    // MARK: - Type Hierarchy Provider
    
    /// Prepare type hierarchy for a position
    public func prepareTypeHierarchy(at position: Position) -> [TypeHierarchyItem]? {
        guard let ast = ast else { return nil }
        
        // Find the class at the given position
        let statements = getStatements(from: ast)
        for statement in statements {
            if case .classDef(let classDef) = statement {
                let line = classDef.lineno
                if line == position.lineNumber {
                    let range = IDERange(
                        startLineNumber: line,
                        startColumn: classDef.colOffset,
                        endLineNumber: line + classDef.body.count,
                        endColumn: 1
                    )
                    
                    return [TypeHierarchyItem(
                        name: classDef.name,
                        kind: .class,
                        detail: "class \(classDef.name)",
                        uri: "document",
                        range: range,
                        selectionRange: IDERange(
                            startLineNumber: line,
                            startColumn: classDef.colOffset,
                            endLineNumber: line,
                            endColumn: classDef.colOffset + classDef.name.count
                        )
                    )]
                }
            }
        }
        
        return nil
    }
    
    /// Get supertypes (base classes)
    public func getSupertypes(for item: TypeHierarchyItem) -> [TypeHierarchyItem] {
        // TODO: Implement class hierarchy analysis
        // Would need to resolve base classes from the class definition
        return []
    }
    
    /// Get subtypes (derived classes)
    public func getSubtypes(for item: TypeHierarchyItem) -> [TypeHierarchyItem] {
        // TODO: Implement subclass search
        // Would need to scan codebase for classes that inherit from this class
        return []
    }
    
    // MARK: - Inline Values Provider
    
    /// Get inline values for debugging
    public func getInlineValues(at range: IDERange) -> [InlineValue] {
        var inlineValues: [InlineValue] = []
        
        // Find variables in the given range
        guard let ast = ast else { return [] }
        
        let statements = getStatements(from: ast)
        for statement in statements {
            // Look for variable assignments
            if case .assign(let assign) = statement {
                let line = assign.lineno
                if line >= range.startLineNumber && line <= range.endLineNumber {
                    for target in assign.targets {
                        if case .name(let name) = target {
                            inlineValues.append(.variableLookup(InlineValueVariableLookup(
                                range: IDERange(
                                    startLineNumber: line,
                                    startColumn: name.colOffset,
                                    endLineNumber: line,
                                    endColumn: name.colOffset + name.id.count
                                ),
                                variableName: name.id,
                                caseSensitiveLookup: true
                            )))
                        }
                    }
                }
            }
        }
        
        return inlineValues
    }
}
