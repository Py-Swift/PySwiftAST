import Foundation
import PySwiftAST
import MonacoApi

/// Provides Monaco Editor language features for Python code analysis
public class MonacoAnalyzer {
    private let validator: PythonValidator
    private let source: String
    private let sourceLines: [String]
    private var ast: Module?
    private var symbolTable: SymbolTable?
    
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
        
        // Build symbol table when AST is available
        if let ast = result.ast {
            self.symbolTable = SymbolTable(ast: ast)
        }
        
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
        
        // Find the node at the given position (statement or expression)
        if let node = findNodeAt(position: position, in: ast) {
            return generateHover(for: node, at: position)
        }
        
        // Try to find expression-level hover info
        if let exprHover = findExpressionHover(at: position, in: ast) {
            return exprHover
        }
        
        return nil
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
        
        // Add built-in type methods (str, list, dict, set, etc.)
        items.append(contentsOf: getBuiltinTypeCompletions())
        
        // Add sequence operations and utilities
        items.append(contentsOf: getSequenceOperations())
        
        // Add numeric types and special attributes
        items.append(contentsOf: getNumericAndSpecialCompletions())
        
        // Add itertools module completions
        items.append(contentsOf: getItertoolsCompletions())
        
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
            return generateFunctionHover(funcDef, isAsync: false)
            
        case .asyncFunctionDef(let funcDef):
            return generateAsyncFunctionHover(funcDef)
            
        case .classDef(let classDef):
            return generateClassHover(classDef)
            
        case .assign(let assign):
            return generateAssignmentHover(assign)
            
        case .annAssign(let annAssign):
            return generateAnnotatedAssignmentHover(annAssign)
            
