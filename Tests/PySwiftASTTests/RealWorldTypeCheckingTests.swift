import XCTest
@testable import PyChecking
@testable import PySwiftAST

/// Tests TypeChecker against real Python files from the test resources
final class RealWorldTypeCheckingTests: XCTestCase {
    
    func analyze(_ pythonCode: String) throws -> TypeChecker {
        let module = try parsePython(pythonCode)
        let checker = TypeChecker()
        _ = checker.analyze(module)
        return checker
    }
    
    func analyzeFile(_ filename: String) throws -> TypeChecker {
        // Direct path to resources
        let resourcePath = "/Volumes/CodeSSD/GitHub/PySwiftAST/Tests/PySwiftASTTests/Resources/\(filename)"
        let code = try String(contentsOfFile: resourcePath, encoding: .utf8)
        return try analyze(code)
    }
    
    // MARK: - Type Annotations Tests
    
    func testTypeAnnotationsAnalysis() throws {
        let checker = try analyze("""
        def greet(name: str) -> str:
            return f"Hello, {name}!"
        
        def add(a: int, b: int) -> int:
            return a + b
        """)
        
        // We can test that the file parses and analyzes without errors
        XCTAssertFalse(checker.getDiagnostics().contains { $0.severity == .error })
    }
    
    // MARK: - String Method Tests
    
    func testStringMethods() throws {
        let checker = try analyze("""
        text = "hello world"
        upper = text.upper()
        lower = text.lower()
        title = text.title()
        stripped = text.strip()
        replaced = text.replace("world", "Swift")
        split_result = text.split()
        joined = " ".join(["a", "b", "c"])
        """)
        
        XCTAssertEqual(checker.getVariableType("text", at: 1), "str")
        XCTAssertEqual(checker.getVariableType("upper", at: 2), "str")
        XCTAssertEqual(checker.getVariableType("lower", at: 3), "str")
        XCTAssertEqual(checker.getVariableType("title", at: 4), "str")
        XCTAssertEqual(checker.getVariableType("stripped", at: 5), "str")
        XCTAssertEqual(checker.getVariableType("replaced", at: 6), "str")
        XCTAssertEqual(checker.getVariableType("split_result", at: 7), "list[str]")
        XCTAssertEqual(checker.getVariableType("joined", at: 8), "str")
    }
    
    // MARK: - List Method Tests
    
    func testListMethods() throws {
        let checker = try analyze("""
        numbers = [1, 2, 3]
        numbers.append(4)
        numbers.extend([5, 6])
        popped = numbers.pop()
        reversed_list = numbers.reverse()
        sorted_list = numbers.sort()
        """)
        
        XCTAssertEqual(checker.getVariableType("numbers", at: 1), "list[int]")
        XCTAssertEqual(checker.getVariableType("popped", at: 4), "int")
        // reverse() and sort() return None (modify in place)
        XCTAssertEqual(checker.getVariableType("reversed_list", at: 5), "None")
        XCTAssertEqual(checker.getVariableType("sorted_list", at: 6), "None")
    }
    
    // MARK: - Dict Method Tests
    
    func testDictMethods() throws {
        let checker = try analyze("""
        data = {"name": "Alice", "city": "NYC"}
        keys_result = data.keys()
        values_result = data.values()
        items_result = data.items()
        name = data.get("name")
        popped = data.pop("city")
        """)
        
        XCTAssertEqual(checker.getVariableType("data", at: 1), "dict[str, str]")
        // dict views return list-based types for IDE compatibility
        XCTAssertEqual(checker.getVariableType("keys_result", at: 2), "list[str]")
        XCTAssertEqual(checker.getVariableType("values_result", at: 3), "list[str]")
        XCTAssertEqual(checker.getVariableType("items_result", at: 4), "list[tuple[str, str]]")
        // get() and pop() return the value type (str in this case)
        XCTAssertEqual(checker.getVariableType("name", at: 5), "str")
        XCTAssertEqual(checker.getVariableType("popped", at: 6), "str")
    }
    
    // MARK: - Set Method Tests
    
