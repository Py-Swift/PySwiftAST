import XCTest
@testable import PySwiftAST

final class TokenizerTests: XCTestCase {
    
    // MARK: - Basic Tokenization Tests
    
    func testSimpleTokenization() throws {
        let source = "x = 42"
        let tokenizer = Tokenizer(source: source)
        let tokens = try tokenizer.tokenize()
        
        XCTAssertEqual(tokens.count, 4)
        XCTAssertEqual(tokens[0].type, .name("x"))
        XCTAssertEqual(tokens[1].type, .equal)
        XCTAssertEqual(tokens[2].type, .number("42"))
        XCTAssertEqual(tokens[3].type, .endmarker)
    }
    
    func testKeywords() throws {
        let source = "def foo(): pass"
        let tokenizer = Tokenizer(source: source)
        let tokens = try tokenizer.tokenize()
        
        XCTAssertEqual(tokens[0].type, .def)
        XCTAssertEqual(tokens[1].type, .name("foo"))
        XCTAssertEqual(tokens[2].type, .leftparen)
        XCTAssertEqual(tokens[3].type, .rightparen)
        XCTAssertEqual(tokens[4].type, .colon)
        XCTAssertEqual(tokens[5].type, .pass)
    }
    
    func testOperators() throws {
        let source = "a + b - c * d / e // f ** g"
        let tokenizer = Tokenizer(source: source)
        let tokens = try tokenizer.tokenize()
        
        let expectedOps: [TokenType] = [.plus, .minus, .star, .slash, .doubleslash, .doublestar]
        var opIndex = 0
        
        for token in tokens {
            switch token.type {
            case .plus, .minus, .star, .slash, .doubleslash, .doublestar:
                XCTAssertEqual(token.type, expectedOps[opIndex])
                opIndex += 1
            default:
                continue
            }
        }
        
        XCTAssertEqual(opIndex, expectedOps.count)
    }
    
    func testIndentation() throws {
        let source = """
        def foo():
            x = 1
            y = 2
        """
        
        let tokenizer = Tokenizer(source: source)
        let tokens = try tokenizer.tokenize()
        
        // Find INDENT and DEDENT tokens
        var indentCount = 0
        var dedentCount = 0
        
        for token in tokens {
            if token.type == .indent {
                indentCount += 1
            } else if token.type == .dedent {
                dedentCount += 1
            }
        }
        
        XCTAssertEqual(indentCount, 1)
        XCTAssertEqual(dedentCount, 1)
    }
    
    func testStrings() throws {
        let source = #"""
        x = "hello"
        y = 'world'
        z = """triple"""
        """#
        
        let tokenizer = Tokenizer(source: source)
        let tokens = try tokenizer.tokenize()
        
        var stringCount = 0
        for token in tokens {
            if case .string = token.type {
                stringCount += 1
            }
        }
        
        XCTAssertEqual(stringCount, 3)
    }
    
    func testComments() throws {
        let source = """
        x = 1  # comment
        # another comment
        y = 2
        """
        
        let tokenizer = Tokenizer(source: source)
        let tokens = try tokenizer.tokenize()
        
        var commentCount = 0
        for token in tokens {
            if case .comment = token.type {
                commentCount += 1
            }
        }
        
        XCTAssertEqual(commentCount, 2)
    }
    
    // MARK: - Compatibility Tests
    
    func testCompatibilityWithComplexCode() throws {
        let source = """
        def fibonacci(n: int) -> int:
            '''Calculate the nth Fibonacci number'''
            if n <= 1:
                return n
            else:
                return fibonacci(n-1) + fibonacci(n-2)
        
        class Calculator:
            def __init__(self, x: float = 0.0):
                self.value: float = x
            
            def add(self, x: float) -> float:
                self.value += x
                return self.value
        
        # List comprehension
        squares = [x**2 for x in range(10) if x % 2 == 0]
        
        # Dictionary
        data = {
            'name': 'test',
            'values': [1, 2, 3],
            'nested': {'key': 'value'}
        }
        """
        
        let tokenizer = Tokenizer(source: source)
        let tokens = try tokenizer.tokenize()
        
        // Verify it tokenizes successfully
        XCTAssertGreaterThan(tokens.count, 50)
    }
    
    // MARK: - Performance Tests
    
    func testTokenizationPerformance() throws {
        // Load a large real-world Python file
        let testFile = "tests/ml_pipeline.py"
        let source = try String(contentsOfFile: testFile)
        
        // Warm up
        _ = try Tokenizer(source: source).tokenize()
        
        // Measure
        var times: [Double] = []
        for _ in 0..<100 {
            let start = DispatchTime.now()
            _ = try Tokenizer(source: source).tokenize()
            let end = DispatchTime.now()
            
            let elapsed = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000.0
            times.append(elapsed)
        }
        
        times.sort()
        let median = times[times.count / 2]
        
        print("Tokenizer median time: \(String(format: "%.3f", median))ms")
        
        // Should be significantly fast (target: < 10ms)
        XCTAssertLessThan(median, 15.0, "Tokenizer should be fast")
    }
}
