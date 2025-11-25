import Foundation
import PySwiftIDE
import PySwiftAST
import MonacoApi

// MARK: - Complete Monaco Language Server Example

/// Example implementation showing how to integrate PySwiftIDE with Monaco Editor
/// This demonstrates all Monaco language features using PySwiftAST
@main
struct MonacoLanguageServer {
    static func main() async throws {
        print("🎯 PySwiftIDE - Complete Monaco Language Features Demo\n")
        
        // Sample Python code for demonstration
        let pythonCode = """
        def calculate(x, y):
            '''Calculate the sum of two numbers'''
            return x + y
        
        class Calculator:
            def __init__(self):
                self.history = []
            
            def add(self, a, b):
                result = a + b
                self.history.append(result)
                return result
        
        # Usage
        calc = Calculator()
        value = calc.add(10, 20)
        """
        
        demonstrateValidation(pythonCode)
        demonstrateHover()
        demonstrateCompletion()
        demonstrateSymbols()
        demonstrateSignatureHelp()
        demonstrateInlayHints()
        demonstrateFolding()
        demonstrateFormatting()
        
        print("\n✅ All language features demonstrated!")
    }
    
    // MARK: - 1. Validation & Diagnostics
    
    static func demonstrateValidation(_ code: String) {
        print("=== 1. Validation & Diagnostics ===")
        
        let validator = PythonValidator(source: code)
        let result = validator.validate()
        
        if result.hasErrors {
            print("❌ Validation errors:")
            for diagnostic in result.diagnostics {
                print("  Line \(diagnostic.range.startLineNumber): \(diagnostic.message)")
            }
        } else {
            print("✅ Code is valid")
            print("  AST nodes: \(String(describing: result.ast).prefix(100))...")
        }
        
        // Demonstrate error with quick fix
        let invalidCode = """
        def broken()
            pass
        """
        let invalidResult = PythonValidator(source: invalidCode).validate()
        if let diagnostic = invalidResult.diagnostics.first {
            print("\n📍 Error detected:")
            print("  \(diagnostic.message)")
            
            let actions = validator.getCodeActions(for: diagnostic.range, diagnostics: [diagnostic])
            if let action = actions.first {
                print("  💡 Quick fix available: \(action.title)")
            }
        }
        print()
    }
    
    // MARK: - 2. Hover Information
    
    static func demonstrateHover() {
        print("=== 2. Hover Provider ===")
        
        // Hover with markdown
        let markdownHover = Hover.markdown("""
        **Function**: `calculate`
        
        Calculate the sum of two numbers.
        
        **Parameters**:
        - `x`: First number
        - `y`: Second number
        
        **Returns**: The sum of x and y
        """, range: IDERange.from(line: 1, column: 5, length: 9))
        
        print("📝 Markdown hover created")
        print("  Range: Line \(markdownHover.range!.startLineNumber)")
        
        // Hover with code block
        let codeHover = Hover.code("""
        def calculate(x: int, y: int) -> int:
            return x + y
        """, language: "python")
        
        print("💻 Code hover created")
        print("  Contents: \(codeHover.contents.count) item(s)")
        
        // Serialize to JSON for Monaco
        if let json = try? JSONEncoder().encode(markdownHover),
           let jsonString = String(data: json, encoding: .utf8) {
            print("  JSON: \(jsonString.prefix(80))...")
        }
        print()
    }
    
    // MARK: - 3. Code Completion
    
    static func demonstrateCompletion() {
        print("=== 3. Completion Provider ===")
        
        // Create completion suggestions
        let completions = CompletionList(suggestions: [
            // Python keywords
            .keyword("def"),
            .keyword("class"),
            .keyword("return"),
            
            // Function with parameters
            .function(
                name: "calculate",
                parameters: ["x", "y"],
                detail: "Calculate the sum of two numbers",
                documentation: "Returns x + y"
            ),
            
            // Class completion
            .class(name: "Calculator", documentation: "A calculator class"),
            
            // Variable completion
            .variable(name: "result", type: "int"),
            .variable(name: "value", type: "float")
        ])
        
        print("📋 Created \(completions.suggestions.count) completion items")
        for item in completions.suggestions.prefix(3) {
            print("  - \(item.label) (\(item.kind))")
        }
        
        // Show snippet example
        if let funcCompletion = completions.suggestions.first(where: { $0.kind == .function }) {
            print("\n🔧 Function completion with snippet:")
            print("  Insert text: \(funcCompletion.insertText)")
            print("  Format: \(funcCompletion.insertTextFormat ?? .plainText)")
        }
        print()
    }
    
    // MARK: - 4. Document Symbols (Outline)
    
    static func demonstrateSymbols() {
        print("=== 4. Document Symbol Provider ===")
        
        // Create symbol tree matching the Python code structure
        let symbols = [
            // Function symbol
            DocumentSymbol.function(
                name: "calculate",
                parameters: "x, y",
                range: IDERange(startLineNumber: 1, startColumn: 1, endLineNumber: 3, endColumn: 20),
                selectionRange: IDERange.from(line: 1, column: 5, length: 9)
            ),
            
            // Class symbol with methods
            DocumentSymbol.class(
                name: "Calculator",
                range: IDERange(startLineNumber: 5, startColumn: 1, endLineNumber: 12, endColumn: 22),
                selectionRange: IDERange.from(line: 5, column: 7, length: 10),
                children: [
                    DocumentSymbol.method(
                        name: "__init__",
                        parameters: "self",
                        range: IDERange(startLineNumber: 6, startColumn: 5, endLineNumber: 7, endColumn: 27),
                        selectionRange: IDERange.from(line: 6, column: 9, length: 8)
                    ),
                    DocumentSymbol.method(
                        name: "add",
                        parameters: "self, a, b",
                        range: IDERange(startLineNumber: 9, startColumn: 5, endLineNumber: 12, endColumn: 22),
                        selectionRange: IDERange.from(line: 9, column: 9, length: 3)
                    )
                ]
            ),
            
            // Variable symbol
            DocumentSymbol.variable(
                name: "calc",
                type: "Calculator",
                range: IDERange.from(line: 15, column: 1, length: 23),
                selectionRange: IDERange.from(line: 15, column: 1, length: 4)
            )
        ]
        
        print("🗂️  Created document symbols:")
        for symbol in symbols {
            print("  \(symbol.kind): \(symbol.name)")
            if let children = symbol.children {
                for child in children {
                    print("    └─ \(child.kind): \(child.name)")
                }
            }
        }
        print()
    }
    