    func testSetMethods() throws {
        let checker = try analyze("""
        numbers = {1, 2, 3}
        numbers.add(4)
        numbers.remove(1)
        popped = numbers.pop()
        other = {3, 4, 5}
        union_result = numbers.union(other)
        intersection_result = numbers.intersection(other)
        difference_result = numbers.difference(other)
        """)
        
        XCTAssertEqual(checker.getVariableType("numbers", at: 1), "set[int]")
        XCTAssertEqual(checker.getVariableType("popped", at: 4), "int")
        XCTAssertEqual(checker.getVariableType("union_result", at: 6), "set[int]")
        XCTAssertEqual(checker.getVariableType("intersection_result", at: 7), "set[int]")
        XCTAssertEqual(checker.getVariableType("difference_result", at: 8), "set[int]")
    }
    
    // MARK: - Method Chaining Tests
    
    func testMethodChaining() throws {
        let checker = try analyze("""
        text = "  HELLO WORLD  "
        result = text.strip().lower().replace("world", "swift")
        
        numbers = [3, 1, 4, 1, 5, 9, 2, 6]
        numbers.sort()
        
        data = {"a": 1, "b": 2}
        keys = list(data.keys())
        """)
        
        XCTAssertEqual(checker.getVariableType("result", at: 2), "str")
        // list() constructor with dict.keys() - we can't infer the element type perfectly yet
        // Since dict.keys() returns Unknown, list(Unknown) returns list[Any]
        XCTAssertEqual(checker.getVariableType("keys", at: 8), "list[Any]")
    }
    
    // MARK: - Class Instance Method Tests
    
    func testClassInstanceMethods() throws {
        let checker = try analyze("""
        class Calculator:
            def add(self, a: int, b: int) -> int:
                return a + b
            
            def get_result(self) -> str:
                return "Result"
        
        calc = Calculator()
        sum_result = calc.add(5, 3)
        message = calc.get_result()
        """)
        
        XCTAssertEqual(checker.getVariableType("calc", at: 8), "Calculator")
        XCTAssertEqual(checker.getVariableType("sum_result", at: 9), "int")
        XCTAssertEqual(checker.getVariableType("message", at: 10), "str")
    }
    
    // MARK: - Constant Detection Tests
    
    func testConstantDetection() throws {
        let checker = try analyze("""
        MAX_SIZE = 100
        API_KEY = "secret"
        DEBUG_MODE = True
        
        current_value = 42
        user_name = "Alice"
        """)
        
        // Check constants are detected
        XCTAssertTrue(checker.isConstant("MAX_SIZE"))
        XCTAssertTrue(checker.isConstant("API_KEY"))
        XCTAssertTrue(checker.isConstant("DEBUG_MODE"))
        
        // Check variables are not constants
        XCTAssertFalse(checker.isConstant("current_value"))
        XCTAssertFalse(checker.isConstant("user_name"))
    }
    
    // MARK: - Constant Reassignment Warning Tests
    
    func testConstantReassignmentWarning() throws {
        let checker = try analyze("""
        MAX_SIZE = 100
        MAX_SIZE = 200
        """)
        
        let diagnostics = checker.getDiagnostics()
        let warnings = diagnostics.filter { $0.severity == .warning }
        
        XCTAssertTrue(warnings.contains { $0.message.contains("MAX_SIZE") && $0.message.contains("reassigned") })
    }
    
    // MARK: - Scope Tests
    
    func testFunctionScope() throws {
        let checker = try analyze("""
        global_var = "global"
        
        def my_function():
            local_var = "local"
            result = global_var.upper()
            return result
        """)
        
        // Global variable accessible at global scope
        XCTAssertEqual(checker.getVariableType("global_var", at: 1), "str")
        
        // Local variable accessible within function
        XCTAssertEqual(checker.getVariableType("local_var", at: 4), "str")
        XCTAssertEqual(checker.getVariableType("result", at: 5), "str")
    }
    
    // MARK: - Complex Type Tests
    
    func testNestedStructures() throws {
        let checker = try analyze("""
        matrix = [[1, 2], [3, 4]]
        nested_dict = {"outer": {"inner": 42}}
        tuple_list = [(1, "a"), (2, "b")]
        """)
        
        XCTAssertEqual(checker.getVariableType("matrix", at: 1), "list[list[int]]")
        XCTAssertEqual(checker.getVariableType("nested_dict", at: 2), "dict[str, dict[str, int]]")
        XCTAssertEqual(checker.getVariableType("tuple_list", at: 3), "list[tuple[int, str]]")
    }
    
