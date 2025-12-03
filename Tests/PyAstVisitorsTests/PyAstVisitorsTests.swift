import XCTest
@testable import PySwiftAST
@testable import PyAstVisitors

final class PyAstVisitorsTests: XCTestCase {
    
    // MARK: - VariableFinder Tests
    
    func testVariableFinder() throws {
        let source = """
        x = 10
        y = 20
        z: int = 30
        w += 5
        """
        
        let module = try parsePython(source)
        
        let finder = VariableFinder()
        module.accept(visitor: finder)
        
        XCTAssertEqual(finder.variables.count, 4)
        XCTAssertEqual(finder.variables["x"], "assigned")
        XCTAssertEqual(finder.variables["y"], "assigned")
        XCTAssertEqual(finder.variables["z"], "annotated")
        XCTAssertEqual(finder.variables["w"], "augmented")
    }
    
    // MARK: - DefinitionCounter Tests
    
    func testDefinitionCounter() throws {
        let source = """
        def foo():
            pass
        
        def bar():
            pass
        
        async def baz():
            pass
        
        class MyClass:
            pass
        
        class AnotherClass:
            def method(self):
                pass
        """
        
        let module = try parsePython(source)
        
        let counter = DefinitionCounter()
        module.accept(visitor: counter)
        
        XCTAssertEqual(counter.functionCount, 3) // foo, bar, method
        XCTAssertEqual(counter.asyncFunctionCount, 1) // baz
        XCTAssertEqual(counter.classCount, 2) // MyClass, AnotherClass
    }
    
    // MARK: - ImportCollector Tests
    
    func testImportCollector() throws {
        let source = """
        import os
        import sys
        from math import sqrt, pi
        from typing import List
        """
        
        let module = try parsePython(source)
        
        let collector = ImportCollector()
        module.accept(visitor: collector)
        
        XCTAssertTrue(collector.imports.contains("os"))
        XCTAssertTrue(collector.imports.contains("sys"))
        XCTAssertTrue(collector.imports.contains("math.sqrt"))
        XCTAssertTrue(collector.imports.contains("math.pi"))
        XCTAssertTrue(collector.imports.contains("typing.List"))
    }
    
    // MARK: - NameCollector Tests
    
    func testNameCollector() throws {
        let source = """
        x = 10
        y = x + 20
        z = x + y
        """
        
        let module = try parsePython(source)
        
        let collector = NameCollector()
        module.accept(visitor: collector)
        
        // Should find: x (target), x (in x+20), y (target), x (in x+y), y (in x+y), z (target)
        XCTAssertTrue(collector.names.contains("x"))
        XCTAssertTrue(collector.names.contains("y"))
        XCTAssertTrue(collector.names.contains("z"))
        
        // x appears 3 times, y appears 2 times, z appears 1 time
        let xCount = collector.names.filter { $0 == "x" }.count
        let yCount = collector.names.filter { $0 == "y" }.count
        let zCount = collector.names.filter { $0 == "z" }.count
        
        XCTAssertEqual(xCount, 3)
        XCTAssertEqual(yCount, 2)
        XCTAssertEqual(zCount, 1)
    }
    
    // MARK: - CallFinder Tests
    
    func testCallFinder() throws {
        let source = """
        print("hello")
        len([1, 2, 3])
        obj.method()
        result = str(42)
        """
        
        let module = try parsePython(source)
        
        let finder = CallFinder()
        module.accept(visitor: finder)
        
        XCTAssertTrue(finder.calls.contains("print"))
        XCTAssertTrue(finder.calls.contains("len"))
        XCTAssertTrue(finder.calls.contains("method"))
        XCTAssertTrue(finder.calls.contains("str"))
        XCTAssertEqual(finder.calls.count, 4)
    }
    
    // MARK: - Complex Traversal Tests
    
    func testNestedFunctionTraversal() throws {
        let source = """
        def outer():
            def inner():
                x = 10
            y = 20
        """
        
        let module = try parsePython(source)
        
        let finder = VariableFinder()
        module.accept(visitor: finder)
        
        // Should find both x and y
        XCTAssertEqual(finder.variables.count, 2)
        XCTAssertNotNil(finder.variables["x"])
        XCTAssertNotNil(finder.variables["y"])
    }
    
    func testClassMethodTraversal() throws {
        let source = """
        class MyClass:
            def __init__(self):
                self.x = 10
            
            def method(self):
                y = 20
        """
        
        let module = try parsePython(source)
        
        let counter = DefinitionCounter()
        module.accept(visitor: counter)
        
        XCTAssertEqual(counter.classCount, 1)
        XCTAssertEqual(counter.functionCount, 2) // __init__ and method
    }
    
    func testConditionalTraversal() throws {
        let source = """
        if x > 0:
            y = 10
        else:
            z = 20
        """
        
        let module = try parsePython(source)
        
        let finder = VariableFinder()
        module.accept(visitor: finder)
        
        // Should traverse both branches
        XCTAssertEqual(finder.variables.count, 2)
        XCTAssertNotNil(finder.variables["y"])
        XCTAssertNotNil(finder.variables["z"])
    }
    
    func testLoopTraversal() throws {
        let source = """
        for i in range(10):
            x = i * 2
        
        while True:
            y = 42
            break
        """
        
        let module = try parsePython(source)
        
        let finder = VariableFinder()
        module.accept(visitor: finder)
        
        XCTAssertEqual(finder.variables.count, 2)
        XCTAssertNotNil(finder.variables["x"])
        XCTAssertNotNil(finder.variables["y"])
    }
    
    // MARK: - Custom Visitor Test
    
    func testCustomVisitor() throws {
        // Create a custom visitor that counts return statements
        class ReturnCounter: ASTVisitor {
            var count = 0
            
            func visit(_ node: Return) {
                count += 1
            }
        }
        
        let source = """
        def foo():
            return 1
        
        def bar():
            if True:
                return 2
            return 3
        """
        
        let module = try parsePython(source)
        
        let counter = ReturnCounter()
        module.accept(visitor: counter)
        
        XCTAssertEqual(counter.count, 3)
    }
}
