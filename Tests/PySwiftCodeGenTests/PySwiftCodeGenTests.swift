import Testing
import Foundation
@testable import PySwiftAST
@testable import PySwiftCodeGen

// MARK: - Helper Functions

func loadResource(_ name: String, subdirectory: String? = nil) throws -> String {
    var path = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("PySwiftASTTests")
        .appendingPathComponent("Resources")
    
    if let subdir = subdirectory {
        path = path.appendingPathComponent(subdir)
    }
    
    path = path.appendingPathComponent(name)
    
    return try String(contentsOf: path, encoding: .utf8)
}

func normalizeWhitespace(_ code: String) -> String {
    // Normalize line endings and trailing whitespace
    return code
        .split(separator: "\n", omittingEmptySubsequences: false)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Basic Tests

@Test func testDebugImport() async throws {
    let source = "import pandas as pd"
    print("Original:", source)
    do {
        let ast = try parsePython(source)
        print("✅ Parsed successfully")
        let generated = generatePythonCode(from: ast)
        print("Generated:", generated)
        _ = try parsePython(generated)
        print("✅ Reparsed successfully")
    } catch {
        print("❌ Error:", error)
        throw error
    }
}

@Test func testDebugImportsFile() async throws {
    let source = try loadResource("imports.py")
    print("=== Testing imports.py ===")
    do {
        let ast = try parsePython(source)
        print("✅ Parsed successfully")
        let generated = generatePythonCode(from: ast)
        print("=== Generated Code ===")
        print(generated)
        print("=== Attempting to reparse ===")
        _ = try parsePython(generated)
        print("✅ Reparsed successfully")
    } catch {
        print("❌ Error:", error)
        throw error
    }
}

@Test func testDebugTypeAnnotation() async throws {
    let source = "x: dict[str, int]"
    print("Original:", source)
    do {
        let ast = try parsePython(source)
        print("✅ Parsed successfully")
        let generated = generatePythonCode(from: ast)
        print("Generated:", generated)
        _ = try parsePython(generated)
        print("✅ Reparsed successfully")
    } catch {
        print("❌ Error:", error)
        throw error
    }
}

@Test func testDebugChainedAssignment() async throws {
    let source = try loadResource("type_annotations.py")
    print("Testing: type_annotations.py")
    do {
        let ast = try parsePython(source)
        print("✅ Parsed successfully")
        let generated = generatePythonCode(from: ast)
        print("Generated code around lines 9-15:")
        let lines = generated.split(separator: "\n", omittingEmptySubsequences: false)
        for (i, line) in lines.enumerated() where i >= 8 && i < 15 {
            print("\(i+1): \(line)")
        }
        _ = try parsePython(generated)
        print("✅ Reparsed successfully")
    } catch {
        print("❌ Error:", error)
        throw error
    }
}

@Test func testDebugFor() async throws {
    let source = """
    for i in range(10):
        print(i)
    """
    print("Original:", source)
    do {
        let ast = try parsePython(source)
        print("✅ Parsed successfully")
        let generated = generatePythonCode(from: ast)
        print("Generated:")
        print(generated)
        _ = try parsePython(generated)
        print("✅ Reparsed successfully")
    } catch {
        print("❌ Error:", error)
        throw error
    }
}

@Test func testDebugLambda() async throws {
    let source = "func = lambda x, y=10: x + y"
    print("Original:", source)
    do {
        let ast = try parsePython(source)
        print("✅ Parsed successfully")
        let generated = generatePythonCode(from: ast)
        print("Generated:", generated)
        _ = try parsePython(generated)
        print("✅ Reparsed successfully")
    } catch {
        print("❌ Error:", error)
        throw error
    }
}

@Test func testDebugComprehension() async throws {
    let source = "squares = [x**2 for x in range(10)]"
    print("Original:", source)
    do {
        let ast = try parsePython(source)
        print("✅ Parsed successfully")
        print("AST:", ast)
        let generated = generatePythonCode(from: ast)
        print("Generated:", generated)
        _ = try parsePython(generated)
        print("✅ Reparsed successfully")
    } catch {
        print("❌ Error:", error)
        throw error
    }
}

@Test func testSimpleAssignment() async throws {
    let source = """
    x = 5
    y = 10
    """
    
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    print("=== Original ===")
    print(source)
    print("\n=== Generated ===")
    print(generated)
    
    // Should be able to parse the generated code
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts2.count == stmts1.count)
    }
}