    // MARK: - Comprehension Tests
    
    func testListComprehensions() throws {
        let checker = try analyze("""
        squares = [x**2 for x in range(10)]
        evens = [x for x in range(20) if x % 2 == 0]
        matrix = [[i * j for j in range(3)] for i in range(3)]
        """)
        
        // Comprehensions now properly infer element types
        XCTAssertEqual(checker.getVariableType("squares", at: 1), "list[int]")
        XCTAssertEqual(checker.getVariableType("evens", at: 2), "list[int]")
        XCTAssertEqual(checker.getVariableType("matrix", at: 3), "list[list[int]]")
    }
    
    func testSetComprehensions() throws {
        let checker = try analyze("""
        unique_squares = {x**2 for x in range(-5, 6)}
        """)
        
        XCTAssertEqual(checker.getVariableType("unique_squares", at: 1), "set[int]")
    }
    
    func testDictComprehensions() throws {
        let checker = try analyze("""
        square_dict = {x: x**2 for x in range(5)}
        """)
        
        XCTAssertEqual(checker.getVariableType("square_dict", at: 1), "dict[int, int]")
    }
    
    func testComprehensionsWithStrings() throws {
        let checker = try analyze("""
        words = ["hello", "world"]
        upper_words = [w.upper() for w in words]
        lengths = [len(w) for w in words]
        """)
        
        XCTAssertEqual(checker.getVariableType("upper_words", at: 2), "list[str]")
        XCTAssertEqual(checker.getVariableType("lengths", at: 3), "list[int]")  // len() returns int
    }
    
    func testNestedComprehensions() throws {
        let checker = try analyze("""
        matrix = [[i * j for j in range(3)] for i in range(3)]
        """)
        
        XCTAssertEqual(checker.getVariableType("matrix", at: 1), "list[list[int]]")
    }
    
    // MARK: - Type Inference Through Operations
    
    func testBinaryOperationTypes() throws {
        let checker = try analyze("""
        a = 5
        b = 3
        sum_result = a + b
        product = a * b
        division = a / b
        
        text1 = "Hello"
        text2 = "World"
        concat = text1 + text2
        """)
        
        XCTAssertEqual(checker.getVariableType("sum_result", at: 3), "int")
        XCTAssertEqual(checker.getVariableType("product", at: 4), "int")
        XCTAssertEqual(checker.getVariableType("division", at: 5), "float")
        XCTAssertEqual(checker.getVariableType("concat", at: 9), "str")
    }
    
    // MARK: - Built-in Function Tests
    
    func testBuiltinFunctions() throws {
        let checker = try analyze("""
        numbers = [1, 2, 3, 4, 5]
        length = len(numbers)
        
        text = "hello"
        text_len = len(text)
        """)
        
        // Built-in functions like len, max, min, sum are now tracked by TypeChecker
        XCTAssertEqual(checker.getVariableType("length", at: 2), "int")
        XCTAssertEqual(checker.getVariableType("text_len", at: 5), "int")
    }
    
    // MARK: - Class Property Assignment
    
    func testClassPropertyAssignment() throws {
        let checker = try analyze("""
        class Person:
            name: str
            age: int
        
        p = Person()
        person_name = p.name
        person_age = p.age
        """)
        
        XCTAssertEqual(checker.getVariableType("p", at: 5), "Person")
        // Properties with type annotations in class body
        XCTAssertEqual(checker.getVariableType("person_name", at: 6), "str")
        XCTAssertEqual(checker.getVariableType("person_age", at: 7), "int")
    }
    
    // MARK: - Comprehensive Integration Test
    
