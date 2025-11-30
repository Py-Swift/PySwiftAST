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
        // NOTE: Currently disabled - should be context-aware attribute completions
        // items.append(contentsOf: _getBuiltinTypeCompletions())
        
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
        return Self.pythonKeywords
    }
    
    private static let pythonKeywords: [CompletionItem] = [
        .keyword("def"), .keyword("class"), .keyword("if"), .keyword("elif"), 
        .keyword("else"), .keyword("for"), .keyword("while"), .keyword("return"), 
        .keyword("yield"), .keyword("import"), .keyword("from"), .keyword("as"), 
        .keyword("try"), .keyword("except"), .keyword("finally"), .keyword("with"), 
        .keyword("async"), .keyword("await"), .keyword("lambda"), .keyword("pass"),
        .keyword("break"), .keyword("continue"), .keyword("raise"), .keyword("assert"), 
        .keyword("del"), .keyword("global"), .keyword("nonlocal"), .keyword("True"), 
        .keyword("False"), .keyword("None"), .keyword("and"), .keyword("or"), 
        .keyword("not"), .keyword("in"), .keyword("is")
    ]
    
    private func getBuiltinCompletions() -> [CompletionItem] {
        return Self.builtinFunctions
    }
    
    private static let builtinFunctions: [CompletionItem] = [
        .function(name: "abs", parameters: ["x"], documentation: "Return the absolute value of the argument."),
        .function(name: "all", parameters: ["iterable"], documentation: "Return True if bool(x) is True for all values x in the iterable."),
        .function(name: "any", parameters: ["iterable"], documentation: "Return True if bool(x) is True for any x in the iterable."),
        .function(name: "ascii", parameters: ["obj"], documentation: "Return an ASCII-only representation of an object."),
        .function(name: "bin", parameters: ["number"], documentation: "Return the binary representation of an integer."),
        .function(name: "bool", parameters: ["object=False"], documentation: "Returns True when the argument is true, False otherwise. The builtins True and False are the only two instances of the class bool. The class bool is a subclass of the class int, and cannot be subclassed."),
        .function(name: "breakpoint", parameters: ["*args", "**kws"], documentation: "Call sys.breakpointhook(*args, **kws). sys.breakpointhook() must accept whatever arguments are passed."),
        .function(name: "bytearray", parameters: [], documentation: "bytearray(iterable_of_ints) -> bytearray bytearray(string, encoding[, errors]) -> bytearray bytearray(bytes_or_buffer) -> mutable copy of bytes_or_buffer bytearray(int) -> bytes array of size given by the parameter initialized with null bytes bytearray() -> empty bytes array"),
        .function(name: "bytes", parameters: [], documentation: "bytes(iterable_of_ints) -> bytes bytes(string, encoding[, errors]) -> bytes bytes(bytes_or_buffer) -> immutable copy of bytes_or_buffer bytes(int) -> bytes object of size given by the parameter initialized with null bytes bytes() -> empty bytes object"),
        .function(name: "callable", parameters: ["obj"], documentation: "Return whether the object is callable (i.e., some kind of function)."),
        .function(name: "chr", parameters: ["i"], documentation: "Return a Unicode string of one character with ordinal i; 0 <= i <= 0x10ffff."),
        .function(name: "classmethod", parameters: ["function"], documentation: "Convert a function to be a class method."),
        .function(name: "compile", parameters: ["source", "filename", "mode", "flags=0", "dont_inherit=False", "optimize=-1", "_feature_version=-1"], documentation: "Compile source into a code object that can be executed by exec() or eval()."),
        .function(name: "complex", parameters: ["real=0", "imag=0"], documentation: "Create a complex number from a string or numbers."),
        .function(name: "delattr", parameters: ["obj", "name"], documentation: "Deletes the named attribute from the given object."),
        .function(name: "dict", parameters: [], documentation: "dict() -> new empty dictionary dict(mapping) -> new dictionary initialized from a mapping object's (key, value) pairs dict(iterable) -> new dictionary initialized as if via: d = {} for k, v in iterable: d[k] = v dict(**kwargs) -> new dictionary initialized with the name=value pairs in the keyword argument list. For example: dict(one=1, two=2)"),
        .function(name: "dir", parameters: [], documentation: "dir([object]) -> list of strings"),
        .function(name: "divmod", parameters: ["x", "y"], documentation: "Return the tuple (x//y, x%y). Invariant: div*y + mod == x."),
        .function(name: "enumerate", parameters: ["iterable", "start=0"], documentation: "Return an enumerate object."),
        .function(name: "eval", parameters: ["source", "globals=None", "locals=None"], documentation: "Evaluate the given source in the context of globals and locals."),
        .function(name: "exec", parameters: ["source", "globals=None", "locals=None", "closure=None"], documentation: "Execute the given source in the context of globals and locals."),
        .function(name: "filter", parameters: ["function", "iterable"], documentation: "Return an iterator yielding those items of iterable for which function(item) is true. If function is None, return the items that are true."),
        .function(name: "float", parameters: ["x=0"], documentation: "Convert a string or number to a floating-point number, if possible."),
        .function(name: "format", parameters: ["value", "format_spec=''"], documentation: "Return type(value).__format__(value, format_spec)"),
        .function(name: "frozenset", parameters: ["iterable=()"], documentation: "Build an immutable unordered collection of unique elements."),
        .function(name: "getattr", parameters: [], documentation: "getattr(object, name[, default]) -> value"),
        .function(name: "globals", parameters: [], documentation: "Return the dictionary containing the current scope's global variables."),
        .function(name: "hasattr", parameters: ["obj", "name"], documentation: "Return whether the object has an attribute with the given name."),
        .function(name: "hash", parameters: ["obj"], documentation: "Return the hash value for the given object."),
        .function(name: "help", parameters: [], documentation: "Define the builtin 'help'."),
        .function(name: "hex", parameters: ["number"], documentation: "Return the hexadecimal representation of an integer."),
        .function(name: "id", parameters: ["obj"], documentation: "Return the identity of an object."),
        .function(name: "input", parameters: ["prompt=''"], documentation: "Read a string from standard input. The trailing newline is stripped."),
        .function(name: "int", parameters: [], documentation: "int([x]) -> integer int(x, base=10) -> integer"),
        .function(name: "isinstance", parameters: ["obj", "class_or_tuple"], documentation: "Return whether an object is an instance of a class or of a subclass thereof."),
        .function(name: "issubclass", parameters: ["cls", "class_or_tuple"], documentation: "Return whether 'cls' is derived from another class or is the same class."),
        .function(name: "iter", parameters: [], documentation: "iter(iterable) -> iterator iter(callable, sentinel) -> iterator"),
        .function(name: "len", parameters: ["obj"], documentation: "Return the number of items in a container."),
        .function(name: "list", parameters: ["iterable=()"], documentation: "Built-in mutable sequence."),
        .function(name: "locals", parameters: [], documentation: "Return a dictionary containing the current scope's local variables."),
        .function(name: "map", parameters: ["function", "iterable", "*iterables"], documentation: "Make an iterator that computes the function using arguments from each of the iterables. Stops when the shortest iterable is exhausted."),
        .function(name: "max", parameters: [], documentation: "max(iterable, *[, default=obj, key=func]) -> value max(arg1, arg2, *args, *[, key=func]) -> value"),
        .function(name: "memoryview", parameters: ["object"], documentation: "Create a new memoryview object which references the given object."),
        .function(name: "min", parameters: [], documentation: "min(iterable, *[, default=obj, key=func]) -> value min(arg1, arg2, *args, *[, key=func]) -> value"),
        .function(name: "next", parameters: [], documentation: "next(iterator[, default])"),
        .function(name: "object", parameters: [], documentation: "The base class of the class hierarchy."),
        .function(name: "oct", parameters: ["number"], documentation: "Return the octal representation of an integer."),
        .function(name: "open", parameters: ["file", "mode='r'", "buffering=-1", "encoding=None", "errors=None", "newline=None", "closefd=True", "opener=None"], documentation: "Open file and return a stream. Raise OSError upon failure."),
        .function(name: "ord", parameters: ["character"], documentation: "Return the ordinal value of a character."),
        .function(name: "pow", parameters: ["base", "exp", "mod=None"], documentation: "Equivalent to base**exp with 2 arguments or base**exp % mod with 3 arguments"),
        .function(name: "print", parameters: ["*args", "sep=' '", "end='\\n'", "file=None", "flush=False"], documentation: "Prints the values to a stream, or to sys.stdout by default."),
        .function(name: "property", parameters: ["fget=None", "fset=None", "fdel=None", "doc=None"], documentation: "Property attribute."),
        .function(name: "range", parameters: [], documentation: "range(stop) -> range object range(start, stop[, step]) -> range object"),
        .function(name: "repr", parameters: ["obj"], documentation: "Return the canonical string representation of the object."),
        .function(name: "reversed", parameters: ["sequence"], documentation: "Return a reverse iterator over the values of the given sequence."),
        .function(name: "round", parameters: ["number", "ndigits=None"], documentation: "Round a number to a given precision in decimal digits."),
        .function(name: "set", parameters: ["iterable=()"], documentation: "Build an unordered collection of unique elements."),
        .function(name: "setattr", parameters: ["obj", "name", "value"], documentation: "Sets the named attribute on the given object to the specified value."),
        .function(name: "slice", parameters: [], documentation: "slice(stop) slice(start, stop[, step])"),
        .function(name: "sorted", parameters: ["iterable", "key=None", "reverse=False"], documentation: "Return a new list containing all items from the iterable in ascending order."),
        .function(name: "staticmethod", parameters: ["function"], documentation: "Convert a function to be a static method."),
        .function(name: "str", parameters: [], documentation: "str(object='') -> str str(bytes_or_buffer[, encoding[, errors]]) -> str"),
        .function(name: "sum", parameters: ["iterable", "start=0"], documentation: "Return the sum of a 'start' value (default: 0) plus an iterable of numbers"),
        .function(name: "super", parameters: [], documentation: "super() -> same as super(__class__, <first argument>) super(type) -> unbound super object super(type, obj) -> bound super object; requires isinstance(obj, type) super(type, type2) -> bound super object; requires issubclass(type2, type) Typical use to call a cooperative superclass method: class C(B): def meth(self, arg):"),
        .function(name: "tuple", parameters: ["iterable=()"], documentation: "Built-in immutable sequence."),
        .function(name: "type", parameters: [], documentation: "type(object) -> the object's type type(name, bases, dict, **kwds) -> a new type"),
        .function(name: "vars", parameters: [], documentation: "vars([object]) -> dictionary"),
        .function(name: "zip", parameters: ["*iterables", "strict=False"], documentation: "The zip object yields n-length tuples, where n is the number of iterables passed as positional arguments to zip(). The i-th element in every tuple comes from the i-th iterable argument to zip(). This continues until the shortest argument is exhausted."),
    ]
    
    // MARK: - Built-in Type Method Definitions (for future type-aware completions)
    
    /// NOTE: These type method definitions are kept for future implementation of type-aware completions.
    /// They should only be used when:
    /// 1. Detecting attribute access (dot notation) 
    /// 2. Type inference determines the object's type
    /// 3. Filtering methods based on inferred type (e.g., only show str methods for string objects)
    
    /// String type methods - for use when type inference determines an object is a string
    struct StringMethods {
        static let methods: [CompletionItem] = [
            .function(name: "capitalize", parameters: [], documentation: "Return a capitalized version of the string."),
            .function(name: "casefold", parameters: [], documentation: "Return a version of the string suitable for caseless comparisons."),
            .function(name: "center", parameters: ["width", "fillchar=' '"], documentation: "Return a centered string of length width."),
            .function(name: "count", parameters: [], documentation: "Return the number of non-overlapping occurrences of substring sub in string S[start:end]."),
            .function(name: "encode", parameters: ["encoding='utf-8'", "errors='strict'"], documentation: "Encode the string using the codec registered for encoding."),
            .function(name: "endswith", parameters: [], documentation: "Return True if the string ends with the specified suffix, False otherwise."),
            .function(name: "expandtabs", parameters: ["tabsize=8"], documentation: "Return a copy where all tab characters are expanded using spaces."),
            .function(name: "find", parameters: [], documentation: "Return the lowest index in S where substring sub is found, such that sub is contained within S[start:end]."),
            .function(name: "format", parameters: ["*args", "**kwargs"], documentation: "Return a formatted version of the string, using substitutions from args and kwargs. The substitutions are identified by braces ('{' and '}')."),
            .function(name: "format_map", parameters: ["mapping"], documentation: "Return a formatted version of the string, using substitutions from mapping. The substitutions are identified by braces ('{' and '}')."),
            .function(name: "index", parameters: [], documentation: "Return the lowest index in S where substring sub is found, such that sub is contained within S[start:end]."),
            .function(name: "isalnum", parameters: [], documentation: "Return True if the string is an alpha-numeric string, False otherwise."),
            .function(name: "isalpha", parameters: [], documentation: "Return True if the string is an alphabetic string, False otherwise."),
            .function(name: "isascii", parameters: [], documentation: "Return True if all characters in the string are ASCII, False otherwise."),
            .function(name: "isdecimal", parameters: [], documentation: "Return True if the string is a decimal string, False otherwise."),
            .function(name: "isdigit", parameters: [], documentation: "Return True if the string is a digit string, False otherwise."),
            .function(name: "isidentifier", parameters: [], documentation: "Return True if the string is a valid Python identifier, False otherwise."),
            .function(name: "islower", parameters: [], documentation: "Return True if the string is a lowercase string, False otherwise."),
            .function(name: "isnumeric", parameters: [], documentation: "Return True if the string is a numeric string, False otherwise."),
            .function(name: "isprintable", parameters: [], documentation: "Return True if all characters in the string are printable, False otherwise."),
            .function(name: "isspace", parameters: [], documentation: "Return True if the string is a whitespace string, False otherwise."),
            .function(name: "istitle", parameters: [], documentation: "Return True if the string is a title-cased string, False otherwise."),
            .function(name: "isupper", parameters: [], documentation: "Return True if the string is an uppercase string, False otherwise."),
            .function(name: "join", parameters: ["iterable"], documentation: "Concatenate any number of strings."),
            .function(name: "ljust", parameters: ["width", "fillchar=' '"], documentation: "Return a left-justified string of length width."),
            .function(name: "lower", parameters: [], documentation: "Return a copy of the string converted to lowercase."),
            .function(name: "lstrip", parameters: ["chars=None"], documentation: "Return a copy of the string with leading whitespace removed."),
            .function(name: "maketrans", parameters: [], documentation: "Return a translation table usable for str.translate()."),
            .function(name: "partition", parameters: ["sep"], documentation: "Partition the string into three parts using the given separator."),
            .function(name: "removeprefix", parameters: ["prefix"], documentation: "Return a str with the given prefix string removed if present."),
            .function(name: "removesuffix", parameters: ["suffix"], documentation: "Return a str with the given suffix string removed if present."),
            .function(name: "replace", parameters: ["old", "new", "count=-1"], documentation: "Return a copy with all occurrences of substring old replaced by new."),
            .function(name: "rfind", parameters: [], documentation: "Return the highest index in S where substring sub is found, such that sub is contained within S[start:end]."),
            .function(name: "rindex", parameters: [], documentation: "Return the highest index in S where substring sub is found, such that sub is contained within S[start:end]."),
            .function(name: "rjust", parameters: ["width", "fillchar=' '"], documentation: "Return a right-justified string of length width."),
            .function(name: "rpartition", parameters: ["sep"], documentation: "Partition the string into three parts using the given separator."),
            .function(name: "rsplit", parameters: ["sep=None", "maxsplit=-1"], documentation: "Return a list of the substrings in the string, using sep as the separator string."),
            .function(name: "rstrip", parameters: ["chars=None"], documentation: "Return a copy of the string with trailing whitespace removed."),
            .function(name: "split", parameters: ["sep=None", "maxsplit=-1"], documentation: "Return a list of the substrings in the string, using sep as the separator string."),
            .function(name: "splitlines", parameters: ["keepends=False"], documentation: "Return a list of the lines in the string, breaking at line boundaries."),
            .function(name: "startswith", parameters: [], documentation: "Return True if the string starts with the specified prefix, False otherwise."),
            .function(name: "strip", parameters: ["chars=None"], documentation: "Return a copy of the string with leading and trailing whitespace removed."),
            .function(name: "swapcase", parameters: [], documentation: "Convert uppercase characters to lowercase and lowercase characters to uppercase."),
            .function(name: "title", parameters: [], documentation: "Return a version of the string where each word is titlecased."),
            .function(name: "translate", parameters: ["table"], documentation: "Replace each character in the string using the given translation table."),
            .function(name: "upper", parameters: [], documentation: "Return a copy of the string converted to uppercase."),
            .function(name: "zfill", parameters: ["width"], documentation: "Pad a numeric string with zeros on the left, to fill a field of the given width.")
        ]
    }
    
    /// List type methods - for use when type inference determines an object is a list
    struct ListMethods {
        static let methods: [CompletionItem] = [
            .function(name: "append", parameters: ["object"], documentation: "Append object to the end of the list."),
            .function(name: "clear", parameters: [], documentation: "Remove all items from list."),
            .function(name: "copy", parameters: [], documentation: "Return a shallow copy of the list."),
            .function(name: "count", parameters: ["value"], documentation: "Return number of occurrences of value."),
            .function(name: "extend", parameters: ["iterable"], documentation: "Extend list by appending elements from the iterable."),
            .function(name: "index", parameters: ["value", "start=0", "stop=9223372036854775807"], documentation: "Return first index of value."),
            .function(name: "insert", parameters: ["index", "object"], documentation: "Insert object before index."),
            .function(name: "pop", parameters: ["index=-1"], documentation: "Remove and return item at index (default last)."),
            .function(name: "remove", parameters: ["value"], documentation: "Remove first occurrence of value."),
            .function(name: "reverse", parameters: [], documentation: "Reverse *IN PLACE*."),
            .function(name: "sort", parameters: ["key=None", "reverse=False"], documentation: "Sort the list in ascending order and return None.")
        ]
    }
    
    /// Dict type methods - for use when type inference determines an object is a dict
    struct DictMethods {
        static let methods: [CompletionItem] = [
            .function(name: "clear", parameters: [], documentation: "Remove all items from the dict."),
            .function(name: "copy", parameters: [], documentation: "Return a shallow copy of the dict."),
            .function(name: "fromkeys", parameters: ["iterable", "value=None"], documentation: "Create a new dictionary with keys from iterable and values set to value."),
            .function(name: "get", parameters: ["key", "default=None"], documentation: "Return the value for key if key is in the dictionary, else default."),
            .function(name: "items", parameters: [], documentation: "Return a set-like object providing a view on the dict's items."),
            .function(name: "keys", parameters: [], documentation: "Return a set-like object providing a view on the dict's keys."),
            .function(name: "pop", parameters: [], documentation: "D.pop(k[,d]) -> v, remove specified key and return the corresponding value."),
            .function(name: "popitem", parameters: [], documentation: "Remove and return a (key, value) pair as a 2-tuple."),
            .function(name: "setdefault", parameters: ["key", "default=None"], documentation: "Insert key with a value of default if key is not in the dictionary."),
            .function(name: "update", parameters: [], documentation: "D.update([E, ]**F) -> None. Update D from mapping/iterable E and F. If E is present and has a .keys() method, then does: for k in E.keys(): D[k] = E[k] If E is present and lacks a .keys() method, then does: for k, v in E: D[k] = v In either case, this is followed by: for k in F: D[k] = F[k]"),
            .function(name: "values", parameters: [], documentation: "Return an object providing a view on the dict's values.")
        ]
    }
    
    /// Set type methods - for use when type inference determines an object is a set
    struct SetMethods {
        static let methods: [CompletionItem] = [
            .function(name: "add", parameters: ["object"], documentation: "Add an element to a set."),
            .function(name: "clear", parameters: [], documentation: "Remove all elements from this set."),
            .function(name: "copy", parameters: [], documentation: "Return a shallow copy of a set."),
            .function(name: "difference", parameters: ["*others"], documentation: "Return a new set with elements in the set that are not in the others."),
            .function(name: "difference_update", parameters: ["*others"], documentation: "Update the set, removing elements found in others."),
            .function(name: "discard", parameters: ["object"], documentation: "Remove an element from a set if it is a member."),
            .function(name: "intersection", parameters: ["*others"], documentation: "Return a new set with elements common to the set and all others."),
            .function(name: "intersection_update", parameters: ["*others"], documentation: "Update the set, keeping only elements found in it and all others."),
            .function(name: "isdisjoint", parameters: ["other"], documentation: "Return True if two sets have a null intersection."),
            .function(name: "issubset", parameters: ["other"], documentation: "Report whether another set contains this set."),
            .function(name: "issuperset", parameters: ["other"], documentation: "Report whether this set contains another set."),
            .function(name: "pop", parameters: [], documentation: "Remove and return an arbitrary set element."),
            .function(name: "remove", parameters: ["object"], documentation: "Remove an element from a set; it must be a member."),
            .function(name: "symmetric_difference", parameters: ["other"], documentation: "Return a new set with elements in either the set or other but not both."),
            .function(name: "symmetric_difference_update", parameters: ["other"], documentation: "Update the set, keeping only elements found in either set, but not in both."),
            .function(name: "union", parameters: ["*others"], documentation: "Return a new set with elements from the set and all others."),
            .function(name: "update", parameters: ["*others"], documentation: "Update the set, adding elements from all others.")
        ]
        
        /// Frozenset methods (subset of set methods that don't modify) - names only for filtering
        static let frozensetMethodNames: [String] = [
            "copy", "difference", "intersection", "isdisjoint", 
            "issubset", "issuperset", "symmetric_difference", "union"
        ]
    }
    
    /// Frozenset type methods - for use when type inference determines an object is a frozenset
    struct FrozensetMethods {
        static let methods: [CompletionItem] = [
            .function(name: "copy", parameters: [], documentation: "Return a shallow copy of a set."),
            .function(name: "difference", parameters: ["*others"], documentation: "Return a new set with elements in the set that are not in the others."),
            .function(name: "intersection", parameters: ["*others"], documentation: "Return a new set with elements common to the set and all others."),
            .function(name: "isdisjoint", parameters: ["other"], documentation: "Return True if two sets have a null intersection."),
            .function(name: "issubset", parameters: ["other"], documentation: "Report whether another set contains this set."),
            .function(name: "issuperset", parameters: ["other"], documentation: "Report whether this set contains another set."),
            .function(name: "symmetric_difference", parameters: ["other"], documentation: "Return a new set with elements in either the set or other but not both."),
            .function(name: "union", parameters: ["*others"], documentation: "Return a new set with elements from the set and all others.")
        ]
    }
    
    /// Bytes type methods - for use when type inference determines an object is bytes
    struct BytesMethods {
        static let methods: [CompletionItem] = [
            .function(name: "capitalize", parameters: [], documentation: "B.capitalize() -> copy of B"),
            .function(name: "center", parameters: ["width", "fillchar=b' '"], documentation: "Return a centered string of length width."),
            .function(name: "count", parameters: [], documentation: "Return the number of non-overlapping occurrences of subsection 'sub' in bytes B[start:end]."),
            .function(name: "decode", parameters: ["encoding='utf-8'", "errors='strict'"], documentation: "Decode the bytes using the codec registered for encoding."),
            .function(name: "endswith", parameters: [], documentation: "Return True if the bytes ends with the specified suffix, False otherwise."),
            .function(name: "expandtabs", parameters: ["tabsize=8"], documentation: "Return a copy where all tab characters are expanded using spaces."),
            .function(name: "find", parameters: [], documentation: "Return the lowest index in B where subsection 'sub' is found, such that 'sub' is contained within B[start,end]."),
            .function(name: "fromhex", parameters: ["string"], documentation: "Create a bytes object from a string of hexadecimal numbers."),
            .function(name: "hex", parameters: [], documentation: "Create a string of hexadecimal numbers from a bytes object."),
            .function(name: "index", parameters: [], documentation: "Return the lowest index in B where subsection 'sub' is found, such that 'sub' is contained within B[start,end]."),
            .function(name: "isalnum", parameters: [], documentation: "B.isalnum() -> bool"),
            .function(name: "isalpha", parameters: [], documentation: "B.isalpha() -> bool"),
            .function(name: "isascii", parameters: [], documentation: "B.isascii() -> bool"),
            .function(name: "isdigit", parameters: [], documentation: "B.isdigit() -> bool"),
            .function(name: "islower", parameters: [], documentation: "B.islower() -> bool"),
            .function(name: "isspace", parameters: [], documentation: "B.isspace() -> bool"),
            .function(name: "istitle", parameters: [], documentation: "B.istitle() -> bool"),
            .function(name: "isupper", parameters: [], documentation: "B.isupper() -> bool"),
            .function(name: "join", parameters: ["iterable_of_bytes"], documentation: "Concatenate any number of bytes objects."),
            .function(name: "ljust", parameters: ["width", "fillchar=b' '"], documentation: "Return a left-justified string of length width."),
            .function(name: "lower", parameters: [], documentation: "B.lower() -> copy of B"),
            .function(name: "lstrip", parameters: ["bytes=None"], documentation: "Strip leading bytes contained in the argument."),
            .function(name: "maketrans", parameters: ["frm", "to"], documentation: "Return a translation table usable for the bytes or bytearray translate method."),
            .function(name: "partition", parameters: ["sep"], documentation: "Partition the bytes into three parts using the given separator."),
            .function(name: "removeprefix", parameters: ["prefix"], documentation: "Return a bytes object with the given prefix string removed if present."),
            .function(name: "removesuffix", parameters: ["suffix"], documentation: "Return a bytes object with the given suffix string removed if present."),
            .function(name: "replace", parameters: ["old", "new", "count=-1"], documentation: "Return a copy with all occurrences of substring old replaced by new."),
            .function(name: "rfind", parameters: [], documentation: "Return the highest index in B where subsection 'sub' is found, such that 'sub' is contained within B[start,end]."),
            .function(name: "rindex", parameters: [], documentation: "Return the highest index in B where subsection 'sub' is found, such that 'sub' is contained within B[start,end]."),
            .function(name: "rjust", parameters: ["width", "fillchar=b' '"], documentation: "Return a right-justified string of length width."),
            .function(name: "rpartition", parameters: ["sep"], documentation: "Partition the bytes into three parts using the given separator."),
            .function(name: "rsplit", parameters: ["sep=None", "maxsplit=-1"], documentation: "Return a list of the sections in the bytes, using sep as the delimiter."),
            .function(name: "rstrip", parameters: ["bytes=None"], documentation: "Strip trailing bytes contained in the argument."),
            .function(name: "split", parameters: ["sep=None", "maxsplit=-1"], documentation: "Return a list of the sections in the bytes, using sep as the delimiter."),
            .function(name: "splitlines", parameters: ["keepends=False"], documentation: "Return a list of the lines in the bytes, breaking at line boundaries."),
            .function(name: "startswith", parameters: [], documentation: "Return True if the bytes starts with the specified prefix, False otherwise."),
            .function(name: "strip", parameters: ["bytes=None"], documentation: "Strip leading and trailing bytes contained in the argument."),
            .function(name: "swapcase", parameters: [], documentation: "B.swapcase() -> copy of B"),
            .function(name: "title", parameters: [], documentation: "B.title() -> copy of B"),
            .function(name: "translate", parameters: ["table", "delete=b''"], documentation: "Return a copy with each character mapped by the given translation table."),
            .function(name: "upper", parameters: [], documentation: "B.upper() -> copy of B"),
            .function(name: "zfill", parameters: ["width"], documentation: "Pad a numeric string with zeros on the left, to fill a field of the given width.")
        ]
    }
    
    /// Bytearray type methods - for use when type inference determines an object is bytearray
    struct BytearrayMethods {
        static let methods: [CompletionItem] = [
            .function(name: "append", parameters: ["item"], documentation: "Append a single item to the end of the bytearray."),
            .function(name: "capitalize", parameters: [], documentation: "B.capitalize() -> copy of B"),
            .function(name: "center", parameters: ["width", "fillchar=b' '"], documentation: "Return a centered string of length width."),
            .function(name: "clear", parameters: [], documentation: "Remove all items from the bytearray."),
            .function(name: "copy", parameters: [], documentation: "Return a copy of B."),
            .function(name: "count", parameters: [], documentation: "Return the number of non-overlapping occurrences of subsection 'sub' in bytes B[start:end]."),
            .function(name: "decode", parameters: ["encoding='utf-8'", "errors='strict'"], documentation: "Decode the bytearray using the codec registered for encoding."),
            .function(name: "endswith", parameters: [], documentation: "Return True if the bytearray ends with the specified suffix, False otherwise."),
            .function(name: "expandtabs", parameters: ["tabsize=8"], documentation: "Return a copy where all tab characters are expanded using spaces."),
            .function(name: "extend", parameters: ["iterable_of_ints"], documentation: "Append all the items from the iterator or sequence to the end of the bytearray."),
            .function(name: "find", parameters: [], documentation: "Return the lowest index in B where subsection 'sub' is found, such that 'sub' is contained within B[start:end]."),
            .function(name: "fromhex", parameters: ["string"], documentation: "Create a bytearray object from a string of hexadecimal numbers."),
            .function(name: "hex", parameters: [], documentation: "Create a string of hexadecimal numbers from a bytearray object."),
            .function(name: "index", parameters: [], documentation: "Return the lowest index in B where subsection 'sub' is found, such that 'sub' is contained within B[start:end]."),
            .function(name: "insert", parameters: ["index", "item"], documentation: "Insert a single item into the bytearray before the given index."),
            .function(name: "isalnum", parameters: [], documentation: "B.isalnum() -> bool"),
            .function(name: "isalpha", parameters: [], documentation: "B.isalpha() -> bool"),
            .function(name: "isascii", parameters: [], documentation: "B.isascii() -> bool"),
            .function(name: "isdigit", parameters: [], documentation: "B.isdigit() -> bool"),
            .function(name: "islower", parameters: [], documentation: "B.islower() -> bool"),
            .function(name: "isspace", parameters: [], documentation: "B.isspace() -> bool"),
            .function(name: "istitle", parameters: [], documentation: "B.istitle() -> bool"),
            .function(name: "isupper", parameters: [], documentation: "B.isupper() -> bool"),
            .function(name: "join", parameters: ["iterable_of_bytes"], documentation: "Concatenate any number of bytes/bytearray objects."),
            .function(name: "ljust", parameters: ["width", "fillchar=b' '"], documentation: "Return a left-justified string of length width."),
            .function(name: "lower", parameters: [], documentation: "B.lower() -> copy of B"),
            .function(name: "lstrip", parameters: ["bytes=None"], documentation: "Strip leading bytes contained in the argument."),
            .function(name: "maketrans", parameters: ["frm", "to"], documentation: "Return a translation table usable for the bytes or bytearray translate method."),
            .function(name: "partition", parameters: ["sep"], documentation: "Partition the bytearray into three parts using the given separator."),
            .function(name: "pop", parameters: ["index=-1"], documentation: "Remove and return a single item from B."),
            .function(name: "remove", parameters: ["value"], documentation: "Remove the first occurrence of a value in the bytearray."),
            .function(name: "removeprefix", parameters: ["prefix"], documentation: "Return a bytearray with the given prefix string removed if present."),
            .function(name: "removesuffix", parameters: ["suffix"], documentation: "Return a bytearray with the given suffix string removed if present."),
            .function(name: "replace", parameters: ["old", "new", "count=-1"], documentation: "Return a copy with all occurrences of substring old replaced by new."),
            .function(name: "reverse", parameters: [], documentation: "Reverse the order of the values in B in place."),
            .function(name: "rfind", parameters: [], documentation: "Return the highest index in B where subsection 'sub' is found, such that 'sub' is contained within B[start,end]."),
            .function(name: "rindex", parameters: [], documentation: "Return the highest index in B where subsection 'sub' is found, such that 'sub' is contained within B[start,end]."),
            .function(name: "rjust", parameters: ["width", "fillchar=b' '"], documentation: "Return a right-justified string of length width."),
            .function(name: "rpartition", parameters: ["sep"], documentation: "Partition the bytearray into three parts using the given separator."),
            .function(name: "rsplit", parameters: ["sep=None", "maxsplit=-1"], documentation: "Return a list of the sections in the bytearray, using sep as the delimiter."),
            .function(name: "rstrip", parameters: ["bytes=None"], documentation: "Strip trailing bytes contained in the argument."),
            .function(name: "split", parameters: ["sep=None", "maxsplit=-1"], documentation: "Return a list of the sections in the bytearray, using sep as the delimiter."),
            .function(name: "splitlines", parameters: ["keepends=False"], documentation: "Return a list of the lines in the bytearray, breaking at line boundaries."),
            .function(name: "startswith", parameters: [], documentation: "Return True if the bytearray starts with the specified prefix, False otherwise."),
            .function(name: "strip", parameters: ["bytes=None"], documentation: "Strip leading and trailing bytes contained in the argument."),
            .function(name: "swapcase", parameters: [], documentation: "B.swapcase() -> copy of B"),
            .function(name: "title", parameters: [], documentation: "B.title() -> copy of B"),
            .function(name: "translate", parameters: ["table", "delete=b''"], documentation: "Return a copy with each character mapped by the given translation table."),
            .function(name: "upper", parameters: [], documentation: "B.upper() -> copy of B"),
            .function(name: "zfill", parameters: ["width"], documentation: "Pad a numeric string with zeros on the left, to fill a field of the given width.")
        ]
    }
    
    /// Tuple type methods - for use when type inference determines an object is a tuple
    struct TupleMethods {
        static let methods: [CompletionItem] = [
            .function(name: "count", parameters: ["value"], documentation: "Return number of occurrences of value."),
            .function(name: "index", parameters: ["value", "start=0", "stop=None"], documentation: "Return first index of value.")
        ]
    }
    
    private func getMathModuleCompletions() -> [CompletionItem] {
        return Self.mathModuleCompletions
    }
    
    private static let mathModuleCompletions: [CompletionItem] = [
        // Math module constants
        .constant(name: "math.e", value: "2.718281828459045", documentation: "The mathematical constant e = 2.718281..."),
        .constant(name: "math.inf", value: "inf", documentation: "A floating-point positive infinity"),
        .constant(name: "math.nan", value: "nan", documentation: "A floating-point 'not a number' (NaN) value"),
        .constant(name: "math.pi", value: "3.141592653589793", documentation: "The mathematical constant π = 3.141592..."),
        .constant(name: "math.tau", value: "6.283185307179586", documentation: "The mathematical constant τ = 6.283185..."),

        // Math module functions
        .function(name: "math.acos", parameters: ["x"], documentation: "Return the arc cosine (measured in radians) of x."),
        .function(name: "math.acosh", parameters: ["x"], documentation: "Return the inverse hyperbolic cosine of x."),
        .function(name: "math.asin", parameters: ["x"], documentation: "Return the arc sine (measured in radians) of x."),
        .function(name: "math.asinh", parameters: ["x"], documentation: "Return the inverse hyperbolic sine of x."),
        .function(name: "math.atan", parameters: ["x"], documentation: "Return the arc tangent (measured in radians) of x."),
        .function(name: "math.atan2", parameters: ["y", "x"], documentation: "Return the arc tangent (measured in radians) of y/x."),
        .function(name: "math.atanh", parameters: ["x"], documentation: "Return the inverse hyperbolic tangent of x."),
        .function(name: "math.cbrt", parameters: ["x"], documentation: "Return the cube root of x."),
        .function(name: "math.ceil", parameters: ["x"], documentation: "Return the ceiling of x as an Integral."),
        .function(name: "math.comb", parameters: ["n", "k"], documentation: "Number of ways to choose k items from n items without repetition and without order."),
        .function(name: "math.copysign", parameters: ["x", "y"], documentation: "Return a float with the magnitude (absolute value) of x but the sign of y."),
        .function(name: "math.cos", parameters: ["x"], documentation: "Return the cosine of x (measured in radians)."),
        .function(name: "math.cosh", parameters: ["x"], documentation: "Return the hyperbolic cosine of x."),
        .function(name: "math.degrees", parameters: ["x"], documentation: "Convert angle x from radians to degrees."),
        .function(name: "math.dist", parameters: ["p", "q"], documentation: "Return the Euclidean distance between two points p and q."),
        .function(name: "math.erf", parameters: ["x"], documentation: "Error function at x."),
        .function(name: "math.erfc", parameters: ["x"], documentation: "Complementary error function at x."),
        .function(name: "math.exp", parameters: ["x"], documentation: "Return e raised to the power of x."),
        .function(name: "math.exp2", parameters: ["x"], documentation: "Return 2 raised to the power of x."),
        .function(name: "math.expm1", parameters: ["x"], documentation: "Return exp(x)-1."),
        .function(name: "math.fabs", parameters: ["x"], documentation: "Return the absolute value of the float x."),
        .function(name: "math.factorial", parameters: ["n"], documentation: "Find n!."),
        .function(name: "math.floor", parameters: ["x"], documentation: "Return the floor of x as an Integral."),
        .function(name: "math.fma", parameters: ["x", "y", "z"], documentation: "Fused multiply-add operation."),
        .function(name: "math.fmod", parameters: ["x", "y"], documentation: "Return fmod(x, y), according to platform C."),
        .function(name: "math.frexp", parameters: ["x"], documentation: "Return the mantissa and exponent of x, as pair (m, e)."),
        .function(name: "math.fsum", parameters: ["seq"], documentation: "Return an accurate floating-point sum of values in the iterable seq."),
        .function(name: "math.gamma", parameters: ["x"], documentation: "Gamma function at x."),
        .function(name: "math.gcd", parameters: ["*integers"], documentation: "Greatest Common Divisor."),
        .function(name: "math.hypot", parameters: [], documentation: "hypot(*coordinates) -> value"),
        .function(name: "math.isclose", parameters: ["a", "b", "rel_tol=1e-09", "abs_tol=0.0"], documentation: "Determine whether two floating-point numbers are close in value."),
        .function(name: "math.isfinite", parameters: ["x"], documentation: "Return True if x is neither an infinity nor a NaN, and False otherwise."),
        .function(name: "math.isinf", parameters: ["x"], documentation: "Return True if x is a positive or negative infinity, and False otherwise."),
        .function(name: "math.isnan", parameters: ["x"], documentation: "Return True if x is a NaN (not a number), and False otherwise."),
        .function(name: "math.isqrt", parameters: ["n"], documentation: "Return the integer part of the square root of the input."),
        .function(name: "math.lcm", parameters: ["*integers"], documentation: "Least Common Multiple."),
        .function(name: "math.ldexp", parameters: ["x", "i"], documentation: "Return x * (2**i)."),
        .function(name: "math.lgamma", parameters: ["x"], documentation: "Natural logarithm of absolute value of Gamma function at x."),
        .function(name: "math.log", parameters: [], documentation: "log(x, [base=math.e]) Return the logarithm of x to the given base."),
        .function(name: "math.log10", parameters: ["x"], documentation: "Return the base 10 logarithm of x."),
        .function(name: "math.log1p", parameters: ["x"], documentation: "Return the natural logarithm of 1+x (base e)."),
        .function(name: "math.log2", parameters: ["x"], documentation: "Return the base 2 logarithm of x."),
        .function(name: "math.modf", parameters: ["x"], documentation: "Return the fractional and integer parts of x."),
        .function(name: "math.nextafter", parameters: ["x", "y", "steps=None"], documentation: "Return the floating-point value the given number of steps after x towards y."),
        .function(name: "math.perm", parameters: ["n", "k=None"], documentation: "Number of ways to choose k items from n items without repetition and with order."),
        .function(name: "math.pow", parameters: ["x", "y"], documentation: "Return x**y (x to the power of y)."),
        .function(name: "math.prod", parameters: ["iterable", "start=1"], documentation: "Calculate the product of all the elements in the input iterable."),
        .function(name: "math.radians", parameters: ["x"], documentation: "Convert angle x from degrees to radians."),
        .function(name: "math.remainder", parameters: ["x", "y"], documentation: "Difference between x and the closest integer multiple of y."),
        .function(name: "math.sin", parameters: ["x"], documentation: "Return the sine of x (measured in radians)."),
        .function(name: "math.sinh", parameters: ["x"], documentation: "Return the hyperbolic sine of x."),
        .function(name: "math.sqrt", parameters: ["x"], documentation: "Return the square root of x."),
        .function(name: "math.sumprod", parameters: ["p", "q"], documentation: "Return the sum of products of values from two iterables p and q."),
        .function(name: "math.tan", parameters: ["x"], documentation: "Return the tangent of x (measured in radians)."),
        .function(name: "math.tanh", parameters: ["x"], documentation: "Return the hyperbolic tangent of x."),
        .function(name: "math.trunc", parameters: ["x"], documentation: "Truncates the Real x to the nearest Integral toward 0."),
        .function(name: "math.ulp", parameters: ["x"], documentation: "Return the value of the least significant bit of the float x.")
    ]
    
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
