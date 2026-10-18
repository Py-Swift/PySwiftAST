import XCTest
@testable import PySwiftAST
@testable import PyChecking

/// Regression tests for https://github.com/Py-Swift/PySwiftAST/issues/9
final class Issue9RegressionTests: XCTestCase {

    // MARK: - Helpers

    func analyze(_ code: String) throws -> TypeChecker {
        let module = try parsePython(code)
        let checker = TypeChecker()
        _ = checker.analyze(module)
        return checker
    }

    func parseError(_ code: String) -> ParseError? {
        do {
            _ = try parsePython(code)
            return nil
        } catch {
            return error as? ParseError
        }
    }

    // MARK: - TypeChecker

    func testParametersNotInScopeAfterFunction() throws {
        let checker = try analyze("""
        def smooth(samples: list[float]) -> list[float]:
            return samples

        result = smooth([1.0])
        x = 1
        """)

        XCTAssertEqual(Swift.Set(checker.getAllVariablesInScope(at: 5).keys), ["smooth", "result", "x"])
        XCTAssertEqual(checker.getAllVariablesInScope(at: 2)["samples"], "list[float]")
    }

    func testLocalShadowsGlobal() throws {
        let checker = try analyze("""
        x = 1
        def f():
            x = 'a'
            y = x
            return y
        z = f()
        """)

        XCTAssertEqual(checker.getAllVariablesInScope(at: 4)["x"], "str")
        XCTAssertEqual(checker.getAllVariablesInScope(at: 4)["y"], "str")
        XCTAssertEqual(checker.getAllVariablesInScope(at: 6)["x"], "int")
        XCTAssertEqual(checker.getVariableType("z", at: 6), "str")
    }

    func testFunctionNameHasCallableType() throws {
        let checker = try analyze("""
        def smooth(samples: list[float]) -> list[float]:
            return samples

        result = smooth([1.0])
        """)

        XCTAssertEqual(checker.getVariableType("smooth", at: 4), "(samples: list[float]) -> list[float]")
        XCTAssertEqual(checker.getVariableType("result", at: 4), "list[float]")
    }

    func testFunctionSignatureParameterKinds() throws {
        let checker = try analyze("""
        def f(a, b: int = 2, /, c: str = "x", *args: int, d: float, e=1, **kw: str):
            return b

        def g(x, *, y: int):
            return "s"
        """)

        XCTAssertEqual(checker.getVariableType("f"), "(a, b: int = ..., /, c: str = ..., *args: int, d: float, e = ..., **kw: str) -> int")
        XCTAssertEqual(checker.getVariableType("g"), "(x, *, y: int) -> str")

        let inside = checker.getAllVariablesInScope(at: 2)
        XCTAssertEqual(inside["args"], "tuple[int, ...]")
        XCTAssertEqual(inside["kw"], "dict[str, str]")
        XCTAssertEqual(inside["d"], "float")
    }

    func testInferredReturnTypes() throws {
        let checker = try analyze("""
        def fact(n: int):
            if n <= 1:
                return 1
            return n * fact(n - 1)

        def gen():
            yield 1

        def noret(x: int):
            x += 1

        sq = lambda v: v
        r = fact(3)
        """)

        XCTAssertEqual(checker.getVariableType("fact"), "(n: int) -> int")
        XCTAssertEqual(checker.getVariableType("gen"), "() -> Any")
        XCTAssertEqual(checker.getVariableType("noret"), "(x: int) -> None")
        XCTAssertEqual(checker.getVariableType("sq"), "(v) -> Any")
        XCTAssertEqual(checker.getVariableType("r"), "int")
    }

    // MARK: - Parse errors

    func testUnclosedBracketReportedAtBracket() {
        let cases: [(code: String, bracket: String, line: Int, column: Int)] = [
            ("x = [1, 2\n\n\nprint(x)\n", "[", 1, 5),
            ("x = foo(1,\ny = 2\n", "(", 1, 8),
            ("def f(\n    pass\n", "(", 1, 6),
        ]
        for (code, bracket, line, column) in cases {
            guard case .unclosedBracket(let token, _) = parseError(code) else {
                XCTFail("Expected unclosedBracket for \(code.debugDescription)")
                continue
            }
            XCTAssertEqual(token.value, bracket)
            XCTAssertEqual(token.line, line)
            XCTAssertEqual(token.column, column)
        }
        XCTAssertTrue(parseError("x = [1, 2\n")?.description.hasPrefix("'[' was never closed at line 1, column 5") ?? false)
    }

    func testErrorBeforeUnclosedBracketIsKept() {
        guard case .unexpectedToken(let token) = parseError("x = = 1\ny = [1\n") else {
            return XCTFail("Expected unexpectedToken")
        }
        XCTAssertEqual(token.line, 1)
    }

    func testFixInsertsAfterPreviousToken() {
        guard case .expectedToken(_, _, _, let fix?) = parseError("def foo()\n    pass\n") else {
            return XCTFail("Expected expectedToken with a fix")
        }
        XCTAssertEqual(fix, ParseFix(line: 1, column: 10, text: ":", fixedLine: "def foo():"))

        guard case .expectedToken(_, _, _, let fix2?) = parseError("if x print(1)\n") else {
            return XCTFail("Expected expectedToken with a fix")
        }
        XCTAssertEqual(fix2.fixedLine, "if x: print(1)")
    }

    func testNoInsertionFixForMismatchedBracket() {
        guard case .expectedToken(let expected, _, _, let fix) = parseError("x = [1, 2)\n") else {
            return XCTFail("Expected expectedToken")
        }
        XCTAssertEqual(expected, "]")
        XCTAssertNil(fix)
    }

    func testUnexpectedNewlineHasColumn() {
        let error = parseError("x = 1 +\n")
        guard case .unexpectedToken(let token) = error else {
            return XCTFail("Expected unexpectedToken")
        }
        XCTAssertEqual(token.type, .newline)
        XCTAssertEqual(error?.column, 8)
        XCTAssertEqual(error?.description, "Unexpected newline at line 1, column 8")
    }

    // MARK: - Found while investigating

    func testTokenTypeDescriptionDoesNotRecurse() {
        XCTAssertEqual(TokenType.assign.description, "ASSIGN")
        XCTAssertEqual(TokenType.leftparen.description, "LEFTPAREN")
        XCTAssertEqual(TokenType.name("x").description, "NAME(x)")
    }

    func testEscapedBackslashIsNotUnescapedTwice() throws {
        let module = try parsePython("a = '\\\\n'\n")
        guard case .module(let statements) = module,
              case .assign(let assign) = statements.first,
              case .constant(let constant) = assign.value,
              case .string(let value) = constant.value else {
            return XCTFail("Expected a string assignment")
        }
        XCTAssertEqual(value, "\\n")
    }
}