    func testRealWorldScenario() throws {
        let checker = try analyze("""
        API_URL = "https://api.example.com"
        MAX_RETRIES = 3
        data = {"users": ["Alice", "Bob"], "count": 2}
        users = data.get("users")
        message = "hello world"
        upper_message = message.upper()
        words = message.split()
        numbers = [1, 2, 3, 4, 5]
        numbers.append(6)
        first = numbers.pop()
        tags = {"python", "swift", "rust"}
        tags.add("go")
        more_tags = {"java", "kotlin"}
        all_tags = tags.union(more_tags)
        
        class DataProcessor:
            def process(self, data: str) -> int:
                return len(data)
        
        processor = DataProcessor()
        result = processor.process("test")
        a = 10
        b = 20
        total = a + b
        ratio = a / b
        """)
        
        // Constants
        XCTAssertTrue(checker.isConstant("API_URL"))
        XCTAssertTrue(checker.isConstant("MAX_RETRIES"))
        
        // Dict and method calls
        XCTAssertEqual(checker.getVariableType("data", at: 5), "dict[str, list[str]]")
        XCTAssertEqual(checker.getVariableType("users", at: 6), "list[str]")
        
        // String operations
        XCTAssertEqual(checker.getVariableType("message", at: 7), "str")
        XCTAssertEqual(checker.getVariableType("upper_message", at: 8), "str")
        XCTAssertEqual(checker.getVariableType("words", at: 9), "list[str]")
        
        // List operations
        XCTAssertEqual(checker.getVariableType("numbers", at: 10), "list[int]")
        XCTAssertEqual(checker.getVariableType("first", at: 12), "int")
        
        // Set operations
        XCTAssertEqual(checker.getVariableType("tags", at: 13), "set[str]")
        XCTAssertEqual(checker.getVariableType("all_tags", at: 16), "set[str]")
        
        // Class instantiation and method calls
        XCTAssertEqual(checker.getVariableType("processor", at: 22), "DataProcessor")
        XCTAssertEqual(checker.getVariableType("result", at: 23), "int")
        
        // Binary operations
        XCTAssertEqual(checker.getVariableType("total", at: 26), "int")
        XCTAssertEqual(checker.getVariableType("ratio", at: 27), "float")
    }
    
    // MARK: - Advanced Built-in Functions and Dict Views
    
    func testAdvancedBuiltinsAndDictViews() throws {
        let checker = try analyze("""
        # Built-in functions with type inference
        numbers = [1, 2, 3, 4, 5]
        total = sum(numbers)
        maximum = max(numbers)
        minimum = min(numbers)
        length = len(numbers)
        absolute = abs(-42)
        rounded = round(3.14)
        
        # Collection transformers
        sorted_nums = sorted(numbers)
        reversed_nums = reversed(numbers)
        
        # Iterator transformers
        enumerated = enumerate(numbers)
        zipped = zip(numbers, numbers)
        
        # Dict view types
        data = {"name": "Alice", "age": "30"}
        keys = data.keys()
        values = data.values()
        items = data.items()
        
        # self.property assignments in __init__
        class Person:
            def __init__(self, name: str, age: int):
                self.name = name
                self.age = age
                self.greeting = "Hello, " + name
        
        person = Person("Bob", 25)
        person_name = person.name
        person_age = person.age
        person_greeting = person.greeting
        """)
        
        // Built-in functions return correct types
        XCTAssertEqual(checker.getVariableType("total", at: 3), "int")
        XCTAssertEqual(checker.getVariableType("maximum", at: 4), "int")
        XCTAssertEqual(checker.getVariableType("minimum", at: 5), "int")
        XCTAssertEqual(checker.getVariableType("length", at: 6), "int")
        XCTAssertEqual(checker.getVariableType("absolute", at: 7), "int")
        XCTAssertEqual(checker.getVariableType("rounded", at: 8), "int")
        
        // Collection transformers preserve element types
        XCTAssertEqual(checker.getVariableType("sorted_nums", at: 11), "list[int]")
        XCTAssertEqual(checker.getVariableType("reversed_nums", at: 12), "list[int]")
        
        // Iterator transformers return correct types
        XCTAssertEqual(checker.getVariableType("enumerated", at: 15), "list[tuple[int, int]]")
        XCTAssertEqual(checker.getVariableType("zipped", at: 16), "list[tuple[int, int]]")
        
        // Dict views return list-based types
        XCTAssertEqual(checker.getVariableType("keys", at: 20), "list[str]")
        XCTAssertEqual(checker.getVariableType("values", at: 21), "list[str]")
        XCTAssertEqual(checker.getVariableType("items", at: 22), "list[tuple[str, str]]")
        
        // self.property assignments tracked in __init__
        XCTAssertEqual(checker.getVariableType("person_name", at: 32), "str")
        XCTAssertEqual(checker.getVariableType("person_age", at: 33), "int")
        XCTAssertEqual(checker.getVariableType("person_greeting", at: 34), "str")
    }
    
