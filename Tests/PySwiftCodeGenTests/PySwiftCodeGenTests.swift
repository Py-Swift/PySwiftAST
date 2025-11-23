import Testing
@testable import PySwiftAST
@testable import PySwiftCodeGen

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
