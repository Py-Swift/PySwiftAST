import Testing
import Foundation
@testable import PySwiftIDE
@testable import MonacoApi

@Test func testBasicValidation() async throws {
    let code = """
    def func()
        pass
    """
    
    let validator = PythonValidator(source: code)
    let result = validator.validate()
    
    #expect(result.hasErrors)
    #expect(result.diagnostics.count == 1)
    
    let diagnostic = result.diagnostics[0]
    #expect(diagnostic.severity == .error)
    #expect(diagnostic.range.startLineNumber == 1)
    #expect(diagnostic.message.contains(":"))
}

@Test func testValidCode() async throws {
    let code = """
    def func():
        pass
    """
    
    let validator = PythonValidator(source: code)
    let result = validator.validate()
    
    #expect(!result.hasErrors)
    #expect(result.diagnostics.count == 0)
    #expect(result.ast != nil)
}

@Test func testCodeActions() async throws {
    let code = """
    def func()
        pass
    """
    
    let validator = PythonValidator(source: code)
    let result = validator.validate()
    
    #expect(result.diagnostics.count == 1)
    
    let actions = validator.getCodeActions(
        for: result.diagnostics[0].range,
        diagnostics: result.diagnostics
    )
    
    #expect(actions.count > 0)
    #expect(actions[0].title.contains(":"))
    #expect(actions[0].kind == .quickfix)
    #expect(actions[0].isPreferred == true)
}

@Test func testRangeCreation() async throws {
    let range = IDERange.from(line: 5, column: 10, length: 3)
    
    #expect(range.startLineNumber == 5)
    #expect(range.startColumn == 10)
    #expect(range.endLineNumber == 5)
    #expect(range.endColumn == 13)
}

@Test func testDiagnosticSerialization() async throws {
    let diagnostic = Diagnostic(
        severity: .error,
        message: "Test error",
        range: IDERange.from(line: 1, column: 1),
        code: "test-code"
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(diagnostic)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Diagnostic.self, from: data)
    
    #expect(decoded.severity == .error)
    #expect(decoded.message == "Test error")
    #expect(decoded.code == "test-code")
}
