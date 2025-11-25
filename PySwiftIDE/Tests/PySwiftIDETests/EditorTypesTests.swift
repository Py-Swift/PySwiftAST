import Testing
import Foundation
@testable import MonacoApi

@Suite("Editor Types Tests")
struct EditorTypesTests {
    
    @Test("Editor enums serialize correctly")
    func testEditorEnumsSerialization() async throws {
        // Test ScrollType
        let scrollSmooth = ScrollType.smooth
        let scrollData = try JSONEncoder().encode(scrollSmooth)
        let scrollDecoded = try JSONDecoder().decode(ScrollType.self, from: scrollData)
        #expect(scrollDecoded == .smooth)
        
        // Test TextEditorCursorStyle
        let cursorBlock = TextEditorCursorStyle.block
        let cursorData = try JSONEncoder().encode(cursorBlock)
        let cursorDecoded = try JSONDecoder().decode(TextEditorCursorStyle.self, from: cursorData)
        #expect(cursorDecoded == .block)
        
        // Test EndOfLineSequence
        let eolLF = EndOfLineSequence.lf
        let eolData = try JSONEncoder().encode(eolLF)
        let eolDecoded = try JSONDecoder().decode(EndOfLineSequence.self, from: eolData)
        #expect(eolDecoded == .lf)
    }
    
    @Test("EditorScrollbarOptions serializes correctly")
    func testScrollbarOptions() async throws {
        let options = EditorScrollbarOptions(
            arrowSize: 11,
            vertical: .auto,
            horizontal: .hidden,
            useShadows: true,
            verticalScrollbarSize: 14,
            handleMouseWheel: true
        )
        
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(EditorScrollbarOptions.self, from: data)
        
        #expect(decoded.arrowSize == 11)
        #expect(decoded.vertical == .auto)
        #expect(decoded.horizontal == .hidden)
        #expect(decoded.useShadows == true)
        #expect(decoded.verticalScrollbarSize == 14)
        #expect(decoded.handleMouseWheel == true)
    }
    
    @Test("EditorMinimapOptions serializes correctly")
    func testMinimapOptions() async throws {
        let options = EditorMinimapOptions(
            enabled: true,
            autohide: false,
            side: .right,
            renderCharacters: true,
            maxColumn: 120,
            scale: 1
        )
        
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(EditorMinimapOptions.self, from: data)
        
        #expect(decoded.enabled == true)
        #expect(decoded.autohide == false)
        #expect(decoded.side == .right)
        #expect(decoded.renderCharacters == true)
        #expect(decoded.maxColumn == 120)
        #expect(decoded.scale == 1)
    }
    
    @Test("QuickSuggestionsOptions serializes correctly")
    func testQuickSuggestionsOptions() async throws {
        let options = QuickSuggestionsOptions(
            other: true,
            comments: false,
            strings: false
        )
        
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(QuickSuggestionsOptions.self, from: data)
        
        #expect(decoded.other == true)
        #expect(decoded.comments == false)
        #expect(decoded.strings == false)
    }
    
    @Test("EditorConfiguration serializes correctly")
    func testEditorConfiguration() async throws {
        let config = EditorConfiguration(
            value: "def hello():\n    print('world')",
            language: "python",
            theme: "vs-dark",
            lineNumbers: "on",
            minimap: EditorMinimapOptions(enabled: true, side: .right),
            scrollbar: EditorScrollbarOptions(vertical: .auto, horizontal: .auto),
            readOnly: false,
            tabSize: 4,
            insertSpaces: true,
            autoIndent: .full,
            cursorStyle: .line,
            cursorBlinking: .blink,
            formatOnPaste: true,
            formatOnType: true,
            fontFamily: "Menlo, Monaco, 'Courier New', monospace",
            fontSize: 14
        )
        
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(EditorConfiguration.self, from: data)
        
        #expect(decoded.value == "def hello():\n    print('world')")
        #expect(decoded.language == "python")
        #expect(decoded.theme == "vs-dark")
        #expect(decoded.lineNumbers == "on")
        #expect(decoded.tabSize == 4)
        #expect(decoded.insertSpaces == true)
        #expect(decoded.readOnly == false)
        #expect(decoded.cursorStyle == TextEditorCursorStyle.line)
        #expect(decoded.cursorBlinking == TextEditorCursorBlinkingStyle.blink)
        #expect(decoded.fontSize == 14)
        #expect(decoded.autoIndent == EditorAutoIndentStrategy.full)
        #expect(decoded.formatOnPaste == true)
        #expect(decoded.formatOnType == true)
    }
    
