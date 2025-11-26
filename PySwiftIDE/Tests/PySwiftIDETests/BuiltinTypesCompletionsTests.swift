import Testing
@testable import PySwiftIDE
@testable import MonacoApi

@Suite("Built-in Types Completions Tests")
struct BuiltinTypesCompletionsTests {
    
    @Test("String methods are available")
    func testStringMethods() async throws {
        let analyzer = MonacoAnalyzer(source: "s = 'hello'\ns.")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 2, column: 3))
        
        let strMethods = completions.suggestions.filter { $0.label.hasPrefix("str.") }
        #expect(strMethods.count > 0, "Should have string method completions")
        
        // Check for specific string methods
        let expectedMethods = ["str.upper", "str.lower", "str.split", "str.strip", "str.replace", 
                               "str.find", "str.startswith", "str.endswith", "str.join"]
        
        for method in expectedMethods {
            let completion = strMethods.first { $0.label == method }
            #expect(completion != nil, "Should have \(method)")
            #expect(completion?.documentation != nil, "\(method) should have documentation")
        }
        
        print("✅ Found \(strMethods.count) string methods")
    }
    
    @Test("List methods are available")
    func testListMethods() async throws {
        let analyzer = MonacoAnalyzer(source: "lst = [1, 2, 3]")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 15))
        
        let listMethods = completions.suggestions.filter { $0.label.hasPrefix("list.") }
        #expect(listMethods.count > 0, "Should have list method completions")
        
        let expectedMethods = ["list.append", "list.extend", "list.insert", "list.remove", 
                               "list.pop", "list.clear", "list.sort", "list.reverse", "list.copy"]
        
        for method in expectedMethods {
            let completion = listMethods.first { $0.label == method }
            #expect(completion != nil, "Should have \(method)")
        }
        
        print("✅ Found \(listMethods.count) list methods")
    }
    
    @Test("Dict methods are available")
    func testDictMethods() async throws {
        let analyzer = MonacoAnalyzer(source: "d = {'a': 1}")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 13))
        
        let dictMethods = completions.suggestions.filter { $0.label.hasPrefix("dict.") }
        #expect(dictMethods.count > 0, "Should have dict method completions")
        
        let expectedMethods = ["dict.keys", "dict.values", "dict.items", "dict.get", 
                               "dict.pop", "dict.update", "dict.clear", "dict.copy"]
        
        for method in expectedMethods {
            let completion = dictMethods.first { $0.label == method }
            #expect(completion != nil, "Should have \(method)")
        }
        
        print("✅ Found \(dictMethods.count) dict methods")
    }
    
    @Test("Set methods are available")
    func testSetMethods() async throws {
        let analyzer = MonacoAnalyzer(source: "s = {1, 2, 3}")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 14))
        
        let setMethods = completions.suggestions.filter { $0.label.hasPrefix("set.") }
        #expect(setMethods.count > 0, "Should have set method completions")
        
        let expectedMethods = ["set.add", "set.remove", "set.discard", "set.union", 
                               "set.intersection", "set.difference", "set.symmetric_difference"]
        
        for method in expectedMethods {
            let completion = setMethods.first { $0.label == method }
            #expect(completion != nil, "Should have \(method)")
        }
        
        print("✅ Found \(setMethods.count) set methods")
    }
    
    @Test("Tuple methods are available")
    func testTupleMethods() async throws {
        let analyzer = MonacoAnalyzer(source: "t = (1, 2, 3)")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 14))
        
        let tupleMethods = completions.suggestions.filter { $0.label.hasPrefix("tuple.") }
        #expect(tupleMethods.count == 2, "Tuples should have exactly 2 methods (count, index)")
        
        #expect(tupleMethods.contains { $0.label == "tuple.count" }, "Should have tuple.count")
        #expect(tupleMethods.contains { $0.label == "tuple.index" }, "Should have tuple.index")
    }
    
    @Test("Bytes and bytearray methods are available")
    func testBytesAndBytearrayMethods() async throws {
        let analyzer = MonacoAnalyzer(source: "b = b'hello'")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 13))
        
        let bytesMethods = completions.suggestions.filter { $0.label.hasPrefix("bytes.") }
        let bytearrayMethods = completions.suggestions.filter { $0.label.hasPrefix("bytearray.") }
        
        #expect(bytesMethods.count > 0, "Should have bytes methods")
        #expect(bytearrayMethods.count > bytesMethods.count, "Bytearray should have more methods than bytes")
        
        // Bytes should have decode, hex, etc.
        #expect(bytesMethods.contains { $0.label == "bytes.decode" }, "Should have bytes.decode")
        #expect(bytesMethods.contains { $0.label == "bytes.hex" }, "Should have bytes.hex")
        
        // Bytearray should have mutating methods
        #expect(bytearrayMethods.contains { $0.label == "bytearray.append" }, "Should have bytearray.append")
        #expect(bytearrayMethods.contains { $0.label == "bytearray.extend" }, "Should have bytearray.extend")
        
        print("✅ Found \(bytesMethods.count) bytes methods")
        print("✅ Found \(bytearrayMethods.count) bytearray methods")
    }
    
    @Test("Frozenset methods are available")
    func testFrozensetMethods() async throws {
        let analyzer = MonacoAnalyzer(source: "fs = frozenset([1, 2])")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 22))
        
        let frozensetMethods = completions.suggestions.filter { $0.label.hasPrefix("frozenset.") }
        #expect(frozensetMethods.count > 0, "Should have frozenset methods")
        
        // Frozenset should only have non-mutating methods
        let expectedMethods = ["frozenset.union", "frozenset.intersection", "frozenset.difference", 
                               "frozenset.symmetric_difference", "frozenset.issubset", "frozenset.issuperset"]
        
        for method in expectedMethods {
            let completion = frozensetMethods.first { $0.label == method }
            #expect(completion != nil, "Should have \(method)")
        }
        
        // Should NOT have mutating methods like add, remove
        #expect(!frozensetMethods.contains { $0.label == "frozenset.add" }, "Should not have frozenset.add")
        #expect(!frozensetMethods.contains { $0.label == "frozenset.remove" }, "Should not have frozenset.remove")
        
        print("✅ Found \(frozensetMethods.count) frozenset methods (immutable)")
    }
    
    @Test("String methods have proper signatures")
    func testStringMethodSignatures() async throws {
        let analyzer = MonacoAnalyzer(source: "")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 1))
        
        // Test methods with different parameter counts
        let strReplace = completions.suggestions.first { $0.label == "str.replace" }
        #expect(strReplace != nil, "Should have str.replace")
        #expect(strReplace?.insertTextFormat == .snippet, "Should be a snippet")
        
        let strSplit = completions.suggestions.first { $0.label == "str.split" }
        #expect(strSplit != nil, "Should have str.split")
        
        let strUpper = completions.suggestions.first { $0.label == "str.upper" }
        #expect(strUpper != nil, "Should have str.upper")
    }
    
    @Test("Total completion count includes all built-in types")
    func testTotalCompletionCount() async throws {
        let analyzer = MonacoAnalyzer(source: "")
        let completions = analyzer.getCompletions(at: Position(lineNumber: 1, column: 1))
        
        let strCount = completions.suggestions.filter { $0.label.hasPrefix("str.") }.count
        let listCount = completions.suggestions.filter { $0.label.hasPrefix("list.") }.count
        let dictCount = completions.suggestions.filter { $0.label.hasPrefix("dict.") }.count
        let setCount = completions.suggestions.filter { $0.label.hasPrefix("set.") }.count
        let tupleCount = completions.suggestions.filter { $0.label.hasPrefix("tuple.") }.count
        let bytesCount = completions.suggestions.filter { $0.label.hasPrefix("bytes.") }.count
        let bytearrayCount = completions.suggestions.filter { $0.label.hasPrefix("bytearray.") }.count
        let frozensetCount = completions.suggestions.filter { $0.label.hasPrefix("frozenset.") }.count
        
        let totalTypeCompletions = strCount + listCount + dictCount + setCount + tupleCount + 
                                   bytesCount + bytearrayCount + frozensetCount
        
        #expect(totalTypeCompletions > 120, "Should have 120+ built-in type method completions")
        #expect(completions.suggestions.count > 220, "Total completions should exceed 220")
        
        print("📊 Built-in Type Completions:")
        print("  str: \(strCount)")
        print("  list: \(listCount)")
        print("  dict: \(dictCount)")
        print("  set: \(setCount)")
        print("  tuple: \(tupleCount)")
        print("  bytes: \(bytesCount)")
        print("  bytearray: \(bytearrayCount)")
        print("  frozenset: \(frozensetCount)")
        print("  TOTAL: \(totalTypeCompletions)")
        print("📊 Grand Total Completions: \(completions.suggestions.count)")
    }
}