    // MARK: - New Feature Tests
    
    func testBinaryOperationEdgeCases() throws {
        let checker = try analyze("""
        # String repetition
        repeated_str = "abc" * 3
        repeated_str2 = 5 * "x"
        
        # List repetition
        repeated_list = [1, 2] * 3
        repeated_list2 = 2 * [3, 4]
        
        # Floor division
        floor_div1 = 10 // 3
        floor_div2 = 10.5 // 2.0
        
        # Modulo
        mod1 = 10 % 3
        mod2 = "Hello %s" % ("world",)
        
        # Power
        pow1 = 2 ** 3
        pow2 = 2.0 ** 3
        
        # Bitwise operations
        bit1 = 5 << 2
        bit2 = 10 >> 1
        bit3 = 5 | 3
        bit4 = 5 & 3
        bit5 = 5 ^ 3
        """)
        
        XCTAssertEqual(checker.getVariableType("repeated_str", at: 2), "str")
        XCTAssertEqual(checker.getVariableType("repeated_str2", at: 3), "str")
        XCTAssertEqual(checker.getVariableType("repeated_list", at: 6), "list[int]")
        XCTAssertEqual(checker.getVariableType("repeated_list2", at: 7), "list[int]")
        XCTAssertEqual(checker.getVariableType("floor_div1", at: 10), "int")
        XCTAssertEqual(checker.getVariableType("floor_div2", at: 11), "float")
        XCTAssertEqual(checker.getVariableType("mod1", at: 14), "int")
        XCTAssertEqual(checker.getVariableType("mod2", at: 15), "str")
        XCTAssertEqual(checker.getVariableType("pow1", at: 18), "int")
        XCTAssertEqual(checker.getVariableType("pow2", at: 19), "float")
        XCTAssertEqual(checker.getVariableType("bit1", at: 22), "int")
        XCTAssertEqual(checker.getVariableType("bit2", at: 23), "int")
        XCTAssertEqual(checker.getVariableType("bit3", at: 24), "int")
        XCTAssertEqual(checker.getVariableType("bit4", at: 25), "int")
        XCTAssertEqual(checker.getVariableType("bit5", at: 26), "int")
    }
    
    func testMoreBuiltinFunctions() throws {
        let checker = try analyze("""
        # Boolean functions
        all_result = all([True, True, False])
        any_result = any([False, False, True])
        is_instance = isinstance(5, int)
        
        # I/O functions
        user_input = input()
        
        # Conversion functions
        ord_result = ord('A')
        chr_result = chr(65)
        
        # Numeric functions
        pow_result = pow(2, 3)
        divmod_result = divmod(10, 3)
        hash_result = hash("test")
        
        # String functions
        repr_result = repr(42)
        bin_result = bin(10)
        hex_result = hex(255)
        
        # Iterator functions
        nums = [1, 2, 3]
        iter_result = iter(nums)
        next_result = next(iter(nums))
        """)
        
        XCTAssertEqual(checker.getVariableType("all_result", at: 2), "bool")
        XCTAssertEqual(checker.getVariableType("any_result", at: 3), "bool")
        XCTAssertEqual(checker.getVariableType("is_instance", at: 4), "bool")
        XCTAssertEqual(checker.getVariableType("user_input", at: 7), "str")
        XCTAssertEqual(checker.getVariableType("ord_result", at: 10), "int")
        XCTAssertEqual(checker.getVariableType("chr_result", at: 11), "str")  // chr() returns str
        XCTAssertEqual(checker.getVariableType("pow_result", at: 14), "int")
        XCTAssertEqual(checker.getVariableType("divmod_result", at: 15), "tuple[int, int]")
        XCTAssertEqual(checker.getVariableType("hash_result", at: 16), "int")
        XCTAssertEqual(checker.getVariableType("repr_result", at: 19), "str")
        XCTAssertEqual(checker.getVariableType("bin_result", at: 20), "str")
        XCTAssertEqual(checker.getVariableType("hex_result", at: 21), "str")
        XCTAssertEqual(checker.getVariableType("iter_result", at: 25), "list[int]")
        XCTAssertEqual(checker.getVariableType("next_result", at: 26), "int")
    }
    
