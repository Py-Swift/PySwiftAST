import XCTest
@testable import PyChecking
@testable import PySwiftAST

final class AttributeAccessBasicTests: XCTestCase {
    
    func analyze(_ code: String) throws -> TypeChecker {
        let module = try parsePython(code)
        let checker = TypeChecker()
        _ = checker.analyze(module)
        return checker
    }
    
    func testStringMethodUpper() throws {
        let checker = try analyze("""
        text = "hello"
        upper = text.upper()
        """)
        
        // First check that basic literal assignment works
        XCTAssertEqual(checker.getVariableType("text"), "str")
        // Then check method call result
        XCTAssertEqual(checker.getVariableType("upper"), "str")
    }
    
    func testListMethodAppend() throws {
        let checker = try analyze("""
        numbers = [1, 2, 3]
        numbers.append(4)
        """)
        
        XCTAssertEqual(checker.getVariableType("numbers", at: 1), "list[int]")
    }
    
    func testClassPropertyAccess() throws {
        let checker = try analyze("""
        class Person:
            name: str
        
        p = Person()
        person_name = p.name
        """)
        
        XCTAssertEqual(checker.getVariableType("person_name", at: 5), "str")
    }
    
    func testClassMethodCall() throws {
        let checker = try analyze("""
        class Person:
            def get_name(self) -> str:
                return "John"
        
        p = Person()
        name = p.get_name()
        """)
        
        XCTAssertEqual(checker.getVariableType("name", at: 6), "str")
    }
    
    func testMethodChaining() throws {
        let checker = try analyze("""
        text = "  Hello  "
        result = text.strip().lower()
        """)
        
        XCTAssertEqual(checker.getVariableType("result", at: 2), "str")
    }
    
    func testStringLiteralMethod() throws {
        let checker = try analyze("""
        upper = "hello".upper()
        """)
        
        XCTAssertEqual(checker.getVariableType("upper", at: 1), "str")
    }
}
