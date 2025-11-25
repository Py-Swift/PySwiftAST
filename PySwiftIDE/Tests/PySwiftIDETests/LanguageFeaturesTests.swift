import Testing
import Foundation
@testable import PySwiftIDE
@testable import MonacoApi

// MARK: - Hover Tests

@Test func testHoverSerialization() async throws {
    let hover = Hover.markdown("This is a **test**", range: IDERange.from(line: 1, column: 5))
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(hover)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Hover.self, from: data)
    
    #expect(decoded.range?.startLineNumber == 1)
    #expect(decoded.range?.startColumn == 5)
}

@Test func testHoverCodeBlock() async throws {
    let hover = Hover.code("def test():\n    pass", language: "python")
    
    #expect(hover.contents.count == 1)
    if case .markdown(let md) = hover.contents[0] {
        #expect(md.value.contains("```python"))
    } else {
        Issue.record("Expected markdown content")
    }
}

// MARK: - Completion Tests

@Test func testCompletionItemKeyword() async throws {
    let item = CompletionItem.keyword("def")
    
    #expect(item.label == "def")
    #expect(item.kind == .keyword)
    #expect(item.sortText?.starts(with: "0_") == true)
}

@Test func testCompletionItemFunction() async throws {
    let item = CompletionItem.function(
        name: "calculate",
        parameters: ["x", "y"],
        detail: "Calculate something"
    )
    
    #expect(item.label == "calculate")
    #expect(item.kind == .function)
    #expect(item.insertTextFormat == .snippet)
    #expect(item.insertText.contains("${1:x}"))
    #expect(item.insertText.contains("${2:y}"))
}

@Test func testCompletionListSerialization() async throws {
    let list = CompletionList(
        suggestions: [
            .keyword("def"),
            .keyword("class"),
            .variable(name: "x", type: "int")
        ],
        incomplete: false
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(list)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(CompletionList.self, from: data)
    
    #expect(decoded.suggestions.count == 3)
    #expect(decoded.incomplete == false)
}

// MARK: - Symbol Tests

@Test func testDocumentSymbolFunction() async throws {
    let symbol = DocumentSymbol.function(
        name: "test_function",
        parameters: "x: int, y: str",
        range: IDERange.from(line: 1, column: 1, length: 50),
        selectionRange: IDERange.from(line: 1, column: 5, length: 13)
    )
    
    #expect(symbol.name == "test_function")
    #expect(symbol.kind == .function)
    #expect(symbol.detail == "(x: int, y: str)")
}

@Test func testDocumentSymbolClass() async throws {
    let methodSymbol = DocumentSymbol.method(
        name: "__init__",
        parameters: "self",
        range: IDERange.from(line: 2, column: 5, length: 20),
        selectionRange: IDERange.from(line: 2, column: 9, length: 8)
    )
    
    let classSymbol = DocumentSymbol.class(
        name: "MyClass",
        bases: ["BaseClass"],
        range: IDERange.from(line: 1, column: 1, length: 100),
        selectionRange: IDERange.from(line: 1, column: 7, length: 7),
        children: [methodSymbol]
    )
    
    #expect(classSymbol.name == "MyClass")
    #expect(classSymbol.kind == .class)
    #expect(classSymbol.detail == "(BaseClass)")
    #expect(classSymbol.children?.count == 1)
}

@Test func testLocationSerialization() async throws {
    let location = Location(
        uri: "file:///path/to/file.py",
        range: IDERange.from(line: 10, column: 5, length: 10)
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(location)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Location.self, from: data)
    
    #expect(decoded.uri == "file:///path/to/file.py")
    #expect(decoded.range.startLineNumber == 10)
}

// MARK: - Signature Help Tests

@Test func testSignatureHelp() async throws {
    let help = SignatureHelp.function(
        name: "calculate",
        parameters: [
            (name: "x", type: "int", doc: "First number"),
            (name: "y", type: "int", doc: "Second number")
        ],
        activeParameter: 0,
        documentation: "Calculates something"
    )
    
    #expect(help.signatures.count == 1)
    #expect(help.activeParameter == 0)
    
    let sig = help.signatures[0]
    #expect(sig.label == "calculate(x: int, y: int)")
    #expect(sig.parameters?.count == 2)
}

// MARK: - Inlay Hints Tests

@Test func testInlayHintType() async throws {
    let hint = InlayHint.typeHint(
        at: Position(lineNumber: 5, column: 10),
        type: "int",
        tooltip: "Type inferred from context"
    )
    
    #expect(hint.label == ": int")
    #expect(hint.kind == .type)
    #expect(hint.position.lineNumber == 5)
}

@Test func testInlayHintParameter() async throws {
    let hint = InlayHint.parameterHint(
        at: Position(lineNumber: 3, column: 15),
        name: "timeout"
    )
    
    #expect(hint.label == "timeout: ")
    #expect(hint.kind == .parameter)
}

// MARK: - Folding Range Tests

@Test func testFoldingRangeBlock() async throws {
    let range = FoldingRange.block(start: 1, end: 10)
    
    #expect(range.start == 1)
    #expect(range.end == 10)
    #expect(range.kind == nil)
}

@Test func testFoldingRangeComment() async throws {
    let range = FoldingRange.comment(start: 5, end: 8)
    
    #expect(range.start == 5)
    #expect(range.end == 8)
    #expect(range.kind == .comment)
}

@Test func testFoldingRangeImports() async throws {
    let range = FoldingRange.imports(start: 1, end: 5)
    
    #expect(range.kind == .imports)
}

// MARK: - Formatting Tests

@Test func testFormattingOptions() async throws {
    let options = FormattingOptions(tabSize: 4, insertSpaces: true)
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(options)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(FormattingOptions.self, from: data)
    
    #expect(decoded.tabSize == 4)
    #expect(decoded.insertSpaces == true)
}

// MARK: - Integration Tests

@Test func testCompleteLanguageFeaturesSerialization() async throws {
    // Test that all language features can be encoded/decoded
    struct LanguageFeatures: Codable {
        let hover: Hover
        let completion: CompletionList
        let symbol: DocumentSymbol
        let location: Location
        let signature: SignatureHelp
        let inlayHint: InlayHint
        let foldingRange: FoldingRange
        let formattingOptions: FormattingOptions
    }
    
    let features = LanguageFeatures(
        hover: .markdown("Test"),
        completion: CompletionList(suggestions: [.keyword("def")]),
        symbol: .function(
            name: "test",
            range: IDERange.from(line: 1, column: 1),
            selectionRange: IDERange.from(line: 1, column: 1)
        ),
        location: .current(range: IDERange.from(line: 1, column: 1)),
        signature: SignatureHelp.function(name: "test", parameters: []),
        inlayHint: .typeHint(at: Position(lineNumber: 1, column: 1), type: "int"),
        foldingRange: .block(start: 1, end: 10),
        formattingOptions: FormattingOptions()
    )
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(features)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(LanguageFeatures.self, from: data)
    
    #expect(decoded.symbol.name == "test")
    #expect(decoded.completion.suggestions.count == 1)
    #expect(decoded.foldingRange.start == 1)
}