    func testLambdaTypeInference() throws {
        let checker = try analyze("""
        # Lambda with inferred return type
        add = lambda x, y: x + y
        square = lambda n: n * n
        to_string = lambda x: str(x)
        
        # Lambda results
        numbers = [1, 2, 3]
        doubled = map(lambda x: x * 2, numbers)
        """)
        
        // Lambda returns are inferred from body
        // Note: lambdas themselves are callable, here we're testing if we can track their return types
        // For now, we just verify the lambda variable exists
        XCTAssertNotNil(checker.getVariableType("add", at: 2))
        XCTAssertNotNil(checker.getVariableType("square", at: 3))
        XCTAssertNotNil(checker.getVariableType("to_string", at: 4))
    }
    
    func testTupleUnpacking() throws {
        let checker = try analyze("""
        # Basic tuple unpacking
        a, b = (1, "hello")
        
        # Unpacking from function/expression
        coords = (10, 20)
        x, y = coords
        
        # Starred unpacking
        first, *rest = [1, 2, 3, 4, 5]
        """)
        
        XCTAssertEqual(checker.getVariableType("a", at: 2), "int")
        XCTAssertEqual(checker.getVariableType("b", at: 2), "str")
        XCTAssertEqual(checker.getVariableType("x", at: 6), "int")
        XCTAssertEqual(checker.getVariableType("y", at: 6), "int")
        XCTAssertEqual(checker.getVariableType("first", at: 9), "int")
        XCTAssertEqual(checker.getVariableType("rest", at: 9), "list[int]")
    }
    
    func testFunctionReturnTypeTracking() throws {
        let checker = try analyze("""
        def add(a: int, b: int) -> int:
            return a + b
        
        def greet(name: str) -> str:
            return "Hello, " + name
        
        # Call user-defined functions
        result = add(5, 3)
        greeting = greet("Alice")
        """)
        
        XCTAssertEqual(checker.getVariableType("result", at: 8), "int")
        XCTAssertEqual(checker.getVariableType("greeting", at: 9), "str")
    }
    
    func testContextManagers() throws {
        let checker = try analyze("""
        # With statement
        with open("file.txt") as f:
            content = f
        
        # Note: We track the context manager variable type
        # In real implementation, this would be file type
        """)
        
        // Context manager variables are tracked
        XCTAssertNotNil(checker.getVariableType("f", at: 2))
        XCTAssertNotNil(checker.getVariableType("content", at: 3))
    }
    
    func testExceptionHandling() throws {
        let checker = try analyze("""
        try:
            x = 10 / 0
        except ValueError as e:
            error = e
        except Exception as ex:
            other_error = ex
        """)
        
        // Exception variables are tracked with their types
        XCTAssertNotNil(checker.getVariableType("error", at: 4))
        XCTAssertNotNil(checker.getVariableType("other_error", at: 6))
    }
    
    func testSliceTypes() throws {
        let checker = try analyze("""
        # List slicing returns list
        numbers = [1, 2, 3, 4, 5]
        slice1 = numbers[1:3]
        element = numbers[0]
        
        # String slicing returns string
        text = "hello"
        substr = text[1:4]
        char = text[0]
        """)
        
        XCTAssertEqual(checker.getVariableType("slice1", at: 3), "list[int]")
        XCTAssertEqual(checker.getVariableType("element", at: 4), "int")
        XCTAssertEqual(checker.getVariableType("substr", at: 8), "str")
        XCTAssertEqual(checker.getVariableType("char", at: 9), "str")
    }
    
    func testGeneratorExpressions() throws {
        let checker = try analyze("""
        # Generator expressions infer element types
        numbers = [1, 2, 3, 4, 5]
        gen = (x**2 for x in numbers)
        
        strings = ["a", "b", "c"]
        upper_gen = (s.upper() for s in strings)
        """)
        
        XCTAssertEqual(checker.getVariableType("gen", at: 3), "list[int]")
        XCTAssertEqual(checker.getVariableType("upper_gen", at: 6), "list[str]")
    }
    
