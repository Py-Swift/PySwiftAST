import XCTest
@testable import PySwiftAST
@testable import PyChecking

final class TypeCheckerQueryTests: XCTestCase {
    
    // MARK: - Helper
    
    func analyze(_ code: String) throws -> TypeChecker {
        let module = try parsePython(code)
        let checker = TypeChecker()
        _ = checker.analyze(module)
        return checker
    }
    
    // MARK: - Basic Variable Type Tests
    
    func testGetVariableTypeWithAnnotation() throws {
        let checker = try analyze("""
        x: int = 5
        y: str = "hello"
        z = 3.14
        """)
        
        XCTAssertEqual(checker.getVariableType("x"), "int")
        XCTAssertEqual(checker.getVariableType("y"), "str")
        XCTAssertEqual(checker.getVariableType("z"), "float")
    }
    
    func testGetVariableTypeAtLine() throws {
        let checker = try analyze("""
        x = 1
        x = "hello"
        x = True
        """)
        
        XCTAssertEqual(checker.getVariableType("x", at: 1), "int")
        XCTAssertEqual(checker.getVariableType("x", at: 2), "str")
        XCTAssertEqual(checker.getVariableType("x", at: 3), "bool")
    }
    
    func testGetVariableTypeInScope() throws {
        let checker = try analyze("""
        x = 1
        
        def foo():
            x = "local"
            y = 2
        """)
        
        XCTAssertEqual(checker.getVariableType("x", at: 1), "int")
        XCTAssertEqual(checker.getVariableType("x", at: 4), "str")
        XCTAssertEqual(checker.getVariableType("y", at: 5), "int")
    }
    
    // MARK: - Scope Tests
    
    func testGetScopeAtFunctionLevel() throws {
        let checker = try analyze("""
        def foo():
            x = 1
            y = 2
        """)
        
        let scope = checker.getScopeAt(line: 2, column: 0)
        XCTAssertNotNil(scope)
        XCTAssertEqual(scope?.kind, .function)
        XCTAssertEqual(scope?.name, "foo")
    }
    
    func testGetScopeAtClassLevel() throws {
        let checker = try analyze("""
        class MyClass:
            x = 1
            
            def method(self):
                y = 2
        """)
        
        let classScope = checker.getScopeAt(line: 2, column: 0)
        XCTAssertNotNil(classScope)
        XCTAssertEqual(classScope?.kind, .classScope)
        XCTAssertEqual(classScope?.name, "MyClass")
    }
    
    // MARK: - Class Context Tests
    
    func testGetClassContext() throws {
        let checker = try analyze("""
        class Outer:
            x = 1
        """)
        
        XCTAssertEqual(checker.getClassContext(lineNumber: 2), "Outer")
    }
    
    // MARK: - Class Members Tests
    
    func testGetClassMembers() throws {
        let checker = try analyze("""
        class Person:
            name: str
            age: int
            
            def __init__(self):
                self.email: str = ""
            
            def greet(self) -> str:
                return "Hello"
            
            @classmethod
            def create(cls) -> Person:
                pass
            
            @staticmethod
            def validate(x: int) -> bool:
                return True
        """)
        
        let members = checker.getClassMembers(className: "Person")
        
        // Properties
        let properties = members.filter { $0.kind == .property }
        XCTAssertTrue(properties.contains(where: { $0.name == "name" }))
        XCTAssertTrue(properties.contains(where: { $0.name == "age" }))
        XCTAssertTrue(properties.contains(where: { $0.name == "email" }))
        
        // Methods
        let methods = members.filter { $0.kind == .method }
        XCTAssertTrue(methods.contains(where: { $0.name == "greet" }))
        
        // Class methods
        let classMethods = members.filter { $0.kind == .classMethod }
        XCTAssertTrue(classMethods.contains(where: { $0.name == "create" }))
        
        // Static methods
        let staticMethods = members.filter { $0.kind == .staticMethod }
        XCTAssertTrue(staticMethods.contains(where: { $0.name == "validate" }))
    }
    
    func testGetPropertyType() throws {
        let checker = try analyze("""
        class Person:
            name: str
            age: int
        """)
        
        XCTAssertEqual(checker.getPropertyType(className: "Person", propertyName: "name"), "str")
        XCTAssertEqual(checker.getPropertyType(className: "Person", propertyName: "age"), "int")
        XCTAssertNil(checker.getPropertyType(className: "Person", propertyName: "nonexistent"))
    }
    
    // MARK: - Variable Existence Tests
    
    func testVariableExists() throws {
        let checker = try analyze("""
        x = 1
        
        def foo():
            y = 2
        """)
        
        XCTAssertTrue(checker.variableExists("x", anywhere: true))
        XCTAssertTrue(checker.variableExists("y", anywhere: true))
        XCTAssertFalse(checker.variableExists("z", anywhere: true))
    }
    
    // MARK: - Class Definition Tests
    
    func testGetClassDefinition() throws {
        let checker = try analyze("""
        class Person:
            name: str
            age: int
        """)
        
        if let (name, code) = checker.getClassDefinition(at: 2) {
            XCTAssertEqual(name, "Person")
            XCTAssertTrue(code.contains("class Person"))
            XCTAssertTrue(code.contains("name: str"))
        } else {
            XCTFail("Should find Person class")
        }
    }
    
    // MARK: - Variable Chain Tests
    
    func testVariableChainTracking() throws {
        let checker = try analyze("""
        x = 1
        y = x
        z = y
        """)
        
        XCTAssertEqual(checker.getVariableType("x"), "int")
        XCTAssertEqual(checker.getVariableType("y"), "int")
        XCTAssertEqual(checker.getVariableType("z"), "int")
    }
}