        default:
            return nil
        }
    }
    
    private func generateFunctionHover(_ funcDef: FunctionDef, isAsync: Bool) -> Hover? {
        var parts: [String] = []
        
        // Build function signature
        var signature = isAsync ? "async def " : "def "
        signature += "\(funcDef.name)("
        
        // Build parameter list with type annotations
        var paramParts: [String] = []
        
        // Position-only arguments
        for arg in funcDef.args.posonlyArgs {
            paramParts.append(formatParameter(arg))
        }
        if !funcDef.args.posonlyArgs.isEmpty {
            paramParts.append("/")
        }
        
        // Regular arguments
        for (index, arg) in funcDef.args.args.enumerated() {
            var param = formatParameter(arg)
            let defaultIndex = funcDef.args.defaults.count - funcDef.args.args.count + index
            if defaultIndex >= 0 && defaultIndex < funcDef.args.defaults.count {
                param += " = ..."
            }
            paramParts.append(param)
        }
        
        // *args
        if let vararg = funcDef.args.vararg {
            paramParts.append("*\(formatParameter(vararg))")
        } else if !funcDef.args.kwonlyArgs.isEmpty {
            paramParts.append("*")
        }
        
        // Keyword-only arguments
        for (index, arg) in funcDef.args.kwonlyArgs.enumerated() {
            var param = formatParameter(arg)
            if index < funcDef.args.kwDefaults.count, funcDef.args.kwDefaults[index] != nil {
                param += " = ..."
            }
            paramParts.append(param)
        }
        
        // **kwargs
        if let kwarg = funcDef.args.kwarg {
            paramParts.append("**\(formatParameter(kwarg))")
        }
        
        signature += paramParts.joined(separator: ", ")
        signature += ")"
        
        // Add return type if available
        if let returns = funcDef.returns {
            signature += " -> \(formatExpression(returns))"
        }
        signature += ":"
        
        parts.append("```python\n\(signature)\n```")
        
        // Extract docstring from function body
        if let docstring = extractDocstring(from: funcDef.body) {
            parts.append("---")
            parts.append(docstring)
        }
        
        return Hover.markdown(parts.joined(separator: "\n\n"))
    }
    
    private func generateAsyncFunctionHover(_ funcDef: AsyncFunctionDef) -> Hover? {
        let syncFuncDef = FunctionDef(
            name: funcDef.name,
            args: funcDef.args,
            body: funcDef.body,
            decoratorList: funcDef.decoratorList,
            returns: funcDef.returns,
            typeComment: funcDef.typeComment,
            typeParams: funcDef.typeParams,
            lineno: funcDef.lineno,
            colOffset: funcDef.colOffset,
            endLineno: funcDef.endLineno,
            endColOffset: funcDef.endColOffset
        )
        return generateFunctionHover(syncFuncDef, isAsync: true)
    }
    
    private func generateClassHover(_ classDef: ClassDef) -> Hover? {
        var parts: [String] = []
        
        var signature = "class \(classDef.name)"
        if !classDef.bases.isEmpty {
            let bases = classDef.bases.map { formatExpression($0) }.joined(separator: ", ")
            signature += "(\(bases))"
        }
        signature += ":"
        
        parts.append("```python\n\(signature)\n```")
        
        if let docstring = extractDocstring(from: classDef.body) {
            parts.append("---")
            parts.append(docstring)
        }
        
        return Hover.markdown(parts.joined(separator: "\n\n"))
    }
    
    private func generateAssignmentHover(_ assign: Assign) -> Hover? {
        let targets = assign.targets.compactMap { target -> String? in
            if case .name(let name) = target {
                return name.id
            }
            return nil
        }.joined(separator: ", ")
        
        if targets.isEmpty { return nil }
        
        let valuePreview = formatExpression(assign.value)
        let code = "\(targets) = \(valuePreview)"
        return Hover.code(code, language: "python")
    }
    
    private func generateAnnotatedAssignmentHover(_ annAssign: AnnAssign) -> Hover? {
        guard case .name(let name) = annAssign.target else { return nil }
        
        var code = "\(name.id): \(formatExpression(annAssign.annotation))"
        if let value = annAssign.value {
            code += " = \(formatExpression(value))"
        }
        
        return Hover.code(code, language: "python")
    }
    
    private func findExpressionHover(at position: Position, in module: Module) -> Hover? {
        let statements = getStatements(from: module)
        
        for statement in statements {
            if let hover = findExpressionHoverInStatement(statement, at: position) {
                return hover
            }
        }
        
        return nil
    }
    
    private func findExpressionHoverInStatement(_ statement: Statement, at position: Position) -> Hover? {
        switch statement {
        case .assign(let assign):
            for target in assign.targets {
                if let hover = findExpressionHoverInExpression(target, at: position) {
                    return hover
                }
            }
            if let hover = findExpressionHoverInExpression(assign.value, at: position) {
                return hover
            }
            
        case .expr(let expr):
            if let hover = findExpressionHoverInExpression(expr.value, at: position) {
                return hover
            }
            
        default:
            break
        }
        
        return nil
    }
    
    private func findExpressionHoverInExpression(_ expression: PySwiftAST.Expression, at position: Position) -> Hover? {
        if expression.lineno == position.lineNumber {
            switch expression {
            case .name(let name):
                return Hover.code(name.id, language: "python")
                
            case .constant(let constant):
                return Hover.markdown("**Constant**: `\(formatConstant(constant.value))`")
                
            case .call(let call):
                let funcName = formatExpression(call.fun)
                return Hover.markdown("**Call**: `\(funcName)(...)`")
                
            default:
                break
            }
        }
        
        return nil
    }
    
    private func extractDocstring(from body: [Statement]) -> String? {
        guard !body.isEmpty else { return nil }
        
        if case .expr(let expr) = body[0] {
            if case .constant(let constant) = expr.value {
                if case .string(let docstring) = constant.value {
                    return docstring.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return nil
    }
    
    private func formatParameter(_ arg: Arg) -> String {
        var result = arg.arg
        if let annotation = arg.annotation {
            result += ": \(formatExpression(annotation))"
        }
        return result
    }
    
    private func formatExpression(_ expression: PySwiftAST.Expression) -> String {
        switch expression {
        case .name(let name):
            return name.id
        case .constant(let constant):
            return formatConstant(constant.value)
        case .attribute(let attr):
            return "\(formatExpression(attr.value)).\(attr.attr)"
        case .subscriptExpr(let sub):
            return "\(formatExpression(sub.value))[...]"
        case .list:
            return "[...]"
        case .tuple:
            return "(...)"
        case .dict:
            return "{...}"
        case .set:
            return "{...}"
        default:
            return "..."
        }
    }
    
    private func formatConstant(_ value: ConstantValue) -> String {
        switch value {
        case .none:
            return "None"
        case .bool(let b):
            return b ? "True" : "False"
        case .int(let i):
            return "\(i)"
        case .float(let f):
            return "\(f)"
        case .complex(let real, let imag):
            return "\(real)+\(imag)j"
        case .string(let s):
            return "\"\"\"\n\(s)\n\"\"\""
        case .bytes(let data):
            return "b'\(data.prefix(20).map { String(format: "%02x", $0) }.joined())...'"
        case .ellipsis:
            return "..."
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
        let builtins: [(String, [String], String?)] = [
            ("print", ["*args", "sep=' '", "end='\\n'"], "Print values to stdout"),
            ("len", ["seq"], "Return the length (number of items) of a sequence"),
            ("range", ["start", "stop=None", "step=1"], "Create an immutable sequence of numbers"),
            ("str", ["object"], "Convert object to string"),
            ("int", ["x", "base=10"], "Convert to integer"),
            ("float", ["x"], "Convert to floating point number"),
            ("list", ["iterable"], "Create a list from an iterable"),
            ("dict", ["**kwargs"], "Create a dictionary"),
            ("set", ["iterable"], "Create a set from an iterable"),
            ("tuple", ["iterable"], "Create a tuple from an iterable"),
            ("open", ["file", "mode='r'"], "Open a file and return a file object"),
            ("type", ["object"], "Return the type of an object"),
            ("isinstance", ["obj", "classinfo"], "Check if object is an instance of a class"),
            ("enumerate", ["iterable", "start=0"], "Return an enumerate object yielding (index, value) pairs"),
            ("zip", ["*iterables", "strict=False"], "Iterate over several iterables in parallel"),
            ("map", ["function", "iterable", "*iterables"], "Apply function to every item of iterable"),
            ("filter", ["function", "iterable"], "Construct an iterator from elements of iterable for which function returns true")
        ]
        
        return builtins.map { name, params, doc in
            CompletionItem.function(name: name, parameters: params, documentation: doc)
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
    
    private func getBuiltinTypeCompletions() -> [CompletionItem] {
        var items: [CompletionItem] = []
        
        // String methods
        let strMethods: [(String, [String], String)] = [
            ("capitalize", [], "Return a capitalized version of the string"),
            ("casefold", [], "Return a casefolded copy suitable for caseless comparisons"),
            ("center", ["width", "fillchar=' '"], "Return a centered string of length width"),
            ("count", ["sub", "start=0", "end=len"], "Return the number of non-overlapping occurrences of substring sub"),
            ("encode", ["encoding='utf-8'", "errors='strict'"], "Encode the string using the codec registered for encoding"),
            ("endswith", ["suffix", "start=0", "end=len"], "Return True if the string ends with the specified suffix"),
            ("expandtabs", ["tabsize=8"], "Return a copy where all tab characters are expanded"),
            ("find", ["sub", "start=0", "end=len"], "Return the lowest index where substring sub is found"),
            ("format", ["*args", "**kwargs"], "Perform a string formatting operation"),
            ("format_map", ["mapping"], "Similar to format(**mapping)"),
            ("index", ["sub", "start=0", "end=len"], "Like find(), but raise ValueError when not found"),
            ("isalnum", [], "Return True if all characters are alphanumeric"),
            ("isalpha", [], "Return True if all characters are alphabetic"),
            ("isascii", [], "Return True if all characters are ASCII"),
            ("isdecimal", [], "Return True if all characters are decimal"),
            ("isdigit", [], "Return True if all characters are digits"),
            ("isidentifier", [], "Return True if the string is a valid Python identifier"),
            ("islower", [], "Return True if all cased characters are lowercase"),
            ("isnumeric", [], "Return True if all characters are numeric"),
            ("isprintable", [], "Return True if all characters are printable"),
            ("isspace", [], "Return True if all characters are whitespace"),
            ("istitle", [], "Return True if the string is titlecased"),
            ("isupper", [], "Return True if all cased characters are uppercase"),
            ("join", ["iterable"], "Concatenate strings in iterable with separator"),
            ("ljust", ["width", "fillchar=' '"], "Return a left-justified string of length width"),
            ("lower", [], "Return a copy with all characters converted to lowercase"),
            ("lstrip", ["chars=None"], "Return a copy with leading whitespace removed"),
            ("maketrans", ["x", "y=None", "z=None"], "Return a translation table"),
            ("partition", ["sep"], "Split at the first occurrence of sep"),
            ("removeprefix", ["prefix"], "Remove prefix if present (Python 3.9+)"),
            ("removesuffix", ["suffix"], "Remove suffix if present (Python 3.9+)"),
            ("replace", ["old", "new", "count=-1"], "Return a copy with all occurrences of old replaced by new"),
            ("rfind", ["sub", "start=0", "end=len"], "Return the highest index where substring sub is found"),
            ("rindex", ["sub", "start=0", "end=len"], "Like rfind(), but raise ValueError when not found"),
            ("rjust", ["width", "fillchar=' '"], "Return a right-justified string of length width"),
            ("rpartition", ["sep"], "Split at the last occurrence of sep"),
            ("rsplit", ["sep=None", "maxsplit=-1"], "Return a list of words, splitting from the right"),
            ("rstrip", ["chars=None"], "Return a copy with trailing whitespace removed"),
            ("split", ["sep=None", "maxsplit=-1"], "Return a list of words in the string"),
            ("splitlines", ["keepends=False"], "Return a list of lines in the string"),
            ("startswith", ["prefix", "start=0", "end=len"], "Return True if string starts with the prefix"),
            ("strip", ["chars=None"], "Return a copy with leading and trailing whitespace removed"),
            ("swapcase", [], "Return a copy with uppercase converted to lowercase and vice versa"),
            ("title", [], "Return a titlecased version"),
            ("translate", ["table"], "Replace characters using translation table"),
            ("upper", [], "Return a copy with all characters converted to uppercase"),
            ("zfill", ["width"], "Pad a numeric string with zeros on the left")
        ]
        
        // List methods
        let listMethods: [(String, [String], String)] = [
            ("append", ["object"], "Append object to the end of the list"),
            ("clear", [], "Remove all items from the list"),
            ("copy", [], "Return a shallow copy of the list"),
            ("count", ["value"], "Return number of occurrences of value"),
            ("extend", ["iterable"], "Extend list by appending elements from the iterable"),
            ("index", ["value", "start=0", "stop=len"], "Return first index of value"),
            ("insert", ["index", "object"], "Insert object before index"),
            ("pop", ["index=-1"], "Remove and return item at index (default last)"),
            ("remove", ["value"], "Remove first occurrence of value"),
            ("reverse", [], "Reverse the list in place"),
            ("sort", ["key=None", "reverse=False"], "Sort the list in ascending order")
        ]
        
        // Dict methods
        let dictMethods: [(String, [String], String)] = [
            ("clear", [], "Remove all items from the dictionary"),
            ("copy", [], "Return a shallow copy of the dictionary"),
            ("fromkeys", ["iterable", "value=None"], "Create a new dictionary with keys from iterable"),
            ("get", ["key", "default=None"], "Return value for key if key is in dictionary"),
            ("items", [], "Return a view of the dictionary's (key, value) pairs"),
            ("keys", [], "Return a view of the dictionary's keys"),
            ("pop", ["key", "default=None"], "Remove key and return value, or default if key not found"),
            ("popitem", [], "Remove and return a (key, value) pair"),
            ("setdefault", ["key", "default=None"], "Get value of key, set to default if not present"),
            ("update", ["other"], "Update dictionary with key/value pairs from other"),
            ("values", [], "Return a view of the dictionary's values")
        ]
        
        // Set methods
        let setMethods: [(String, [String], String)] = [
            ("add", ["elem"], "Add element elem to the set"),
            ("clear", [], "Remove all elements from the set"),
            ("copy", [], "Return a shallow copy of the set"),
            ("difference", ["*others"], "Return the difference of two or more sets"),
            ("difference_update", ["*others"], "Remove all elements of other sets from this set"),
            ("discard", ["elem"], "Remove element elem from the set if present"),
            ("intersection", ["*others"], "Return the intersection of two or more sets"),
            ("intersection_update", ["*others"], "Update set with intersection of itself and others"),
            ("isdisjoint", ["other"], "Return True if two sets have a null intersection"),
            ("issubset", ["other"], "Test whether every element is in other"),
            ("issuperset", ["other"], "Test whether every element of other is in the set"),
            ("pop", [], "Remove and return an arbitrary element"),
            ("remove", ["elem"], "Remove element elem from the set, raise KeyError if not found"),
            ("symmetric_difference", ["other"], "Return symmetric difference of two sets"),
            ("symmetric_difference_update", ["other"], "Update set with symmetric difference"),
            ("union", ["*others"], "Return the union of sets"),
            ("update", ["*others"], "Update set with union of itself and others")
        ]
        
        // Bytes/bytearray methods (common subset)
        let bytesMethods: [(String, [String], String)] = [
            ("count", ["sub", "start=0", "end=len"], "Return the number of non-overlapping occurrences"),
            ("decode", ["encoding='utf-8'", "errors='strict'"], "Decode bytes to string"),
            ("endswith", ["suffix", "start=0", "end=len"], "Return True if bytes ends with suffix"),
            ("find", ["sub", "start=0", "end=len"], "Return the lowest index where sub is found"),
            ("hex", ["sep=''", "bytes_per_sep=1"], "Return hexadecimal representation"),
            ("index", ["sub", "start=0", "end=len"], "Like find(), but raise ValueError when not found"),
            ("join", ["iterable"], "Concatenate bytes objects in iterable"),
            ("replace", ["old", "new", "count=-1"], "Return a copy with occurrences of old replaced by new"),
            ("split", ["sep=None", "maxsplit=-1"], "Return a list of bytes"),
            ("startswith", ["prefix", "start=0", "end=len"], "Return True if bytes starts with prefix"),
            ("strip", ["bytes=None"], "Return bytes with leading and trailing bytes removed")
        ]
        
        // Add string methods
        for (name, params, doc) in strMethods {
            items.append(CompletionItem.function(
                name: "str.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        // Add list methods
        for (name, params, doc) in listMethods {
            items.append(CompletionItem.function(
                name: "list.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        // Add dict methods
        for (name, params, doc) in dictMethods {
            items.append(CompletionItem.function(
                name: "dict.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        // Add set methods
        for (name, params, doc) in setMethods {
            items.append(CompletionItem.function(
                name: "set.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        // Add frozenset methods (subset of set methods that don't modify)
        let frozensetMethods = ["copy", "difference", "intersection", "isdisjoint", "issubset", "issuperset", "symmetric_difference", "union"]
        for method in frozensetMethods {
            if let setMethod = setMethods.first(where: { $0.0 == method }) {
                items.append(CompletionItem.function(
                    name: "frozenset.\(setMethod.0)",
                    parameters: setMethod.1,
                    documentation: setMethod.2
                ))
            }
        }
        
        // Add bytes methods
        for (name, params, doc) in bytesMethods {
            items.append(CompletionItem.function(
                name: "bytes.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        // Add bytearray methods (includes bytes methods + mutating methods)
        for (name, params, doc) in bytesMethods {
            items.append(CompletionItem.function(
                name: "bytearray.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        // Additional bytearray-only methods (mutating)
        let bytearrayOnly: [(String, [String], String)] = [
            ("append", ["item"], "Append a single byte"),
            ("clear", [], "Remove all items from the bytearray"),
            ("extend", ["iterable"], "Extend bytearray by appending elements"),
            ("insert", ["index", "item"], "Insert a single byte before index"),
            ("pop", ["index=-1"], "Remove and return byte at index"),
            ("remove", ["value"], "Remove first occurrence of value"),
            ("reverse", [], "Reverse the bytearray in place")
        ]
        
        for (name, params, doc) in bytearrayOnly {
            items.append(CompletionItem.function(
                name: "bytearray.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        // Tuple methods (immutable, so minimal)
        let tupleMethods: [(String, [String], String)] = [
            ("count", ["value"], "Return number of occurrences of value"),
            ("index", ["value", "start=0", "stop=len"], "Return first index of value")
        ]
        
        for (name, params, doc) in tupleMethods {
            items.append(CompletionItem.function(
                name: "tuple.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        return items
    }
    
    // MARK: - Sequence Operations and Iterator Protocol
    
    /// Returns completions for sequence operations, range type, and iterator protocol
    private func getSequenceOperations() -> [CompletionItem] {
        var items: [CompletionItem] = []
        
        // Range type (Python 3.x)
        let rangeMethods: [(String, [String], String)] = [
            ("start", [], "The start value of the range"),
            ("stop", [], "The stop value of the range"),
            ("step", [], "The step value of the range"),
            ("count", ["value"], "Return number of occurrences of value"),
            ("index", ["value"], "Return first index of value")
        ]
        
        for (name, params, doc) in rangeMethods {
            if params.isEmpty {
                // Properties accessed as attributes, not methods
                items.append(CompletionItem.variable(name: "range.\(name)", type: "int"))
            } else {
                items.append(CompletionItem.function(
                    name: "range.\(name)",
                    parameters: params,
                    documentation: doc
                ))
            }
        }
        
        // Common sequence operations (work on list, tuple, str, range, bytes, etc.)
        let sequenceOps: [(String, [String], String)] = [
            ("len", ["seq"], "Return the length (number of items) of a sequence"),
            ("min", ["seq", "key=None", "default=None"], "Return the smallest item in a sequence"),
            ("max", ["seq", "key=None", "default=None"], "Return the largest item in a sequence"),
            ("sum", ["iterable", "start=0"], "Return the sum of items in an iterable"),
            ("any", ["iterable"], "Return True if any element is true"),
            ("all", ["iterable"], "Return True if all elements are true"),
            ("sorted", ["iterable", "key=None", "reverse=False"], "Return a sorted list from items in iterable"),
            ("reversed", ["seq"], "Return a reverse iterator"),
            ("enumerate", ["iterable", "start=0"], "Return an enumerate object yielding (index, value) pairs"),
            ("zip", ["*iterables", "strict=False"], "Iterate over several iterables in parallel"),
            ("filter", ["function", "iterable"], "Construct an iterator from elements of iterable for which function returns true"),
            ("map", ["function", "iterable", "*iterables"], "Apply function to every item of iterable"),
            ("slice", ["start", "stop=None", "step=None"], "Create a slice object")
        ]
        
        for (name, params, doc) in sequenceOps {
            // These are already in builtins but adding docs
            if !items.contains(where: { $0.label == name }) {
                items.append(CompletionItem.function(
                    name: name,
                    parameters: params,
                    documentation: doc
                ))
            }
        }
        
        // Iterator protocol methods (dunder methods)
        let iteratorMethods: [(String, [String], String)] = [
            ("__iter__", [], "Return an iterator object. Required for iterables"),
            ("__next__", [], "Return the next item from the iterator. Raise StopIteration when exhausted"),
            ("__reversed__", [], "Return a reverse iterator"),
            ("__length_hint__", [], "Return an estimated length for the object (optional)")
        ]
        
        for (name, params, doc) in iteratorMethods {
            items.append(CompletionItem.function(
                name: name,
                parameters: params,
                documentation: doc
            ))
        }
        
        // Iterable utility functions
        let iterableUtils: [(String, [String], String)] = [
            ("iter", ["object", "sentinel=None"], "Return an iterator object. With two arguments, creates a sentinel iterator"),
            ("next", ["iterator", "default=None"], "Retrieve the next item from the iterator by calling __next__()"),
            ("range", ["start", "stop=None", "step=1"], "Create an immutable sequence of numbers")
        ]
        
        for (name, params, doc) in iterableUtils {
            if !items.contains(where: { $0.label == name }) {
                items.append(CompletionItem.function(
                    name: name,
                    parameters: params,
                    documentation: doc
                ))
            }
        }
        
        return items
    }
    
    // MARK: - Numeric Types and Special Attributes
    
    /// Returns completions for numeric type methods and special attributes
    private func getNumericAndSpecialCompletions() -> [CompletionItem] {
        var items: [CompletionItem] = []
        
        // Integer methods (int type)
        let intMethods: [(String, [String], String)] = [
            ("bit_length", [], "Return number of bits necessary to represent integer in binary"),
            ("bit_count", [], "Return number of ones in binary representation"),
            ("to_bytes", ["length=1", "byteorder='big'", "signed=False"], "Return array of bytes representing integer"),
            ("from_bytes", ["bytes", "byteorder='big'", "signed=False"], "Return integer represented by byte array (class method)"),
            ("as_integer_ratio", [], "Return pair of integers whose ratio equals the original"),
            ("is_integer", [], "Returns True (for duck-type compatibility with float)")
        ]
        
        for (name, params, doc) in intMethods {
            items.append(CompletionItem.function(
                name: "int.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        // Float methods
        let floatMethods: [(String, [String], String)] = [
            ("as_integer_ratio", [], "Return pair of integers whose ratio equals the float"),
            ("is_integer", [], "Return True if float has integral value"),
            ("hex", [], "Return hexadecimal representation of float"),
            ("fromhex", ["s"], "Create float from hexadecimal string (class method)")
        ]
        
        for (name, params, doc) in floatMethods {
            items.append(CompletionItem.function(
                name: "float.\(name)",
                parameters: params,
                documentation: doc
            ))
        }
        
        // Complex number attributes
        let complexAttrs: [(String, String)] = [
            ("real", "The real part of complex number"),
            ("imag", "The imaginary part of complex number")
        ]
        
        for (name, _) in complexAttrs {
            items.append(CompletionItem.variable(name: "complex.\(name)", type: "float"))
        }
        
        items.append(CompletionItem.function(
            name: "complex.conjugate",
            parameters: [],
            documentation: "Return complex conjugate"
        ))
        
        // Boolean constants
        items.append(CompletionItem.constant(
            name: "True",
            value: "True",
            documentation: "Boolean true constant"
        ))
        items.append(CompletionItem.constant(
            name: "False",
            value: "False",
            documentation: "Boolean false constant"
        ))
        
        // Special singleton objects
        items.append(CompletionItem.constant(
            name: "None",
            value: "None",
            documentation: "The null object - represents absence of value"
        ))
        items.append(CompletionItem.constant(
            name: "Ellipsis",
            value: "...",
            documentation: "The ellipsis object - commonly used to indicate omission"
        ))
        items.append(CompletionItem.constant(
            name: "...",
            value: "...",
            documentation: "The ellipsis literal - same as Ellipsis"
        ))
        items.append(CompletionItem.constant(
            name: "NotImplemented",
            value: "NotImplemented",
            documentation: "Returned from comparisons and binary ops on unsupported types"
        ))
        
        // Special method attributes  
        let specialAttrs: [(String, String, String)] = [
            ("__name__", "str", "Name of class, function, method, descriptor, or generator"),
            ("__qualname__", "str", "Qualified name of class, function, method, or descriptor"),
            ("__module__", "str", "Name of module in which class or function was defined"),
            ("__doc__", "str", "Documentation string, or None if undefined"),
            ("__dict__", "dict", "Dictionary containing object's namespace"),
            ("__class__", "type", "Class of an instance"),
            ("__annotations__", "dict", "Dictionary of variable annotations"),
            ("__code__", "code", "Code object (for functions)"),
            ("__func__", "function", "Underlying function (for methods)"),
            ("__self__", "object", "Instance bound to method")
        ]
        
        for (name, type, _) in specialAttrs {
            items.append(CompletionItem.variable(name: name, type: type))
        }
        
        return items
    }
    
    private func getItertoolsCompletions() -> [CompletionItem] {
        var items: [CompletionItem] = []
        
        // Infinite iterators
        items.append(CompletionItem.function(
            name: "itertools.count",
            parameters: ["start=0", "step=1"],
            documentation: "Make iterator returning evenly spaced values starting with start"
        ))
        items.append(CompletionItem.function(
            name: "itertools.cycle",
            parameters: ["iterable"],
            documentation: "Make iterator returning elements from iterable and saving a copy. Repeats indefinitely"
        ))
        items.append(CompletionItem.function(
            name: "itertools.repeat",
            parameters: ["object", "times=None"],
            documentation: "Make iterator that returns object over and over again. Runs indefinitely unless times specified"
        ))
        
        // Iterators terminating on shortest input sequence
        items.append(CompletionItem.function(
            name: "itertools.accumulate",
            parameters: ["iterable", "function=operator.add", "initial=None"],
            documentation: "Make iterator that returns accumulated sums or accumulated results from binary functions"
        ))
        items.append(CompletionItem.function(
            name: "itertools.batched",
            parameters: ["iterable", "n", "strict=False"],
            documentation: "Batch data from iterable into tuples of length n. Last batch may be shorter unless strict=True"
        ))
        items.append(CompletionItem.function(
            name: "itertools.chain",
            parameters: ["*iterables"],
            documentation: "Make iterator that returns elements from first iterable until exhausted, then next iterable"
        ))
        items.append(CompletionItem.function(
            name: "itertools.chain.from_iterable",
            parameters: ["iterable"],
            documentation: "Alternate constructor for chain(). Gets chained inputs from single iterable"
        ))
        items.append(CompletionItem.function(
            name: "itertools.compress",
            parameters: ["data", "selectors"],
            documentation: "Make iterator that returns elements from data where corresponding selector is true"
        ))
        items.append(CompletionItem.function(
            name: "itertools.dropwhile",
            parameters: ["predicate", "iterable"],
            documentation: "Make iterator that drops elements while predicate is true, then returns every element"
        ))
        items.append(CompletionItem.function(
            name: "itertools.filterfalse",
            parameters: ["predicate", "iterable"],
            documentation: "Make iterator that filters elements returning only those where predicate is false"
        ))
        items.append(CompletionItem.function(
            name: "itertools.groupby",
            parameters: ["iterable", "key=None"],
            documentation: "Make iterator returning consecutive keys and groups from iterable"
        ))
        items.append(CompletionItem.function(
            name: "itertools.islice",
            parameters: ["iterable", "stop"],
            documentation: "Make iterator that returns selected elements from iterable. islice(iterable, start, stop, step)"
        ))
        items.append(CompletionItem.function(
            name: "itertools.pairwise",
            parameters: ["iterable"],
            documentation: "Return successive overlapping pairs taken from input iterable"
        ))
        items.append(CompletionItem.function(
            name: "itertools.starmap",
            parameters: ["function", "iterable"],
            documentation: "Make iterator that computes function using arguments obtained from iterable"
        ))
        items.append(CompletionItem.function(
            name: "itertools.takewhile",
            parameters: ["predicate", "iterable"],
            documentation: "Make iterator that returns elements as long as predicate is true"
        ))
        items.append(CompletionItem.function(
            name: "itertools.tee",
            parameters: ["iterable", "n=2"],
            documentation: "Return n independent iterators from single iterable"
        ))
        items.append(CompletionItem.function(
            name: "itertools.zip_longest",
            parameters: ["*iterables", "fillvalue=None"],
            documentation: "Make iterator that aggregates elements from iterables. Continues until longest is exhausted"
        ))
        
        // Combinatoric iterators
        items.append(CompletionItem.function(
            name: "itertools.product",
            parameters: ["*iterables", "repeat=1"],
            documentation: "Cartesian product of input iterables. Equivalent to nested for-loops"
        ))
        items.append(CompletionItem.function(
            name: "itertools.permutations",
            parameters: ["iterable", "r=None"],
            documentation: "Return r-length permutations of elements from iterable"
        ))
        items.append(CompletionItem.function(
            name: "itertools.combinations",
            parameters: ["iterable", "r"],
            documentation: "Return r-length subsequences of elements from iterable (no repeated elements)"
        ))
        items.append(CompletionItem.function(
            name: "itertools.combinations_with_replacement",
            parameters: ["iterable", "r"],
            documentation: "Return r-length subsequences allowing individual elements to be repeated"
        ))
        
        return items
    }
    
    // MARK: - Contextual Completions
    
    private func getContextualCompletions(at position: Position, in module: Module) -> [CompletionItem] {
        var items: [CompletionItem] = []
        
        guard let symbolTable = symbolTable else {
            // Fallback to basic AST traversal
            return getBasicContextualCompletions(in: module)
        }
        
        // Add all defined functions
        for symbol in symbolTable.functions {
            let params = symbol.parameters.map { $0.name }
            items.append(CompletionItem.function(
                name: symbol.name,
                parameters: params,
                documentation: symbol.docstring
            ))
        }
        
        // Add all defined classes
        for symbol in symbolTable.classes {
            items.append(CompletionItem.class(
                name: symbol.name,
                documentation: symbol.docstring
            ))
        }
        
        // Add all variables in scope
        for symbol in symbolTable.variables {
            items.append(CompletionItem.variable(
                name: symbol.name,
                type: symbol.typeAnnotation
            ))
        }
        
        // Add all imports
        for symbol in symbolTable.imports {
            items.append(CompletionItem.variable(
                name: symbol.name,
                type: "module"
            ))
        }
        
        return items
    }
    
    private func getBasicContextualCompletions(in module: Module) -> [CompletionItem] {
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
        
        // Extract imports
        for statement in statements {
            switch statement {
            case .importStmt(let imp):
                for alias in imp.names {
                    let name = alias.asName ?? alias.name
                    items.append(CompletionItem.variable(name: name, type: "module"))
                }
            case .importFrom(let impFrom):
                for alias in impFrom.names {
                    let name = alias.asName ?? alias.name
                    items.append(CompletionItem.variable(name: name, type: "module"))
                }
            default:
                break
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
        // Try symbol table first for faster lookup
        if let symbolTable = symbolTable {
            if symbol.kind == .function {
                if let funcSym = symbolTable.functions.first(where: { $0.name == symbol.name }) {
                    return Location(
                        uri: "document",
                        range: IDERange.from(line: funcSym.line, column: funcSym.column, length: funcSym.name.count)
                    )
                }
            } else if symbol.kind == .class {
                if let classSym = symbolTable.classes.first(where: { $0.name == symbol.name }) {
                    return Location(
                        uri: "document",
                        range: IDERange.from(line: classSym.line, column: classSym.column, length: classSym.name.count)
                    )
                }
            } else if symbol.kind == .variable {
                if let varSym = symbolTable.variables.first(where: { $0.name == symbol.name }) {
                    return Location(
                        uri: "document",
                        range: IDERange.from(line: varSym.line, column: varSym.column, length: varSym.name.count)
                    )
                }
            }
        }
        
        // Fallback to AST traversal
        let statements = getStatements(from: module)
        
        for statement in statements {
            if let location = findDefinitionInStatement(statement, symbolName: symbol.name, kind: symbol.kind) {
                return location
            }
        }
        
        return nil
    }
    
    private func findDefinitionInStatement(_ statement: Statement, symbolName: String, kind: SymbolKind) -> Location? {
        switch statement {
        case .functionDef(let funcDef):
            if funcDef.name == symbolName && kind == .function {
                return Location(
                    uri: "document",
                    range: IDERange.from(line: funcDef.lineno, column: funcDef.colOffset, length: funcDef.name.count)
                )
            }
            // Search in nested statements
            for stmt in funcDef.body {
                if let location = findDefinitionInStatement(stmt, symbolName: symbolName, kind: kind) {
                    return location
                }
            }
            
        case .asyncFunctionDef(let funcDef):
            if funcDef.name == symbolName && kind == .function {
                return Location(
                    uri: "document",
                    range: IDERange.from(line: funcDef.lineno, column: funcDef.colOffset, length: funcDef.name.count)
                )
            }
            for stmt in funcDef.body {
                if let location = findDefinitionInStatement(stmt, symbolName: symbolName, kind: kind) {
                    return location
                }
            }
            
        case .classDef(let classDef):
            if classDef.name == symbolName && kind == .class {
                return Location(
                    uri: "document",
                    range: IDERange.from(line: classDef.lineno, column: classDef.colOffset, length: classDef.name.count)
                )
            }
            for stmt in classDef.body {
                if let location = findDefinitionInStatement(stmt, symbolName: symbolName, kind: kind) {
                    return location
                }
            }
            
        case .assign(let assign):
            if kind == .variable {
                for target in assign.targets {
                    if case .name(let name) = target, name.id == symbolName {
                        return Location(
                            uri: "document",
                            range: IDERange.from(line: name.lineno, column: name.colOffset, length: name.id.count)
                        )
                    }
                }
            }
            
        case .annAssign(let annAssign):
            if kind == .variable, case .name(let name) = annAssign.target, name.id == symbolName {
                return Location(
                    uri: "document",
                    range: IDERange.from(line: name.lineno, column: name.colOffset, length: name.id.count)
                )
            }
            
        case .ifStmt(let ifStmt):
            for stmt in ifStmt.body {
                if let location = findDefinitionInStatement(stmt, symbolName: symbolName, kind: kind) {
                    return location
                }
            }
            for stmt in ifStmt.orElse {
                if let location = findDefinitionInStatement(stmt, symbolName: symbolName, kind: kind) {
                    return location
                }
            }
            
        case .whileStmt(let whileStmt):
            for stmt in whileStmt.body {
                if let location = findDefinitionInStatement(stmt, symbolName: symbolName, kind: kind) {
                    return location
                }
            }
            
        case .forStmt(let forStmt):
            for stmt in forStmt.body {
                if let location = findDefinitionInStatement(stmt, symbolName: symbolName, kind: kind) {
                    return location
                }
            }
            
        case .withStmt(let withStmt):
            for stmt in withStmt.body {
                if let location = findDefinitionInStatement(stmt, symbolName: symbolName, kind: kind) {
                    return location
                }
            }
            
        default:
            break
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
        
        // Helper to check expressions for name references
        func checkExpression(_ expression: PySwiftAST.Expression) {
            if case .name(let name) = expression, name.id == symbol.name {
                locations.append(Location(
                    uri: "document",
                    range: IDERange.from(line: name.lineno, column: name.colOffset, length: name.id.count)
                ))
            }
            
            // Recursively check nested expressions
            switch expression {
            case .call(let call):
                checkExpression(call.fun)
                for arg in call.args {
                    checkExpression(arg)
                }
                for keyword in call.keywords {
                    checkExpression(keyword.value)
                }
                
            case .attribute(let attr):
                checkExpression(attr.value)
                
            case .subscriptExpr(let sub):
                checkExpression(sub.value)
                checkExpression(sub.slice)
                
            case .list(let list):
                for elt in list.elts {
                    checkExpression(elt)
                }
                
            case .tuple(let tuple):
                for elt in tuple.elts {
                    checkExpression(elt)
                }
                
            case .dict(let dict):
                for key in dict.keys {
                    if let key = key {
                        checkExpression(key)
                    }
                }
                for value in dict.values {
                    checkExpression(value)
                }
                
            case .set(let set):
                for elt in set.elts {
                    checkExpression(elt)
                }
                
            case .binOp(let binOp):
                checkExpression(binOp.left)
                checkExpression(binOp.right)
                
            case .unaryOp(let unaryOp):
                checkExpression(unaryOp.operand)
                
            case .compare(let compare):
                checkExpression(compare.left)
                for comparator in compare.comparators {
                    checkExpression(comparator)
                }
                
            case .boolOp(let boolOp):
                for value in boolOp.values {
                    checkExpression(value)
                }
                
            case .ifExp(let ifExp):
                checkExpression(ifExp.test)
                checkExpression(ifExp.body)
                checkExpression(ifExp.orElse)
                
            case .lambda(let lambda):
                checkExpression(lambda.body)
                
            default:
                break
            }
        }
        
        // Traverse statement structure
        switch statement {
        case .functionDef(let funcDef):
            for stmt in funcDef.body {
                locations.append(contentsOf: findReferencesInStatement(stmt, symbol: symbol))
            }
            
        case .asyncFunctionDef(let funcDef):
            for stmt in funcDef.body {
                locations.append(contentsOf: findReferencesInStatement(stmt, symbol: symbol))
            }
            
        case .classDef(let classDef):
            for stmt in classDef.body {
                locations.append(contentsOf: findReferencesInStatement(stmt, symbol: symbol))
            }
            
        case .assign(let assign):
            for target in assign.targets {
                checkExpression(target)
            }
            checkExpression(assign.value)
            
        case .annAssign(let annAssign):
            checkExpression(annAssign.target)
            checkExpression(annAssign.annotation)
            if let value = annAssign.value {
                checkExpression(value)
            }
            
        case .expr(let expr):
            checkExpression(expr.value)
            
        case .returnStmt(let ret):
            if let value = ret.value {
                checkExpression(value)
            }
            
        case .ifStmt(let ifStmt):
            checkExpression(ifStmt.test)
            for stmt in ifStmt.body {
                locations.append(contentsOf: findReferencesInStatement(stmt, symbol: symbol))
            }
            for stmt in ifStmt.orElse {
                locations.append(contentsOf: findReferencesInStatement(stmt, symbol: symbol))
            }
            
        case .whileStmt(let whileStmt):
            checkExpression(whileStmt.test)
            for stmt in whileStmt.body {
                locations.append(contentsOf: findReferencesInStatement(stmt, symbol: symbol))
            }
            
        case .forStmt(let forStmt):
            checkExpression(forStmt.iter)
            for stmt in forStmt.body {
                locations.append(contentsOf: findReferencesInStatement(stmt, symbol: symbol))
            }
            
        case .withStmt(let withStmt):
            for item in withStmt.items {
                checkExpression(item.contextExpr)
            }
            for stmt in withStmt.body {
                locations.append(contentsOf: findReferencesInStatement(stmt, symbol: symbol))
            }
            
        default:
            break
        }
        
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
            
            // Classify body statements
            for stmt in funcDef.body {
                classifyStatement(stmt, builder: builder)
            }
            
        case .asyncFunctionDef(let funcDef):
            let line = funcDef.lineno
            builder.push(
                line: line,
                startChar: funcDef.colOffset,
                length: funcDef.name.count,
                tokenType: .function,
                tokenModifiers: [.definition]
            )
            
            for stmt in funcDef.body {
                classifyStatement(stmt, builder: builder)
            }
            
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
            
            // Classify base classes
            for base in classDef.bases {
                classifyExpression(base, builder: builder)
            }
            
            // Classify body statements
            for stmt in classDef.body {
                classifyStatement(stmt, builder: builder)
            }
            
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
            
            // Classify the value expression
            classifyExpression(assign.value, builder: builder)
            
        case .annAssign(let annAssign):
            if case .name(let name) = annAssign.target {
                builder.push(
                    line: name.lineno,
                    startChar: name.colOffset,
                    length: name.id.count,
                    tokenType: .variable,
                    tokenModifiers: []
                )
            }
            
            classifyExpression(annAssign.annotation, builder: builder)
            if let value = annAssign.value {
                classifyExpression(value, builder: builder)
            }
            
        case .importStmt(let importStmt):
            for alias in importStmt.names {
                let name = alias.asName ?? alias.name
                builder.push(
                    line: importStmt.lineno,
                    startChar: importStmt.colOffset,
                    length: name.count,
                    tokenType: .namespace,
                    tokenModifiers: []
                )
            }
            
        case .importFrom(let importFrom):
            for alias in importFrom.names {
                let name = alias.asName ?? alias.name
                builder.push(
                    line: importFrom.lineno,
                    startChar: importFrom.colOffset,
                    length: name.count,
                    tokenType: .function,
                    tokenModifiers: []
                )
            }
            
        case .expr(let expr):
            classifyExpression(expr.value, builder: builder)
            
        case .ifStmt(let ifStmt):
            classifyExpression(ifStmt.test, builder: builder)
            for stmt in ifStmt.body {
                classifyStatement(stmt, builder: builder)
            }
            for stmt in ifStmt.orElse {
                classifyStatement(stmt, builder: builder)
            }
            
        case .whileStmt(let whileStmt):
            classifyExpression(whileStmt.test, builder: builder)
            for stmt in whileStmt.body {
                classifyStatement(stmt, builder: builder)
            }
            for stmt in whileStmt.orElse {
                classifyStatement(stmt, builder: builder)
            }
            
        case .forStmt(let forStmt):
            classifyExpression(forStmt.iter, builder: builder)
            for stmt in forStmt.body {
                classifyStatement(stmt, builder: builder)
            }
            for stmt in forStmt.orElse {
                classifyStatement(stmt, builder: builder)
            }
            
        case .withStmt(let withStmt):
            for item in withStmt.items {
                classifyExpression(item.contextExpr, builder: builder)
            }
            for stmt in withStmt.body {
                classifyStatement(stmt, builder: builder)
            }
            
        case .returnStmt(let ret):
            if let value = ret.value {
                classifyExpression(value, builder: builder)
            }
            
        default:
            break
        }
    }
    
    private func classifyExpression(_ expression: PySwiftAST.Expression, builder: SemanticTokensBuilder) {
        switch expression {
        case .name(let name):
            builder.push(
                line: name.lineno,
                startChar: name.colOffset,
                length: name.id.count,
                tokenType: .variable,
                tokenModifiers: []
            )
            
        case .call(let call):
            // Classify the function being called
            if case .name(let name) = call.fun {
                builder.push(
                    line: name.lineno,
                    startChar: name.colOffset,
                    length: name.id.count,
                    tokenType: .function,
                    tokenModifiers: []
                )
            } else {
                classifyExpression(call.fun, builder: builder)
            }
            
            // Classify arguments
            for arg in call.args {
                classifyExpression(arg, builder: builder)
            }
            
            for keyword in call.keywords {
                classifyExpression(keyword.value, builder: builder)
            }
            
        case .attribute(let attr):
            classifyExpression(attr.value, builder: builder)
            
            // Attribute name
            let line = attr.value.lineno
            builder.push(
                line: line,
                startChar: attr.colOffset,
                length: attr.attr.count,
                tokenType: .property,
                tokenModifiers: []
            )
            
        case .subscriptExpr(let sub):
            classifyExpression(sub.value, builder: builder)
            classifyExpression(sub.slice, builder: builder)
            
        case .list(let list):
            for elt in list.elts {
                classifyExpression(elt, builder: builder)
            }
            
        case .tuple(let tuple):
            for elt in tuple.elts {
                classifyExpression(elt, builder: builder)
            }
            
        case .dict(let dict):
            for key in dict.keys {
                if let key = key {
                    classifyExpression(key, builder: builder)
                }
            }
            for value in dict.values {
                classifyExpression(value, builder: builder)
            }
            
        case .set(let set):
            for elt in set.elts {
                classifyExpression(elt, builder: builder)
            }
            
        case .binOp(let binOp):
            classifyExpression(binOp.left, builder: builder)
            classifyExpression(binOp.right, builder: builder)
            
        case .unaryOp(let unaryOp):
            classifyExpression(unaryOp.operand, builder: builder)
            
        case .compare(let compare):
            classifyExpression(compare.left, builder: builder)
            for comparator in compare.comparators {
                classifyExpression(comparator, builder: builder)
            }
            
        case .boolOp(let boolOp):
            for value in boolOp.values {
                classifyExpression(value, builder: builder)
            }
            
        case .lambda(let lambda):
            classifyExpression(lambda.body, builder: builder)
            
        case .ifExp(let ifExp):
            classifyExpression(ifExp.test, builder: builder)
            classifyExpression(ifExp.body, builder: builder)
            classifyExpression(ifExp.orElse, builder: builder)
            
        case .listComp(let listComp):
            classifyExpression(listComp.elt, builder: builder)
            
        case .dictComp(let dictComp):
            classifyExpression(dictComp.key, builder: builder)
            classifyExpression(dictComp.value, builder: builder)
            
        case .setComp(let setComp):
            classifyExpression(setComp.elt, builder: builder)
            
        case .generatorExp(let genExp):
            classifyExpression(genExp.elt, builder: builder)
            
        default:
            break
        }
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
        guard line > 1 && line <= sourceLines.count else { return 0 }
        
        // Try AST-based indentation first
        if let ast = ast, let astIndent = calculateIndentationFromAST(at: line, in: ast) {
            return astIndent
        }
        
        // Fallback to simple heuristic
        let prevLine = sourceLines[line - 2]
        let prevIndent = prevLine.prefix(while: { $0 == " " || $0 == "\t" }).count
        
        if prevLine.trimmingCharacters(in: .whitespaces).hasSuffix(":") {
            return prevIndent + 4 // Increase indent after colon
        }
        
        return prevIndent
    }
    
    private func calculateIndentationFromAST(at line: Int, in module: Module) -> Int? {
        let statements = getStatements(from: module)
        
        for statement in statements {
            if let indent = indentationForStatement(statement, targetLine: line) {
                return indent
            }
        }
        
        return nil
    }
    
    private func indentationForStatement(_ statement: Statement, targetLine: Int) -> Int? {
        let stmtLine = statement.lineno
        let baseIndent = (stmtLine > 0 && stmtLine <= sourceLines.count) 
            ? sourceLines[stmtLine - 1].prefix(while: { $0 == " " || $0 == "\t" }).count 
            : 0
        
        switch statement {
        case .functionDef(let funcDef):
            if funcDef.lineno < targetLine && (funcDef.endLineno ?? 0) >= targetLine {
                // Inside function body
                return baseIndent + 4
            }
            for stmt in funcDef.body {
                if let indent = indentationForStatement(stmt, targetLine: targetLine) {
                    return indent
                }
            }
            
        case .asyncFunctionDef(let funcDef):
            if funcDef.lineno < targetLine && (funcDef.endLineno ?? 0) >= targetLine {
                return baseIndent + 4
            }
            for stmt in funcDef.body {
                if let indent = indentationForStatement(stmt, targetLine: targetLine) {
                    return indent
                }
            }
            
        case .classDef(let classDef):
            if classDef.lineno < targetLine && (classDef.endLineno ?? 0) >= targetLine {
                // Inside class body
                return baseIndent + 4
            }
            for stmt in classDef.body {
                if let indent = indentationForStatement(stmt, targetLine: targetLine) {
                    return indent
                }
            }
            
        case .ifStmt(let ifStmt):
            if ifStmt.lineno < targetLine && (ifStmt.endLineno ?? 0) >= targetLine {
                return baseIndent + 4
            }
            for stmt in ifStmt.body {
                if let indent = indentationForStatement(stmt, targetLine: targetLine) {
                    return indent
                }
            }
            for stmt in ifStmt.orElse {
                if let indent = indentationForStatement(stmt, targetLine: targetLine) {
                    return indent
                }
            }
            
        case .whileStmt(let whileStmt):
            if whileStmt.lineno < targetLine && (whileStmt.endLineno ?? 0) >= targetLine {
                return baseIndent + 4
            }
            for stmt in whileStmt.body {
                if let indent = indentationForStatement(stmt, targetLine: targetLine) {
                    return indent
                }
            }
            
        case .forStmt(let forStmt):
            if forStmt.lineno < targetLine && (forStmt.endLineno ?? 0) >= targetLine {
                return baseIndent + 4
            }
            for stmt in forStmt.body {
                if let indent = indentationForStatement(stmt, targetLine: targetLine) {
                    return indent
                }
            }
            
        case .withStmt(let withStmt):
            if withStmt.lineno < targetLine && (withStmt.endLineno ?? 0) >= targetLine {
                return baseIndent + 4
            }
            for stmt in withStmt.body {
                if let indent = indentationForStatement(stmt, targetLine: targetLine) {
                    return indent
                }
            }
            
        case .tryStmt(let tryStmt):
            if tryStmt.lineno < targetLine && (tryStmt.endLineno ?? 0) >= targetLine {
                return baseIndent + 4
            }
            for stmt in tryStmt.body {
                if let indent = indentationForStatement(stmt, targetLine: targetLine) {
                    return indent
                }
            }
            for handler in tryStmt.handlers {
                for stmt in handler.body {
                    if let indent = indentationForStatement(stmt, targetLine: targetLine) {
                        return indent
                    }
                }
            }
            
        default:
            break
        }
        
        return nil
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

// MARK: - Symbol Table

/// Symbol information collected from AST
private class SymbolTable {
    var functions: [FunctionSymbol] = []
    var classes: [ClassSymbol] = []
    var variables: [VariableSymbol] = []
    var imports: [ImportSymbol] = []
    
    init(ast: Module) {
        buildSymbolTable(from: ast)
    }
    
    private func buildSymbolTable(from module: Module) {
        let statements = getStatements(from: module)
        
        for statement in statements {
            switch statement {
            case .functionDef(let funcDef):
                extractFunction(funcDef, isAsync: false)
                
            case .asyncFunctionDef(let funcDef):
                extractAsyncFunction(funcDef)
                
            case .classDef(let classDef):
                extractClass(classDef)
                
            case .assign(let assign):
                extractAssignments(assign)
                
            case .annAssign(let annAssign):
                extractAnnotatedAssignment(annAssign)
                
            case .importStmt(let imp):
                extractImport(imp)
                
            case .importFrom(let impFrom):
                extractImportFrom(impFrom)
                
            default:
                break
            }
        }
    }
    
    private func extractFunction(_ funcDef: FunctionDef, isAsync: Bool) {
        let params = funcDef.args.args.map { arg in
            ParameterInfo(
                name: arg.arg,
                typeAnnotation: arg.annotation.map { formatExpressionSimple($0) }
            )
        }
        
        let returnType = funcDef.returns.map { formatExpressionSimple($0) }
        let docstring = extractDocstringFromBody(funcDef.body)
        
        functions.append(FunctionSymbol(
            name: funcDef.name,
            parameters: params,
            returnType: returnType,
            isAsync: isAsync,
            docstring: docstring,
            line: funcDef.lineno,
            column: funcDef.colOffset
        ))
    }
    
    private func extractAsyncFunction(_ funcDef: AsyncFunctionDef) {
        let params = funcDef.args.args.map { arg in
            ParameterInfo(
                name: arg.arg,
                typeAnnotation: arg.annotation.map { formatExpressionSimple($0) }
            )
        }
        
        let returnType = funcDef.returns.map { formatExpressionSimple($0) }
        let docstring = extractDocstringFromBody(funcDef.body)
        
        functions.append(FunctionSymbol(
            name: funcDef.name,
            parameters: params,
            returnType: returnType,
            isAsync: true,
            docstring: docstring,
            line: funcDef.lineno,
            column: funcDef.colOffset
        ))
    }
    
    private func extractClass(_ classDef: ClassDef) {
        let docstring = extractDocstringFromBody(classDef.body)
        let baseClasses = classDef.bases.map { formatExpressionSimple($0) }
        
        classes.append(ClassSymbol(
            name: classDef.name,
            baseClasses: baseClasses,
            docstring: docstring,
            line: classDef.lineno,
            column: classDef.colOffset
        ))
    }
    
    private func extractAssignments(_ assign: Assign) {
        for target in assign.targets {
            if case .name(let name) = target {
                variables.append(VariableSymbol(
                    name: name.id,
                    typeAnnotation: nil,
                    line: name.lineno,
                    column: name.colOffset
                ))
            }
        }
    }
    
    private func extractAnnotatedAssignment(_ annAssign: AnnAssign) {
        if case .name(let name) = annAssign.target {
            variables.append(VariableSymbol(
                name: name.id,
                typeAnnotation: formatExpressionSimple(annAssign.annotation),
                line: name.lineno,
                column: name.colOffset
            ))
        }
    }
    
    private func extractImport(_ imp: Import) {
        for alias in imp.names {
            let name = alias.asName ?? alias.name
            imports.append(ImportSymbol(
                name: name,
                originalName: alias.name,
                line: imp.lineno,
                column: imp.colOffset
            ))
        }
    }
    
    private func extractImportFrom(_ impFrom: ImportFrom) {
        for alias in impFrom.names {
            let name = alias.asName ?? alias.name
            imports.append(ImportSymbol(
                name: name,
                originalName: alias.name,
                fromModule: impFrom.module,
                line: impFrom.lineno,
                column: impFrom.colOffset
            ))
        }
    }
    
    private func getStatements(from module: Module) -> [Statement] {
        switch module {
        case .module(let statements), .interactive(let statements):
            return statements
        default:
            return []
        }
    }
    
    private func extractDocstringFromBody(_ body: [Statement]) -> String? {
        guard !body.isEmpty else { return nil }
        
        if case .expr(let expr) = body[0] {
            if case .constant(let constant) = expr.value {
                if case .string(let docstring) = constant.value {
                    return docstring.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return nil
    }
    
    private func formatExpressionSimple(_ expression: PySwiftAST.Expression) -> String {
        switch expression {
        case .name(let name):
            return name.id
        case .constant(let constant):
            switch constant.value {
            case .string(let s): return s
            case .int(let i): return "\(i)"
            case .bool(let b): return b ? "True" : "False"
            default: return "..."
            }
        case .attribute(let attr):
            return "\(formatExpressionSimple(attr.value)).\(attr.attr)"
        case .subscriptExpr(let sub):
            return "\(formatExpressionSimple(sub.value))[...]"
        case .list:
            return "[...]"
        case .tuple:
            return "(...)"
        default:
            return "..."
        }
    }
}

// MARK: - Symbol Types

private struct FunctionSymbol {
    let name: String
    let parameters: [ParameterInfo]
    let returnType: String?
    let isAsync: Bool
    let docstring: String?
    let line: Int
    let column: Int
}

private struct ClassSymbol {
    let name: String
    let baseClasses: [String]
    let docstring: String?
    let line: Int
    let column: Int
}

private struct VariableSymbol {
    let name: String
    let typeAnnotation: String?
    let line: Int
    let column: Int
}

private struct ImportSymbol {
    let name: String
    let originalName: String
    let fromModule: String?
    let line: Int
    let column: Int
    
    init(name: String, originalName: String, fromModule: String? = nil, line: Int, column: Int) {
        self.name = name
        self.originalName = originalName
        self.fromModule = fromModule
        self.line = line
        self.column = column
    }
}

private struct ParameterInfo {
    let name: String
    let typeAnnotation: String?
}
