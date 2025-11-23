# Python Test Resources

This directory contains Python test files for validating the PySwiftAST parser.

## Test Files

### Basic Constructs
- `minimal.py` - Simplest valid Python (just pass)
- `simple_assignment.py` - Basic variable assignments
- `operators.py` - All operator types

### Statements
- `functions.py` - Function definitions (def, async def)
- `classes.py` - Class definitions with inheritance
- `control_flow.py` - if, while, for, break, continue
- `imports.py` - Import statements (various forms)
- `exceptions.py` - try/except/finally/raise/assert
- `context_managers.py` - with statements

### Expressions
- `lambdas.py` - Lambda expressions
- `comprehensions.py` - List/set/dict comprehensions and generators
- `collections.py` - Lists, tuples, dicts, sets, slicing
- `fstrings.py` - F-string formatting

### Advanced Features
- `async_await.py` - Async/await syntax
- `pattern_matching.py` - Match/case statements (Python 3.10+)
- `type_annotations.py` - Type hints and type parameters (Python 3.12+)
- `decorators.py` - Decorator usage

### Integration
- `complex_example.py` - Real-world example combining multiple features

## Usage in Tests

```swift
func loadTestFile(_ name: String) throws -> String {
    let url = Bundle.module.url(
        forResource: name,
        withExtension: "py",
        subdirectory: "Resources"
    )!
    return try String(contentsOf: url)
}

func testParseFunction() throws {
    let source = try loadTestFile("functions")
    let module = try parsePython(source)
    // ... assertions
}
```

## Coverage

These test files cover:
- ✅ All statement types
- ✅ All expression types  
- ✅ Python 3.10+ features (pattern matching)
- ✅ Python 3.12+ features (type parameters)
- ✅ Control flow
- ✅ Exception handling
- ✅ Async/await
- ✅ Comprehensions
- ✅ F-strings
- ✅ Decorators
- ✅ Type annotations

## Adding New Test Files

1. Create `.py` file in this directory
2. Add descriptive comment at the top
3. Include various examples of the feature
4. Update this README
5. Add corresponding Swift test in `PySwiftASTTests.swift`