@Test func testFunctionDefinition() async throws {
    let source = """
    def greet(name):
        return name
    """
    
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    print("=== Original ===")
    print(source)
    print("\n=== Generated ===")
    print(generated)
}

@Test func testConstants() async throws {
    let source = """
    x = 42
    y = 3.14
    z = True
    w = None
    """
    
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    print("=== Original ===")
    print(source)
    print("\n=== Generated ===")
    print(generated)
    
    // Verify it round-trips
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts) = reparsed {
        #expect(stmts.count == 4)
    }
}

@Test func testSimpleStatements() async throws {
    let source = """
    pass
    break
    continue
    return 42
    """
    
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    print("=== Original ===")
    print(source)
    print("\n=== Generated ===")
    print(generated)
}

// MARK: - Resource File Round-Trip Tests

@Test func testMinimalRoundTrip() async throws {
    let source = try loadResource("minimal.py")
    
    print("Testing: minimal.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    // Should be able to parse the generated code
    let reparsed = try parsePython(generated)
    
    // Verify structure matches
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count, "Statement count should match")
    }
}

@Test func testSimpleAssignmentFileRoundTrip() async throws {
    let source = try loadResource("simple_assignment.py")
    
    print("Testing: simple_assignment.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testFunctionsFileRoundTrip() async throws {
    let source = try loadResource("functions.py")
    
    print("Testing: functions.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    print("\n=== Generated Preview ===")
    print(String(generated.prefix(500)))
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testClassesFileRoundTrip() async throws {
    let source = try loadResource("classes.py")
    
    print("Testing: classes.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testControlFlowFileRoundTrip() async throws {
    let source = try loadResource("control_flow.py")
    
    print("Testing: control_flow.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    print("=== Generated Code ===")
    print(generated)
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        print("Original statements: \(stmts1.count)")
        print("Reparsed statements: \(stmts2.count)")
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testOperatorsFileRoundTrip() async throws {
    let source = try loadResource("operators.py")
    
    print("Testing: operators.py")
    print("Source lines: \(source.split(separator: "\n").count)")
    print("Lines 29-33:")
    let srcLines = source.split(separator: "\n", omittingEmptySubsequences: false)
    for (i, line) in srcLines.enumerated() where i >= 28 && i <= 32 {
        print("\(i+1): \(line)")
    }
    
    let ast = try parsePython(source)
    print("✅ Parsed original")
    let generated = generatePythonCode(from: ast)
    
    print("Generated code lines 29-33:")
    let lines = generated.split(separator: "\n", omittingEmptySubsequences: false)
    for (i, line) in lines.enumerated() where i >= 28 && i <= 32 {
        print("\(i+1): \(line)")
    }
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testCollectionsFileRoundTrip() async throws {
    let source = try loadResource("collections.py")
    
    print("Testing: collections.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    print("Generated code lines 14-24:")
    let lines = generated.split(separator: "\n", omittingEmptySubsequences: false)
    for (i, line) in lines.enumerated() where i >= 13 && i <= 23 {
        print("\(i+1): \(line)")
    }
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testComprehensionsFileRoundTrip() async throws {
    let source = try loadResource("comprehensions.py")
    
    print("Testing: comprehensions.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    print("🔍 Generated code preview:")
    print(generated.prefix(500))
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testLambdasFileRoundTrip() async throws {
    let source = try loadResource("lambdas.py")
    
    print("Testing: lambdas.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testDecoratorsFileRoundTrip() async throws {
    let source = try loadResource("decorators.py")
    
    print("Testing: decorators.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testImportsFileRoundTrip() async throws {
    let source = try loadResource("imports.py")
    
    print("Testing: imports.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testTypeAnnotationsFileRoundTrip() async throws {
    let source = try loadResource("type_annotations.py")
    
    print("Testing: type_annotations.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testAsyncAwaitFileRoundTrip() async throws {
    let source = try loadResource("async_await.py")
    
    print("Testing: async_await.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    print("\n=== Generated Code ===")
    print(generated)
    print("=== End Generated ===\n")
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}

@Test func testNewFeaturesFileRoundTrip() async throws {
    let source = try loadResource("new_features.py", subdirectory: "test_files")
    
    print("Testing: new_features.py")
    let ast = try parsePython(source)
    let generated = generatePythonCode(from: ast)
    
    print("\n=== Generated Preview ===")
    print(String(generated.prefix(800)))
    
    let reparsed = try parsePython(generated)
    
    if case .module(let stmts1) = ast, case .module(let stmts2) = reparsed {
        #expect(stmts1.count == stmts2.count)
    }
}
