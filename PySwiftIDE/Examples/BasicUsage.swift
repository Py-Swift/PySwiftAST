import Foundation
import PySwiftIDE
import MonacoApi

// MARK: - Basic Validation Example

func validatePythonCode() {
    let code = """
    def hello(name):
        print(f"Hello, {name}!")
        return True
    
    class Person:
        def __init__(self, name, age):
            self.name = name
            self.age = age
    """
    
    let validator = PythonValidator(source: code)
    let result = validator.validate()
    
    if result.hasErrors {
        print("❌ Validation failed with \(result.diagnostics.count) error(s):")
        for diagnostic in result.diagnostics {
            print("  - Line \(diagnostic.range.startLineNumber): \(diagnostic.message)")
        }
    } else {
        print("✅ Code is valid!")
        print("  AST nodes: \(String(describing: result.ast))")
    }
}

// MARK: - Error Reporting Example

func showErrorMessages() {
    let invalidCode = """
    def broken_func()
        print("missing colon")
    
    class BadClass
        pass
    """
    
    let validator = PythonValidator(source: invalidCode)
    let result = validator.validate()
    
    print("\n=== Error Diagnostics ===")
    for diagnostic in result.diagnostics {
        let severity = diagnostic.severity == .error ? "ERROR" : "WARNING"
        print("[\(severity)] \(diagnostic.message)")
        print("  Location: Line \(diagnostic.range.startLineNumber), Column \(diagnostic.range.startColumn)")
        if let code = diagnostic.code {
            print("  Code: \(code)")
        }
    }
}

// MARK: - Code Actions Example

func generateQuickFixes() {
    let code = """
    def func()
        pass
    """
    
    let validator = PythonValidator(source: code)
    let result = validator.validate()
    
    if let firstDiagnostic = result.diagnostics.first {
        let actions = validator.getCodeActions(
            for: firstDiagnostic.range,
            diagnostics: result.diagnostics
        )
        
        print("\n=== Available Quick Fixes ===")
        for action in actions {
            print("📝 \(action.title)")
            if action.isPreferred == true {
                print("   ⭐️ Preferred fix")
            }
            if let edit = action.edit, let changes = edit.changes {
                print("   Changes:")
                for (uri, edits) in changes {
                    print("   - File: \(uri)")
                    for textEdit in edits {
                        print("     Insert '\(textEdit.newText)' at line \(textEdit.range.startLineNumber)")
                    }
                }
            }
        }
    }
}

// MARK: - JSON Serialization Example

func serializeToJSON() throws {
    let code = """
    def test()
        pass
    """
    
    let validator = PythonValidator(source: code)
    let result = validator.validate()
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    
    // Serialize diagnostics to JSON for Monaco Editor
    let jsonData = try encoder.encode(result.diagnostics)
    let jsonString = String(data: jsonData, encoding: .utf8)!
    
    print("\n=== Monaco-Compatible JSON ===")
    print(jsonString)
}

// MARK: - Thread Safety Example

func parseOnBackgroundThread() async {
    let code = """
    def async_example():
        result = await fetch_data()
        return process(result)
    """
    
    // Safe to use on background thread - all types are Sendable
    let result = await Task.detached {
        let validator = PythonValidator(source: code)
        return validator.validate()
    }.value
    
    print("\n=== Background Thread Validation ===")
    print("Valid: \(!result.hasErrors)")
    print("Diagnostics: \(result.diagnostics.count)")
}

// MARK: - Main Entry Point

@main
struct BasicUsageExample {
    static func main() async throws {
        print("🐍 PySwiftIDE - Basic Usage Examples\n")
        
        validatePythonCode()
        showErrorMessages()
        generateQuickFixes()
        try serializeToJSON()
        await parseOnBackgroundThread()
        
        print("\n✅ All examples completed!")
    }
}
