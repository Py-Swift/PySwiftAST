# PySwiftAST

A Python 3.13 AST parser and code generator written in pure Swift. Parse Python code without requiring a Python runtime!

## Overview

PySwiftAST provides a comprehensive toolkit for parsing and generating Python code in Swift. It consists of:

1. **Tokenizer** - Complete lexical analysis with full Python 3.13 token support
2. **Parser** - Recursive descent parser handling complex real-world Python code
3. **AST Nodes** - Complete Swift types matching Python's `ast` module (28 modular files)
4. **Code Generator** - Generate Python source code from AST

## Why Pure Swift?

A pure Swift implementation offers:

- **Speed**: No Python interpreter overhead, native performance
- **Portability**: Works anywhere Swift runs (macOS, Linux, iOS, etc.)
- **Integration**: Native Swift types and error handling
- **Tooling**: Use with Swift projects directly, great for IDEs and tools

## Architecture

### Hand-Written Recursive Descent Parser

PySwiftAST uses a hand-written recursive descent parser that efficiently handles Python 3.13 syntax:

```
Python Source → Tokenizer → Parser → Complete AST → Code Generator → Python Source
```

This approach provides:
- ✅ **Performance**: Efficient parsing with operator precedence climbing
- ✅ **Maintainability**: Clear, readable Swift code
- ✅ **No Dependencies**: Pure Swift, no Python runtime required
- ✅ **Round-Trip**: Parse and regenerate Python code

### Implementation Details

The implementation consists of:

1. **Token.swift** - All Python 3.13 token types (130+ tokens)
2. **Tokenizer.swift** - Complete lexical analysis with:
   - Indentation-aware tokenization (INDENT/DEDENT)
   - All string literal types (raw, f-strings, triple-quoted, bytes)
   - All number formats (int, float, complex, hex, octal, binary, scientific)
   - All Python operators and keywords
   - Comments and type comments
   - Proper line/column tracking

