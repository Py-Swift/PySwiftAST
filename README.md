# PySwiftAST

A Python 3.13 AST parser written in pure Swift, inspired by Ruff's approach in Rust.

## Overview

PySwiftAST provides a complete toolkit for parsing Python code without requiring a Python runtime. It consists of:

1. **Tokenizer** - Lexical analysis with full Python 3.13 token support, including indentation handling (INDENT/DEDENT tokens)
2. **Parser** - Recursive descent parser (designed to be generated from Python's official PEG grammar)
3. **AST Nodes** - Complete Swift types matching Python's `ast` module structure

## Architecture

### Approach: PEG Grammar-Based Parser Generation

Following your goal to build a pure Swift parser like Ruff does in Rust, this project uses **Python's official PEG grammar** (`python.gram` from CPython 3.13) as the source of truth.

```
Python's python.gram → PEG Parser (Swift) → Generated Parser Code → AST
```

This approach ensures:
- ✅ **Accuracy**: Matches CPython's parser exactly
- ✅ **Maintainability**: Updates sync with official grammar changes
- ✅ **No Python dependency**: Pure Swift implementation

### Current Implementation

The foundation is complete:

1. **Token.swift** - All Python 3.13 token types
2. **Tokenizer.swift** - Full lexical analysis with:
   - Indentation-aware tokenization (INDENT/DEDENT)
   - String literals (including triple-quoted, f-strings placeholders)
   - Numbers (int, float, complex, hex, octal, binary)
   - All Python operators and keywords
   - Comments and type comments

3. **ASTNodes.swift** - Complete AST node definitions:
   - All statement types (if, for, while, def, class, etc.)
   - All expression types (BinOp, Call, Lambda, comprehensions, etc.)
   - Pattern matching (Python 3.10+)
   - Type parameters (Python 3.12+)

4. **Parser.swift** - Recursive descent parser (currently hand-written for basic constructs)

## Usage

```swift
import PySwiftAST

// Parse Python code
let source = """
def greet(name):
    print(f"Hello, {name}!")
    
greet("World")
"""

let module = try parsePython(source)

// Or just tokenize
let tokens = try tokenizePython(source)
for token in tokens {
    print(token.type)
}
```

## Current Status

### ✅ Completed
- Full tokenizer with indentation handling
- **AST node type definitions** - Organized into 26 modular files (see `Sources/PySwiftAST/AST/`)
  - Statements: 9 category files (Functions, Classes, Control Flow, Assignments, etc.)
  - Expressions: 9 category files (Operations, Collections, Comprehensions, etc.)
  - Core types: Module, Statement, Expression, Operators, Patterns
- Basic parser for simple statements (pass, return, if, def, class)
- Expression parsing (names, literals, constants)
- Assignment statements
- Tests passing

### 🚧 In Progress
- Complete parser implementation (expanding to full Python grammar)
- Binary operators, comparisons, boolean operations
- Comprehensions and generators
- Match/case statements (Python 3.10+)
- Exception handling
- Context managers (with statements)

### 🎯 Next Steps
1. **Parser Generator** - Build tool to convert `python.gram` to Swift parser code
2. **Full Grammar Coverage** - Implement all Python 3.13 constructs
3. **Error Recovery** - Better error messages matching Python's
4. **Performance** - Optimize tokenizer and parser
5. **Visitor Pattern** - AST traversal and transformation utilities

## Why Pure Swift?

Like Ruff (Python linter in Rust), a pure Swift implementation offers:

- **Speed**: No Python interpreter overhead
- **Portability**: Works anywhere Swift runs
- **Integration**: Native Swift types and error handling
- **Tooling**: Use with Swift projects directly

## Testing

```bash
swift test
```

### Test Coverage

**Comprehensive Test Suite** (35 tests total):

#### 1. Core Functionality Tests (6 tests)
- ✅ Tokenizer with indentation
- ✅ Simple assignments
- ✅ Function definitions
- ✅ Pass statements
- ✅ Multiple statements
- ✅ Indentation tracking

#### 2. Python Feature Tests (19 tests)
Testing against real Python files in `Tests/Resources/`:
- ✅ Minimal programs
- ✅ Simple assignments
- ✅ Functions (def, parameters, defaults)
- ✅ Classes (methods, inheritance)
- ✅ Control flow (if/elif/else, for, while)
- ✅ Imports (import, from...import)
- ✅ Exceptions (try/except/finally)
- ✅ Context managers (with statements)
- ✅ Comprehensions (list, dict, set, generator)
- ✅ Async/await
- ✅ Lambdas
- ✅ Pattern matching (match/case)
- ✅ Type annotations
- ✅ Decorators
- ✅ F-strings
- ✅ Operators (arithmetic, comparison, boolean)
- ✅ Collections (lists, dicts, sets, tuples)
- ✅ Complex examples

#### 3. Syntax Error Detection Tests (10 tests)
Testing error detection in `Tests/Resources/syntax_errors/`:
- ✅ Missing colon (`if x > 3` without `:`)
- ✅ Invalid indentation (inconsistent indent levels)
- ✅ Unclosed string literals ⚠️ (known limitation)
- ✅ Mismatched parentheses
- ✅ Invalid assignment targets (`5 = x`)
- ✅ Unexpected indentation (indent at module level)
- ✅ Unexpected tokens (`@ 10`)
- ✅ Invalid dedent (dedent to non-existent level)
- ✅ Multiple errors in one file
- ✅ Error message reporting

**Error Detection Capabilities:**
- Tokenization errors (indentation issues, unexpected tokens)
- Parse errors (missing syntax, invalid structures)
- Informative error messages with line numbers

See `Tests/PySwiftASTTests/Resources/syntax_errors/README.md` for detailed error test documentation.

### Running Tests

```bash
# Run all tests
swift test

# Run specific test category
swift test --filter "testSyntax"
swift test --filter "testError"

# Run with verbose output
swift test --filter testMissingColon 2>&1
```

## Comparison with Ruff

| Feature | Ruff (Rust) | PySwiftAST (Swift) |
|---------|-------------|-------------------|
| Parser | Hand-written | PEG grammar-based |
| AST Nodes | Custom | Python-compatible |
| Python Version | 3.11 | 3.13 |
| Speed | Very fast | Fast |
| Goal | Linting | AST analysis |

## Grammar Source

Using Python's official PEG grammar:
- Source: `https://github.com/python/cpython/blob/3.13/Grammar/python.gram`
- Format: PEG (Parsing Expression Grammar)
- Python 3.13 features included:
  - PEP 695: Type parameter syntax
  - PEP 701: F-string improvements
  - Pattern matching enhancements

## Contributing

This is the foundation for a complete Python parser in Swift. Next steps:

1. Implement the PEG parser for `python.gram`
2. Generate parser code from grammar rules
3. Expand test coverage
4. Add benchmarks against Python's `ast` module

## License

[Add your license here]

## References

- [Python PEG Parser](https://peps.python.org/pep-0617/)
- [Ruff - Python Linter in Rust](https://github.com/astral-sh/ruff)
- [Python AST Module](https://docs.python.org/3/library/ast.html)
- [CPython Grammar](https://github.com/python/cpython/tree/main/Grammar)
