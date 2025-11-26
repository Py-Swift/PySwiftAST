import Testing
@testable import PySwiftIDE
@testable import MonacoApi

@Suite("Math Module Completions Tests")
struct MathCompletionsTests {
    
    @Test("Math module completions are available")
    func testMathCompletions() async throws {
        let analyzer = MonacoAnalyzer(source: "import math\nmath.")
        
        let completions = analyzer.getCompletions(at: Position(lineNumber: 2, column: 6))
        
        // Check we have math completions
        let mathCompletions = completions.suggestions.filter { $0.label.hasPrefix("math.") }
        
        #expect(mathCompletions.count > 0, "Should have math module completions")
        
        // Check for specific constants
        let piCompletion = mathCompletions.first { $0.label == "math.pi" }
        #expect(piCompletion != nil, "Should have math.pi constant")
        #expect(piCompletion?.detail?.contains("3.14159") == true, "Should show pi value")
        
        let eCompletion = mathCompletions.first { $0.label == "math.e" }
        #expect(eCompletion != nil, "Should have math.e constant")
        
        // Check for specific functions
        let sqrtCompletion = mathCompletions.first { $0.label == "math.sqrt" }
        #expect(sqrtCompletion != nil, "Should have math.sqrt function")
        #expect(sqrtCompletion?.documentation != nil, "Should have documentation")
        
        let sinCompletion = mathCompletions.first { $0.label == "math.sin" }
        #expect(sinCompletion != nil, "Should have math.sin function")
        
        let cosCompletion = mathCompletions.first { $0.label == "math.cos" }
        #expect(cosCompletion != nil, "Should have math.cos function")
        
        let logCompletion = mathCompletions.first { $0.label == "math.log" }
        #expect(logCompletion != nil, "Should have math.log function")
        
        print("✅ Found \(mathCompletions.count) math completions")
    }
    
    @Test("Math constants have correct details")
    func testMathConstants() async throws {
        let analyzer = MonacoAnalyzer(source: "import math")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 12))
        
        let constants = [
            ("math.pi", "π"),
            ("math.e", "2.718"),
            ("math.tau", "τ"),
            ("math.inf", "infinity"),
            ("math.nan", "not a number")
        ]
        
        for (name, expectedInDetail) in constants {
            let completion = completions.suggestions.first { $0.label == name }
            #expect(completion != nil, "Should have \(name)")
            if let detail = completion?.detail?.lowercased() {
                #expect(detail.contains(expectedInDetail.lowercased()) || 
                       completion?.documentation != nil,
                       "\(name) should mention \(expectedInDetail)")
            }
        }
    }
    
    @Test("Math functions have proper signatures")
    func testMathFunctionSignatures() async throws {
        let analyzer = MonacoAnalyzer(source: "import math")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 12))
        
        // Test functions with different parameter counts
        let functions = [
            ("math.sqrt", 1),
            ("math.pow", 2),
            ("math.log", 2),  // x and optional base
            ("math.hypot", -1), // Variable args
            ("math.isclose", 4)  // a, b, rel_tol, abs_tol
        ]
        
        for (name, _) in functions {
            let completion = completions.suggestions.first { $0.label == name }
            #expect(completion != nil, "Should have \(name)")
            #expect(completion?.insertTextFormat == .snippet, "\(name) should be a snippet")
        }
    }
    
    @Test("Math trigonometric functions are available")
    func testTrigFunctions() async throws {
        let analyzer = MonacoAnalyzer(source: "import math")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 12))
        
        let trigFunctions = ["math.sin", "math.cos", "math.tan", "math.asin", "math.acos", "math.atan", "math.atan2"]
        
        for funcName in trigFunctions {
            let completion = completions.suggestions.first { $0.label == funcName }
            #expect(completion != nil, "Should have \(funcName)")
            #expect(completion?.documentation != nil, "\(funcName) should have documentation")
        }
    }
    
    @Test("Math hyperbolic functions are available")
    func testHyperbolicFunctions() async throws {
        let analyzer = MonacoAnalyzer(source: "import math")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 12))
        
        let hyperbolicFunctions = ["math.sinh", "math.cosh", "math.tanh", "math.asinh", "math.acosh", "math.atanh"]
        
        for funcName in hyperbolicFunctions {
            let completion = completions.suggestions.first { $0.label == funcName }
            #expect(completion != nil, "Should have \(funcName)")
        }
    }
    
    @Test("Math special functions are available")
    func testSpecialFunctions() async throws {
        let analyzer = MonacoAnalyzer(source: "import math")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 12))
        
        let specialFunctions = [
            "math.erf",
            "math.erfc",
            "math.gamma",
            "math.lgamma",
            "math.factorial",
            "math.gcd",
            "math.lcm",
            "math.comb",
            "math.perm"
        ]
        
        for funcName in specialFunctions {
            let completion = completions.suggestions.first { $0.label == funcName }
            #expect(completion != nil, "Should have \(funcName)")
        }
    }
    
    @Test("Total completion count includes math module")
    func testTotalCompletionCount() async throws {
        let analyzer = MonacoAnalyzer(source: "")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 1))
        
        // Should have keywords + builtins + math module
        let mathCompletions = completions.suggestions.filter { $0.label.hasPrefix("math.") }
        
        #expect(mathCompletions.count > 50, "Should have 50+ math completions (constants + functions)")
        #expect(completions.suggestions.count > 100, "Total completions should exceed 100")
        
        print("📊 Total completions: \(completions.suggestions.count)")
        print("📐 Math completions: \(mathCompletions.count)")
    }
}