3. **AST/** (28 files) - Complete AST node definitions:
   - All statement types (if, for, while, def, class, try, with, match, etc.)
   - All expression types (BinOp, Call, Lambda, comprehensions, etc.)
   - Pattern matching (Python 3.10+)
   - Type parameters (Python 3.12+)
   - TreeDisplayable protocol for visualization

4. **Parser.swift** (3,200+ lines) - Recursive descent parser implementing:
   - All statements (assignments, control flow, functions, classes, etc.)
   - All expressions with proper operator precedence
   - Comprehensions (list, dict, set, generator)
   - Pattern matching
   - Type annotations
   - F-strings with embedded expressions and concatenation
   - Complex real-world Python constructs
   - Error recovery and reporting

5. **CodeGen.swift** - Python code generator with:
   - AST to source code conversion
   - Proper indentation and formatting
   - Round-trip support (parse → generate → parse)

## Usage

```swift
import PySwiftAST

// Parse Python code with full feature support
let source = """
def greet(name: str, age: int = 0) -> str:
    return f"Hello, {name}, age {age}!"

class Dog(Animal):
    def bark(self):
        print("Woof!")

# Ternary operator
result = 10 if x > 5 else 20

# Pattern matching
match value:
    case [x, y] if x > 0:
        print(f"Positive: {x}, {y}")
    case _:
        print("Other")

greet("World")
"""

let module = try parsePython(source)
print(module.display())  // Beautiful tree visualization

// Or just tokenize
let tokens = try tokenizePython(source)
for token in tokens {
    print(token.type)
}
```

## Features

### Core Language
- ✅ Variables, assignments, type annotations
- ✅ All operators (arithmetic, comparison, logical, bitwise)
- ✅ Assignment target validation
- ✅ Walrus operator (`:=`)
- ✅ Augmented assignments (`+=`, `-=`, etc.)

### Control Flow
- ✅ If/elif/else statements
- ✅ If-expressions (ternary: `x if cond else y`)
- ✅ For/while loops with else
- ✅ Break, continue, pass
- ✅ Match/case statements (Python 3.10+)
- ✅ Pattern matching with guards

### Functions
- ✅ Function definitions with decorators
- ✅ Async functions
- ✅ Lambda expressions
- ✅ Type annotations (parameters, return types)
- ✅ Default parameters
- ✅ `*args` and `**kwargs`
- ✅ Positional-only (`/`) and keyword-only (`*`) parameters
- ✅ Yield and yield from

### Classes
- ✅ Class definitions with decorators
- ✅ Inheritance (single and multiple)
- ✅ Metaclass specification
- ✅ Methods and attributes

### Data Structures
- ✅ Lists, tuples, dictionaries, sets
- ✅ List/dict/set comprehensions with conditions
- ✅ Generator expressions
- ✅ Starred expressions in comprehensions (`for *args, item in items`)
- ✅ Subscripting and slicing

### Literals
- ✅ Integers (decimal, hex `0xFF`, binary `0b1010`, octal `0o777`)
- ✅ Floats, scientific notation (`1.5e10`)
- ✅ Complex numbers (`1+2j`)
- ✅ Strings (all quote styles, raw, bytes)
- ✅ F-strings with embedded expressions and concatenation
- ✅ None, True, False
- ✅ Ellipsis (`...`)

### Advanced Features
- ✅ Exception handling (try/except/finally/else)
- ✅ Context managers (with statements)
- ✅ Async/await (async def, await, async for, async with)
- ✅ Import statements (all forms, including dotted: `import urllib.request`)
- ✅ Global/nonlocal declarations
- ✅ Del statements
- ✅ Assert and raise
- ✅ Implicit tuple returns (`return a, b, c`)
- ✅ Comments in expressions and blocks

See [FEATURES.md](FEATURES.md) for a comprehensive feature list.

## Why Pure Swift?

A pure Swift implementation offers:

- **Speed**: No Python interpreter overhead, native performance
- **Portability**: Works anywhere Swift runs (macOS, Linux, iOS, etc.)
- **Integration**: Native Swift types and error handling
- **Tooling**: Use with Swift projects directly, great for IDEs and tools

## Real-World Testing

PySwiftAST successfully parses complex real-world Python code:

- **Django query.py** (2,886 lines, 111 KB) - Django ORM query module, full parse + round-trip
- **Data Pipeline** (311 lines, 1,994 tokens) - Complex data processing with pandas
- **Web Framework** (412 lines, 2,515 tokens) - FastAPI-style web framework
- **ML Pipeline** (482 lines, 3,112 tokens) - Machine learning with PyTorch patterns
- **Pattern Matching** (480 lines, 2,794 tokens) - Comprehensive match/case examples

## ⚡ Performance

PySwiftAST is **faster than Python's built-in `ast` module** for both parsing and round-trip operations:

```bash
python3 benchmark.py
```

**Benchmark Results** (Django query.py, 2,886 lines):

### Parsing Only

| Parser | Median | Mean | P95 | Speedup |
|--------|--------|------|-----|---------|
| Python ast.parse() | 8.679 ms | 8.754 ms | 9.364 ms | 1.00x |
| **PySwiftAST** | **6.429 ms** | **6.669 ms** | **7.016 ms** | **1.35x faster** ✨ |

### Round-Trip (parse → generate → reparse)

| Implementation | Median | Mean | P95 | Speedup |
|----------------|--------|------|-----|---------|
| Python (parse → unparse → reparse) | 30.229 ms | 30.839 ms | 33.398 ms | 1.00x |
| **PySwiftAST** | **29.204 ms** | **29.181 ms** | **30.148 ms** | **1.04x faster** ✨ |

**Key Takeaways:**
- ✨ **1.35x faster parsing** than Python's ast module
- ✨ **1.04x faster round-trip** than Python's parse + unparse cycle
- Validates code generation correctness at scale
- Consistent performance with low variance

*Benchmark: 100 iterations with 10 warmup runs, release build, macOS*

## Testing

```bash
swift test
```

### Test Results

**72 tests, all passing (100% success rate)** 🎉

#### Test Categories:

**1. Core Functionality (7 tests)**
- ✅ Tokenizer with indentation tracking
- ✅ Simple assignments and expressions
- ✅ Function definitions
- ✅ Control structures
- ✅ Multiple statements
- ✅ Indentation validation
- ✅ **Dotted module imports** (urllib.request, xml.etree.ElementTree)

**2. Python Feature Coverage (50 tests)**
Real-world Python files covering every feature:
- ✅ Functions (def, async def, decorators, type hints, f-strings)
- ✅ Classes (inheritance, metaclass, methods)
- ✅ Control flow (if/elif/else, for, while, match/case)
- ✅ **Imports (all forms, including dotted modules)**
- ✅ Exceptions (try/except/finally/else)
- ✅ Context managers (with, async with)
- ✅ Comprehensions (list, dict, set, generator)
- ✅ Async/await (async def, await, async for)
- ✅ Lambdas and closures
- ✅ Pattern matching (comprehensive)
- ✅ Type annotations
- ✅ Decorators
- ✅ **F-strings with embedded expressions**
- ✅ All operators
- ✅ All collections
- ✅ Complex real-world examples

**3. Syntax Error Detection (10 tests)**
Validates proper error reporting:
- ✅ Missing colons
- ✅ Invalid indentation
- ✅ Unclosed strings
- ✅ Mismatched parentheses
- ✅ Invalid assignment targets
- ✅ Unexpected indents/dedents
- ✅ Unexpected tokens
- ✅ Multiple errors with clear messages

### Running Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter testPatternMatching

# Verbose output
swift test 2>&1 | less
```

## 🎯 Future Work

Potential enhancements include:

1. **Performance Optimization** - Benchmark and optimize hot paths
2. **Visitor Pattern** - AST traversal and transformation utilities
3. **Error Recovery** - Better error messages, suggest fixes
4. **Source Maps** - Preserve exact formatting information
5. **LSP Support** - Language Server Protocol integration
6. **Additional Testing** - More edge cases and Python constructs
7. **Documentation** - More examples and use cases

## Project Structure

```
PySwiftAST/
├── Sources/PySwiftAST/
│   ├── Token.swift           (130+ token types)
│   ├── Tokenizer.swift       (533 lines)
│   ├── Parser.swift          (2,904 lines)
│   ├── PySwiftAST.swift      (Public API)
│   └── AST/                  (28 files)
│       ├── Module.swift
│       ├── Statement.swift
│       ├── Expression.swift
│       ├── Statements/       (9 files)
│       ├── Expressions/      (9 files)
│       └── Supporting/       (7 files)
├── Tests/
│   └── PySwiftASTTests/
│       ├── PySwiftASTTests.swift
│       └── Resources/
│           ├── test_files/    (24 Python test files)
│           └── syntax_errors/ (10 error test files)
├── Package.swift
├── README.md
└── FEATURES.md               (Complete feature list)
```

## Contributing

Contributions are welcome! Areas for enhancement:

- Performance optimizations
- Additional visitor utilities
- More test cases
- Documentation improvements
- Example tools using the parser

## License

MIT License

## Acknowledgments

Inspired by:
- [Ruff](https://github.com/astral-sh/ruff) - Fast Python linter in Rust
- [CPython](https://github.com/python/cpython) - Python's AST module
- [Tree-sitter Python](https://github.com/tree-sitter/tree-sitter-python) - Incremental parser

Built with ❤️ in Swift for the Python community.