    func testEnhancedForLoops() throws {
        let checker = try analyze("""
        # Iterate over different types
        for x in [1, 2, 3]:
            num = x
        
        for s in {"a", "b", "c"}:
            string_from_set = s
        
        for c in "hello":
            char = c
        
        # Tuple unpacking in for loop
        data = {"name": "Alice", "age": "30"}
        for key, value in data.items():
            k = key
            v = value
        
        # Tuple unpacking from list of tuples
        pairs = [(1, "a"), (2, "b")]
        for num, letter in pairs:
            n = num
            l = letter
        """)
        
        XCTAssertEqual(checker.getVariableType("num", at: 3), "int")
        XCTAssertEqual(checker.getVariableType("string_from_set", at: 6), "str")
        XCTAssertEqual(checker.getVariableType("char", at: 9), "str")
        XCTAssertEqual(checker.getVariableType("k", at: 14), "str")
        XCTAssertEqual(checker.getVariableType("v", at: 15), "str")
        XCTAssertEqual(checker.getVariableType("n", at: 20), "int")
        XCTAssertEqual(checker.getVariableType("l", at: 21), "str")
    }
    
    func testAugmentedAssignments() throws {
        let checker = try analyze("""
        # Numeric augmented assignments
        x = 10
        x += 5
        
        y = 5.0
        y *= 2
        
        z = 3
        z /= 2
        
        # String concatenation
        s = "hello"
        s += " world"
        
        # List concatenation
        nums = [1, 2]
        nums += [3, 4]
        """)
        
        XCTAssertEqual(checker.getVariableType("x", at: 3), "int")
        XCTAssertEqual(checker.getVariableType("y", at: 6), "float")
        XCTAssertEqual(checker.getVariableType("z", at: 9), "float")  // Division always returns float
        XCTAssertEqual(checker.getVariableType("s", at: 13), "str")
        XCTAssertEqual(checker.getVariableType("nums", at: 17), "list[int]")
    }
    
    func testImportTracking() throws {
        let checker = try analyze("""
        import math
        import os as operating_system
        from datetime import datetime
        from collections import Counter as MyCounter
        
        # Imported names should be tracked
        pi = math
        sys_module = operating_system
        dt = datetime
        counter = MyCounter
        """)
        
        // Imported names are tracked (as Any since we don't have type stubs)
        XCTAssertNotNil(checker.getVariableType("math", at: 6))
        XCTAssertNotNil(checker.getVariableType("operating_system", at: 7))
        XCTAssertNotNil(checker.getVariableType("datetime", at: 8))
        XCTAssertNotNil(checker.getVariableType("MyCounter", at: 9))
    }
    
    func testTypeNarrowing() throws {
        let checker = try analyze("""
        # Basic import tracking and type narrowing demonstration
        x: int | str = 5
        
        if isinstance(x, int):
            # x is narrowed to int in this block
            pass
        
        # Note: Full type narrowing with variable assignments would require
        # more sophisticated scope tracking. This test demonstrates that
        # isinstance is recognized and type narrowing logic exists.
        """)
        
        // Verify the isinstance pattern is handled (test passes if no crash)
        XCTAssertNotNil(checker.getVariableType("x", at: 2))
    }
    
    func testEmptyDictDefaultType() throws {
        let checker = try analyze("""
        # Global cache
        price_cache = {}
        customer_cache = {}
        
        # With values
        config = {"debug": True}
        """)
        
        // Empty dicts default to dict[str, Any]
        XCTAssertEqual(checker.getVariableType("price_cache", at: 2), "dict[str, Any]")
        XCTAssertEqual(checker.getVariableType("customer_cache", at: 3), "dict[str, Any]")
        
        // Dict with values infers from first entry
        XCTAssertEqual(checker.getVariableType("config", at: 6), "dict[str, bool]")
    }
    
    // MARK: - Scope API Tests
    
    func testGetScopeAt_ClassDefinition() throws {
        let checker = try analyze("""
        class MyClass:
            pass
        """)
        
        let scope = checker.getScopeAt(line: 1, column: 0)
        XCTAssertNotNil(scope)
        XCTAssertEqual(scope?.kind, .classScope)
        XCTAssertEqual(scope?.name, "MyClass")
        XCTAssertEqual(scope?.startLine, 1)
    }
    
