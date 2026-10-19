import XCTest
@testable import PySwiftAST
@testable import PyChecking

/// Regression tests for https://github.com/Py-Swift/PySwiftAST/issues/11
final class Issue11RegressionTests: XCTestCase {

    // MARK: - Helpers

    func analyze(_ code: String) throws -> TypeChecker {
        let module = try parsePython(code)
        let checker = TypeChecker()
        _ = checker.analyze(module)
        return checker
    }

    /// The script from the issue: a class used as a namespace of static methods
    let namespaceScript = """
    class functions:
        @staticmethod
        def smooth(samples: list[float]) -> list[float]: ...
    def oscillator(self, value: float) -> None:
        samples = [1.0, 2.0]
        smoothed = functions.smooth(samples)
        print(smoothed)
    x = functions.smooth([1.0])
    """

    // MARK: - 1. Classes in scope

    func testModuleLevelClassInScope() throws {
        let checker = try analyze(namespaceScript)

        let symbols = Dictionary(uniqueKeysWithValues: checker.getSymbolsAt(line: 8, column: 0).map { ($0.name, $0.type) })
        XCTAssertEqual(symbols["functions"], .classType("functions"))
        XCTAssertEqual(checker.getAllVariablesInScope(at: 6)["functions"], "type[functions]")
        XCTAssertEqual(checker.getAllVariablesInScope(at: 8)["functions"], "type[functions]")
    }

    func testClassNotInScopeBeforeDefinition() throws {
        let checker = try analyze("""
        x = 1
        class Later:
            pass
        """)

        XCTAssertNil(checker.getAllVariablesInScope(at: 1)["Later"])
        XCTAssertEqual(checker.getAllVariablesInScope(at: 3)["Later"], "type[Later]")
    }

    // MARK: - 2. Static methods called through their class

    func testStaticMethodCallThroughClass() throws {
        let checker = try analyze(namespaceScript)

        XCTAssertEqual(checker.getAllVariablesInScope(at: 7)["smoothed"], "list[float]")
        XCTAssertEqual(checker.getVariableType("x"), "list[float]")
    }

    func testStaticMethodAttributeType() throws {
        let checker = try analyze(namespaceScript)

        XCTAssertEqual(checker.getAttributeTypeString(object: "functions", attribute: "smooth", line: 6),
                       "(samples: list[float]) -> list[float]")
    }

    func testStaticMethodMemberHasCallableType() throws {
        let checker = try analyze(namespaceScript)

        let members = checker.getClassMembers(className: "functions")
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(members.first?.kind, .staticMethod)
        XCTAssertEqual(members.first?.type.toDisplayString(), "(samples: list[float]) -> list[float]")
    }

    // MARK: - Methods bound to instances and classes

    func testMethodsBoundByAccess() throws {
        let checker = try analyze("""
        class Counter:
            def add(self, n: int) -> int:
                return n
            @classmethod
            def create(cls, start: int) -> Counter:
                return cls()
            @staticmethod
            def zero() -> int:
                return 0
        c = Counter()
        a = c.add(1)
        b = Counter.zero()
        d = c.zero()
        e = Counter.create(1)
        """)

        // On an instance, self is dropped; on the class, a plain method keeps it
        XCTAssertEqual(checker.getAttributeTypeString(object: "c", attribute: "add", line: 11), "(n: int) -> int")
        XCTAssertEqual(checker.getAttributeTypeString(object: "Counter", attribute: "add", line: 11), "(self, n: int) -> int")
        // cls is dropped either way
        XCTAssertEqual(checker.getAttributeTypeString(object: "Counter", attribute: "create", line: 11), "(start: int) -> Counter")
        XCTAssertEqual(checker.getAttributeTypeString(object: "c", attribute: "zero", line: 11), "() -> int")

        XCTAssertEqual(checker.getVariableType("a"), "int")
        XCTAssertEqual(checker.getVariableType("b"), "int")
        XCTAssertEqual(checker.getVariableType("d"), "int")
        XCTAssertEqual(checker.getVariableType("e"), "Counter")
    }

    func testPropertyReadsAsValue() throws {
        let checker = try analyze("""
        class Box:
            @property
            def size(self) -> int:
                return 1
        b = Box()
        s = b.size
        """)

        XCTAssertEqual(checker.getClassMembers(className: "Box").first?.kind, .property)
        XCTAssertEqual(checker.getAttributeTypeString(object: "b", attribute: "size", line: 6), "int")
        XCTAssertEqual(checker.getVariableType("s"), "int")
    }

    func testAsyncStaticMethodKind() throws {
        let checker = try analyze("""
        class Api:
            @staticmethod
            async def fetch(url: str) -> str:
                return url
        """)

        XCTAssertEqual(checker.getClassMembers(className: "Api").first?.kind, .staticMethod)
        XCTAssertEqual(checker.getAttributeTypeString(object: "Api", attribute: "fetch", line: 4), "(url: str) -> str")
    }

    func testDecoratedAsyncDefParses() throws {
        let module = try parsePython("""
        @decorator
        async def fetch(url: str) -> str:
            return url
        """)

        guard case .module(let statements) = module,
              case .asyncFunctionDef(let funcDef) = statements.first else {
            return XCTFail("Expected an async function definition")
        }
        XCTAssertEqual(funcDef.decoratorList.count, 1)
    }

    func testStubClassMethodCall() throws {
        let checker = try analyze("""
        import random
        rng = random.Random()
        r = rng.random()
        """)

        XCTAssertEqual(checker.getVariableType("r"), "float")
    }
}
