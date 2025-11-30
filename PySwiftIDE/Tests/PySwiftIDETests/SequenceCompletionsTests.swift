import Testing
@testable import PySwiftIDE
@testable import MonacoApi

/// Tests for Python sequence operations, range type, and iterator protocol completions
@Suite("Sequence Completions Tests")
struct SequenceCompletionsTests {
    
    @Test("Range type has start, stop, step properties")
    func testRangeProperties() async throws {
        let analyzer = MonacoAnalyzer(source: "x = range(10)\n")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 0))
        
        // Check for range properties
        let rangeStart = completions.suggestions.first { $0.label == "range.start" }
        #expect(rangeStart != nil, "Should have range.start property")
        #expect(rangeStart?.kind == .variable, "range.start should be a variable/property")
        
        let rangeStop = completions.suggestions.first { $0.label == "range.stop" }
        #expect(rangeStop != nil, "Should have range.stop property")
        
        let rangeStep = completions.suggestions.first { $0.label == "range.step" }
        #expect(rangeStep != nil, "Should have range.step property")
    }
    
    @Test("Range type has count and index methods")
    func testRangeMethods() async throws {
        let analyzer = MonacoAnalyzer(source: "x = range(10)\n")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 0))
        
        let rangeCount = completions.suggestions.first { $0.label == "range.count" }
        #expect(rangeCount != nil, "Should have range.count method")
        #expect(rangeCount?.kind == .function, "range.count should be a function")
        
        let rangeIndex = completions.suggestions.first { $0.label == "range.index" }
        #expect(rangeIndex != nil, "Should have range.index method")
        #expect(rangeIndex?.kind == .function, "range.index should be a function")
    }
    
    @Test("Common sequence operations are available")
    func testSequenceOperations() async throws {
        let analyzer = MonacoAnalyzer(source: "nums = [1, 2, 3]\n")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 0))
        
        let sequenceOps = ["len", "min", "max", "sum", "any", "all", 
                          "sorted", "reversed", "enumerate", "zip", 
                          "filter", "map", "slice"]
        
        for op in sequenceOps {
            let completion = completions.suggestions.first { $0.label == op }
            #expect(completion != nil, "Should have \(op) operation")
            #expect(completion?.kind == .function, "\(op) should be a function")
            #expect(completion?.documentation != nil, "\(op) should have documentation")
        }
    }
    
    @Test("Iterator protocol methods are available")
    func testIteratorProtocol() async throws {
        let analyzer = MonacoAnalyzer(source: "class MyIter:\n    pass\n")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 2, column: 0))
        
        let iteratorMethods = ["__iter__", "__next__", "__reversed__", "__length_hint__"]
        
        for method in iteratorMethods {
            let completion = completions.suggestions.first { $0.label == method }
            #expect(completion != nil, "Should have \(method) protocol method")
            #expect(completion?.kind == .function, "\(method) should be a function")
        }
    }
    
    @Test("Iterator utility functions are available")
    func testIteratorUtils() async throws {
        let analyzer = MonacoAnalyzer(source: "x = [1, 2, 3]\n")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 0))
        
        let utils = ["iter", "next", "range"]
        
        for util in utils {
            let completion = completions.suggestions.first { $0.label == util }
            #expect(completion != nil, "Should have \(util) utility function")
            #expect(completion?.kind == .function, "\(util) should be a function")
        }
    }
    
    @Test("len function has proper signature")
    func testLenSignature() async throws {
        let analyzer = MonacoAnalyzer(source: "x = []\n")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 0))
        
        let lenFunc = completions.suggestions.first { $0.label == "len" }
        #expect(lenFunc != nil, "Should have len function")
        #expect(lenFunc?.insertText.contains("len(") == true, "len should have proper call syntax")
    }
    
    @Test("enumerate function has proper signature")
    func testEnumerateSignature() async throws {
        let analyzer = MonacoAnalyzer(source: "x = []\n")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 0))
        
        let enumFunc = completions.suggestions.first { $0.label == "enumerate" }
        #expect(enumFunc != nil, "Should have enumerate function")
        #expect(enumFunc?.insertText.contains("enumerate(") == true, "enumerate should have proper call syntax")
    }
    
    @Test("zip function has proper signature")
    func testZipSignature() async throws {
        let analyzer = MonacoAnalyzer(source: "x = []\n")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 0))
        
        let zipFunc = completions.suggestions.first { $0.label == "zip" }
        #expect(zipFunc != nil, "Should have zip function")
        #expect(zipFunc?.insertText.contains("zip(") == true, "zip should have proper call syntax")
    }
    
    @Test("Total completions include sequence operations")
    func testTotalCompletionCount() async throws {
        let analyzer = MonacoAnalyzer(source: "x = 1\n")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 0))
        
        // Count sequence-related completions
        let rangeCompletions = completions.suggestions.filter { $0.label.hasPrefix("range.") }.count
        let iteratorMethods = completions.suggestions.filter { $0.label.hasPrefix("__") && 
                                                   ($0.label.contains("iter") || 
                                                    $0.label.contains("next") || 
                                                    $0.label.contains("reversed") ||
                                                    $0.label.contains("length_hint")) }.count
        
        // Should have at least:
        // - 5 range items (start, stop, step, count, index)
        // - 4 iterator protocol methods (__iter__, __next__, __reversed__, __length_hint__)
        // - 13 sequence operations (len, min, max, sum, any, all, sorted, reversed, enumerate, zip, filter, map, slice)
        // - 3 iterator utils (iter, next, range)
        
        #expect(rangeCompletions >= 5, "Should have at least 5 range completions, got \(rangeCompletions)")
        #expect(iteratorMethods >= 4, "Should have at least 4 iterator protocol methods, got \(iteratorMethods)")
        
        // Total should include keywords, builtins, math, sequence operations, and iterator protocol
        // (Type method completions removed - they require type inference to be context-aware)
        #expect(completions.suggestions.count > 180, "Total completions should exceed 180, got \(completions.suggestions.count)")
        
        print("Sequence completions breakdown:")
        print("  Range items: \(rangeCompletions)")
        print("  Iterator protocol: \(iteratorMethods)")
        print("  Total completions: \(completions.suggestions.count)")
    }
}
