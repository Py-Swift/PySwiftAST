import XCTest
@testable import PySwiftAST
@testable import PyChecking

/// Tests to ensure Parser and TypeChecker handle constant naming conventions
final class ConstantNamingTests: XCTestCase {
    
    func analyze(_ code: String) throws -> TypeChecker {
        let module = try parsePython(code)
        let checker = TypeChecker()
        _ = checker.analyze(module)
        return checker
    }
    
    func testUppercaseConstant() throws {
        let checker = try analyze("""
        ABC = 1
        """)
        
        // Parser should handle uppercase names
        XCTAssertEqual(checker.getVariableType("ABC"), "int")
    }
    
    func testLowercaseVariable() throws {
        let checker = try analyze("""
        abc = 1
        """)
        
        // Parser should handle lowercase names
        XCTAssertEqual(checker.getVariableType("abc"), "int")
    }
    
    func testMixedCase() throws {
        let checker = try analyze("""
        ABC = 1
        abc = 2
        Abc = 3
        aBc = 4
        """)
        
        // All naming styles should be tracked independently
        XCTAssertEqual(checker.getVariableType("ABC"), "int")
        XCTAssertEqual(checker.getVariableType("abc"), "int")
        XCTAssertEqual(checker.getVariableType("Abc"), "int")
        XCTAssertEqual(checker.getVariableType("aBc"), "int")
    }
    
    func testConstantWithTypeAnnotation() throws {
        let checker = try analyze("""
        MAX_SIZE: int = 100
        min_size: int = 10
        """)
        
        XCTAssertEqual(checker.getVariableType("MAX_SIZE"), "int")
        XCTAssertEqual(checker.getVariableType("min_size"), "int")
    }
    
    func testConstantInClass() throws {
        let checker = try analyze("""
        class Config:
            MAX_RETRIES: int = 3
            default_timeout: int = 30
        """)
        
        // Class-level constants should be accessible
        XCTAssertEqual(checker.getPropertyType(className: "Config", propertyName: "MAX_RETRIES"), "int")
        XCTAssertEqual(checker.getPropertyType(className: "Config", propertyName: "default_timeout"), "int")
    }
    
    func testConstantReassignment() throws {
        let checker = try analyze("""
        PI = 3.14
        PI = 3.14159
        """)
        
        // Even "constants" can be reassigned in Python (though discouraged)
        // TypeChecker should track the most recent value
        XCTAssertEqual(checker.getVariableType("PI", at: 2), "float")
    }
}
