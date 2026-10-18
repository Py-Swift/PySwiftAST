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

    // MARK: - Modules and stubs

    func testImportedModulesHaveModuleType() throws {
        let checker = try analyze("""
        import math
        import os.path
        import os.path as osp
        from os import path
        from json import loads as parse
        from mystery import thing
        x = 1
        """)

        let vars = checker.getAllVariablesInScope(at: 7)
        XCTAssertEqual(vars["math"], "Module(\"math\")")
        XCTAssertEqual(vars["os"], "Module(\"os\")")
        XCTAssertEqual(vars["osp"], "Module(\"os.path\")")
        XCTAssertEqual(vars["path"], "Module(\"os.path\")")
        XCTAssertEqual(vars["parse"], "(s: str | bytes, *, object_hook: Any = ..., parse_float: Any = ..., parse_int: Any = ..., parse_constant: Any = ..., object_pairs_hook: Any = ...) -> Any")
        XCTAssertEqual(vars["thing"], "Any")
    }

    func testStandardLibraryTypes() throws {
        let checker = try analyze("""
        import math
        import os
        import random
        from time import sleep, localtime
        x = math.pi
        y = math.sin(1.0)
        n = math.floor(2.5)
        p = os.path.join("a", "b")
        rng = random.Random()
        r = rng.randint(1, 6)
        t = localtime()
        year = t.tm_year
        z = math.not_there
        """)

        XCTAssertEqual(checker.getVariableType("x"), "float")
        XCTAssertEqual(checker.getVariableType("y"), "float")
        XCTAssertEqual(checker.getVariableType("n"), "int")
        XCTAssertEqual(checker.getVariableType("p"), "str")
        XCTAssertEqual(checker.getVariableType("rng"), "Random")
        XCTAssertEqual(checker.getVariableType("r"), "int")
        XCTAssertEqual(checker.getVariableType("sleep"), "(seconds: float, /) -> None")
        XCTAssertEqual(checker.getVariableType("t"), "struct_time")
        XCTAssertEqual(checker.getVariableType("year"), "int")
        XCTAssertEqual(checker.getVariableType("z"), "Unknown")
        XCTAssertEqual(checker.getAttributeTypeString(object: "math", attribute: "tau", line: 13), "float")
    }

    func testStarImportAndOptionalReturn() throws {
        let checker = try analyze("""
        from math import *
        import re
        a = sqrt(2.0)
        m = re.match("a", "abc")
        """)

        XCTAssertEqual(checker.getVariableType("a"), "float")
        XCTAssertEqual(checker.getVariableType("pi"), "float")
        XCTAssertEqual(checker.getVariableType("m"), "Match | None")
    }

    func testCustomStubs() throws {
        var stubs = StubRegistry.standardLibrary
        try stubs.register(module: "touchbay", source: """
        class Pad:
            name: str
            def pressure(self) -> float: ...

        VERSION: str
        def pad(index: int) -> Pad: ...
        """)

        let checker = TypeChecker(stubs: stubs)
        _ = checker.analyze(try parsePython("""
        import touchbay
        p = touchbay.pad(0)
        level = p.pressure()
        label = p.name
        v = touchbay.VERSION
        """))

        XCTAssertEqual(checker.getVariableType("p"), "Pad")
        XCTAssertEqual(checker.getVariableType("level"), "float")
        XCTAssertEqual(checker.getVariableType("label"), "str")
        XCTAssertEqual(checker.getVariableType("v"), "str")
    }

    func testScriptClassIsNotReplacedByStubClass() throws {
        let checker = try analyze("""
        class Match:
            def score(self) -> int:
                return 1

        import re
        s = Match().score()
        """)

        XCTAssertEqual(checker.getVariableType("s"), "int")
    }

    func testBundledStubsParse() {
        for (name, _) in StandardLibraryStubs.sources {
            XCTAssertNotNil(StubRegistry.standardLibrary.module(name), "Stub for \(name) missing")
        }
        XCTAssertEqual(StubRegistry.standardLibrary.module("math")?.members["pi"], .float)
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
    
    func testSoftKeywordsAsNames() throws {
        let names = [
            "match = 1\n", "x = match\n", "m = re.match(a, b)\n", "def match(): pass\n",
            "class C:\n    def match(self): pass\n", "f(match=1)\n", "case = 2\n",
            "type = 3\n", "print(type(x))\n", "match(x)\n", "match[0] = 1\n",
        ]
        for code in names {
            XCTAssertNoThrow(try parsePython(code), code.debugDescription)
        }
    }
    
    func testSoftKeywordTestFilesParse() throws {
        // Both files use `match` as a variable name next to match statements
        for name in ["parser_combinators", "state_machine"] {
            XCTAssertNoThrow(try parsePython(loadTestFileResource(name)), name)
        }
    }
    
    func testMatchStatementsStillParse() throws {
        let statements = [
            "match x:\n    case 1:\n        pass\n",
            "match (x):\n    case 1:\n        pass\n",
            "match -x:\n    case 1:\n        pass\n",
            "match [a, b]:\n    case [1, 2]:\n        pass\n",
            "match x:  # comment\n    case _:\n        pass\n",
            "match x:\n    # comment\n    case 1:\n        pass\n    # between\n    case _:\n        pass\n",
            "type X = int\n",
        ]
        for code in statements {
            let module = try parsePython(code)
            guard case .module(let body) = module, let first = body.first else {
                return XCTFail("No statement for \(code.debugDescription)")
            }
            switch first {
            case .match, .typeAlias: break
            default: XCTFail("Expected match or type alias for \(code.debugDescription), got \(first)")
            }
        }
    }

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