    func testGetScopeAt_InsideMethod() throws {
        let checker = try analyze("""
        class MyClass:
            def method(self):
                x = 1
        """)
        
        // Line 3 is inside the method, which is inside the class
        let scope = checker.getScopeAt(line: 3, column: 8)
        XCTAssertNotNil(scope)
        // Should return function scope (innermost)
        XCTAssertEqual(scope?.kind, .function)
        XCTAssertEqual(scope?.name, "method")
    }
    
    func testGetScopeAt_NestedClasses() throws {
        let checker = try analyze("""
        class Outer:
            class Inner:
                def method(self):
                    pass
        """)
        
        // Line 4 should be in the Inner class's method
        let scope = checker.getScopeAt(line: 4, column: 12)
        XCTAssertNotNil(scope)
        // Should return the function scope (innermost)
        XCTAssertEqual(scope?.kind, .function)
        XCTAssertEqual(scope?.name, "method")
    }
    
    func testGetScopeAt_ModuleLevel() throws {
        let checker = try analyze("""
        x = 1
        y = 2
        """)
        
        let scope = checker.getScopeAt(line: 1, column: 0)
        XCTAssertNotNil(scope)
        XCTAssertEqual(scope?.kind, .module)
    }
    
    func testGetScopeChainAt() throws {
        let checker = try analyze("""
        class MyClass:
            def method(self):
                x = 1
        """)
        
        // Line 3 is inside method inside class inside module
        let chain = checker.getScopeChainAt(line: 3, column: 8)
        
        // Should have 3 scopes: module, class, function
        XCTAssertEqual(chain.count, 3)
        
        // Outermost to innermost
        XCTAssertEqual(chain[0].kind, .module)
        XCTAssertEqual(chain[1].kind, .classScope)
        XCTAssertEqual(chain[1].name, "MyClass")
        XCTAssertEqual(chain[2].kind, .function)
        XCTAssertEqual(chain[2].name, "method")
    }
    
    func testIsInScope() throws {
        let checker = try analyze("""
        class MyClass:
            def method(self):
                x = 1
        
        y = 2
        """)
        
        // Line 3 is inside a class
        XCTAssertTrue(checker.isInScope(line: 3, column: 8, kind: .classScope))
        XCTAssertTrue(checker.isInScope(line: 3, column: 8, kind: .function))
        
        // Line 5 is not inside a class or function
        XCTAssertFalse(checker.isInScope(line: 5, column: 0, kind: .classScope))
        XCTAssertFalse(checker.isInScope(line: 5, column: 0, kind: .function))
    }
    
    func testGetClassContext() throws {
        let checker = try analyze("""
        class MyClass:
            def method(self):
                x = 1
        
        y = 2
        """)
        
        // Line 3 is inside MyClass
        XCTAssertEqual(checker.getClassContext(lineNumber: 3), "MyClass")
        
        // Line 5 is not inside any class
        XCTAssertNil(checker.getClassContext(lineNumber: 5))
    }
    
    func testSelfParameterType() throws {
        let checker = try analyze("""
        class MyClass:
            def method(self):
                x = self
        
            def other(self, value: int):
                y = self
        """)
        
        // self should have the type of the containing class
        XCTAssertEqual(checker.getVariableType("self", at: 3), "MyClass")
        XCTAssertEqual(checker.getVariableType("x", at: 3), "MyClass")
        XCTAssertEqual(checker.getVariableType("self", at: 6), "MyClass")
        XCTAssertEqual(checker.getVariableType("y", at: 6), "MyClass")
    }
    
    func testClsParameterType() throws {
        let checker = try analyze("""
        class MyClass:
            @classmethod
            def create(cls):
                return cls()
        """)
        
        // cls should have type "type[MyClass]"
        XCTAssertEqual(checker.getVariableType("cls", at: 4), "type[MyClass]")
    }
    
    func testStaticMethodNoSelf() throws {
        let checker = try analyze("""
        class MyClass:
            @staticmethod
            def utility(value):
                return value * 2
        """)
        
        // First parameter in static method is not self, should be Any
        XCTAssertEqual(checker.getVariableType("value", at: 4), "Any")
    }
}