    // MARK: - 5. Signature Help
    
    static func demonstrateSignatureHelp() {
        print("=== 5. Signature Help Provider ===")
        
        let signatureHelp = SignatureHelp.function(
            name: "calculate",
            parameters: [
                (name: "x", type: "int", doc: "The first number to add"),
                (name: "y", type: "int", doc: "The second number to add")
            ],
            activeParameter: 0,
            documentation: "Calculate the sum of two numbers"
        )
        
        print("✍️  Signature help:")
        if let sig = signatureHelp.signatures.first {
            print("  Label: \(sig.label)")
            print("  Active parameter: \(signatureHelp.activeParameter ?? 0)")
            if let params = sig.parameters {
                print("  Parameters:")
                for param in params {
                    print("    - \(param.label)")
                }
            }
        }
        print()
    }
    
    // MARK: - 6. Inlay Hints
    
    static func demonstrateInlayHints() {
        print("=== 6. Inlay Hints Provider ===")
        
        let hints = [
            // Type hints
            InlayHint.typeHint(
                at: Position(lineNumber: 3, column: 12),
                type: "int",
                tooltip: "Inferred return type"
            ),
            
            // Parameter name hints
            InlayHint.parameterHint(
                at: Position(lineNumber: 16, column: 19),
                name: "a",
                tooltip: "First parameter"
            ),
            InlayHint.parameterHint(
                at: Position(lineNumber: 16, column: 23),
                name: "b",
                tooltip: "Second parameter"
            )
        ]
        
        print("💡 Created \(hints.count) inlay hints:")
        for hint in hints {
            let kindStr = hint.kind == .type ? "type" : "parameter"
            print("  Line \(hint.position.lineNumber): \(hint.label) (\(kindStr))")
        }
        print()
    }
    
    // MARK: - 7. Code Folding
    
    static func demonstrateFolding() {
        print("=== 7. Folding Range Provider ===")
        
        let foldingRanges = [
            // Function body
            FoldingRange.block(start: 1, end: 3),
            
            // Class body
            FoldingRange.block(start: 5, end: 12),
            
            // Method bodies
            FoldingRange.block(start: 6, end: 7),
            FoldingRange.block(start: 9, end: 12),
            
            // Comment section (if exists)
            FoldingRange.comment(start: 14, end: 14)
        ]
        
        print("📁 Created \(foldingRanges.count) folding ranges:")
        for range in foldingRanges {
            let kindStr = range.kind?.rawValue ?? "block"
            print("  Lines \(range.start)-\(range.end) (\(kindStr))")
        }
        print()
    }
    
    // MARK: - 8. Code Formatting
    
    static func demonstrateFormatting() {
        print("=== 8. Formatting Provider ===")
        
        let options = FormattingOptions(tabSize: 4, insertSpaces: true)
        
        print("⚙️  Formatting options:")
        print("  Tab size: \(options.tabSize)")
        print("  Use spaces: \(options.insertSpaces)")
        
        // Example formatting edits
        let formattingEdits = [
            TextEdit(
                range: IDERange.from(line: 1, column: 1, length: 0),
                newText: "# Auto-formatted code\n"
            ),
            TextEdit(
                range: IDERange(startLineNumber: 2, startColumn: 1, endLineNumber: 2, endColumn: 5),
                newText: "    "  // Fix indentation
            )
        ]
        
        print("  Generated \(formattingEdits.count) formatting edits")
        print()
    }
}

// MARK: - Monaco Integration Example

extension MonacoLanguageServer {
    /// Example showing how to serialize all features to JSON for Monaco
    static func demonstrateMonacoIntegration() throws {
        print("=== Monaco Integration Example ===\n")
        
        // Create a complete language features response
        struct LanguageFeatures: Codable {
            let diagnostics: [Diagnostic]
            let hover: Hover?
            let completions: CompletionList
            let symbols: [DocumentSymbol]
            let signatureHelp: SignatureHelp?
            let inlayHints: [InlayHint]
            let foldingRanges: [FoldingRange]
        }
        
        let features = LanguageFeatures(
            diagnostics: [],
            hover: .markdown("**Function**: `test`"),
            completions: CompletionList(suggestions: [.keyword("def")]),
            symbols: [.function(name: "test", range: .from(line: 1, column: 1), selectionRange: .from(line: 1, column: 1))],
            signatureHelp: .function(name: "test", parameters: []),
            inlayHints: [.typeHint(at: Position(lineNumber: 1, column: 1), type: "int")],
            foldingRanges: [.block(start: 1, end: 10)]
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(features)
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 JSON for Monaco Editor:")
            print(jsonString.prefix(500))
            print("...")
        }
    }
}