    @Test("TextModelOptions serializes correctly")
    func testTextModelOptions() async throws {
        let options = TextModelOptions(
            tabSize: 4,
            insertSpaces: true,
            detectIndentation: true,
            trimAutoWhitespace: true,
            defaultEOL: .lf
        )
        
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(TextModelOptions.self, from: data)
        
        #expect(decoded.tabSize == 4)
        #expect(decoded.insertSpaces == true)
        #expect(decoded.detectIndentation == true)
        #expect(decoded.trimAutoWhitespace == true)
        #expect(decoded.defaultEOL == .lf)
    }
    
    @Test("ScrollPosition serializes correctly")
    func testScrollPosition() async throws {
        let position = ScrollPosition(scrollLeft: 100, scrollTop: 200)
        
        let data = try JSONEncoder().encode(position)
        let decoded = try JSONDecoder().decode(ScrollPosition.self, from: data)
        
        #expect(decoded.scrollLeft == 100)
        #expect(decoded.scrollTop == 200)
    }
    
    @Test("EditorLayoutInfo serializes correctly")
    func testEditorLayoutInfo() async throws {
        let overviewRuler = OverviewRulerPosition(top: 0, width: 15, height: 600)
        let layout = EditorLayoutInfo(
            width: 800,
            height: 600,
            glyphMarginLeft: 0,
            glyphMarginWidth: 30,
            lineNumbersLeft: 30,
            lineNumbersWidth: 50,
            decorationsLeft: 80,
            decorationsWidth: 10,
            contentLeft: 90,
            contentWidth: 710,
            contentHeight: 600,
            minimapLeft: 785,
            minimapWidth: 0,
            verticalScrollbarWidth: 15,
            horizontalScrollbarHeight: 10,
            overviewRuler: overviewRuler
        )
        
        let data = try JSONEncoder().encode(layout)
        let decoded = try JSONDecoder().decode(EditorLayoutInfo.self, from: data)
        
        #expect(decoded.width == 800)
        #expect(decoded.height == 600)
        #expect(decoded.contentWidth == 710)
        #expect(decoded.contentLeft == 90)
        #expect(decoded.lineNumbersWidth == 50)
        #expect(decoded.overviewRuler.width == 15)
    }
    
    @Test("BracketPairColorizationOptions serializes correctly")
    func testBracketPairColorization() async throws {
        let options = BracketPairColorizationOptions(
            enabled: true,
            independentColorPoolPerBracketType: true
        )
        
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(BracketPairColorizationOptions.self, from: data)
        
        #expect(decoded.enabled == true)
        #expect(decoded.independentColorPoolPerBracketType == true)
    }
    
    @Test("Complete editor configuration with all options")
    func testCompleteEditorConfiguration() async throws {
        let config = EditorConfiguration(
            value: "# Python code",
            language: "python",
            theme: "vs-dark",
            lineNumbers: "on",
            rulers: [80, 120],
            wordWrap: "on",
            wordWrapColumn: 80,
            wrappingIndent: .indent,
            renderWhitespace: "boundary",
            renderControlCharacters: true,
            minimap: EditorMinimapOptions(
                enabled: true,
                side: .right,
                renderCharacters: true,
                maxColumn: 120
            ),
            scrollbar: EditorScrollbarOptions(
                vertical: .auto,
                horizontal: .auto,
                useShadows: true,
                handleMouseWheel: true
            ),
            padding: EditorPaddingOptions(top: 10, bottom: 10),
            readOnly: false,
            tabSize: 4,
            insertSpaces: true,
            detectIndentation: true,
            autoIndent: .full,
            cursorStyle: .line,
            cursorBlinking: .blink,
            smoothScrolling: true,
            scrollBeyondLastLine: true,
            selectionHighlight: true,
            quickSuggestions: QuickSuggestionsOptions(other: true, comments: false, strings: false),
            formatOnPaste: true,
            formatOnType: true,
            autoClosingBrackets: "languageDefined",
            bracketPairColorization: BracketPairColorizationOptions(enabled: true),
            fontSize: 14,
            lineHeight: 20,
            automaticLayout: true
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Verify JSON is properly formatted
        #expect(jsonString.contains("\"language\" : \"python\""))
        #expect(jsonString.contains("\"tabSize\" : 4"))
        #expect(jsonString.contains("\"fontSize\" : 14"))
        
        // Verify roundtrip
        let decoded = try JSONDecoder().decode(EditorConfiguration.self, from: data)
        #expect(decoded.language == "python")
        #expect(decoded.tabSize == 4)
        #expect(decoded.fontSize == 14)
    }
}
