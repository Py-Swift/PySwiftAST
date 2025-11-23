# Syntax Error Detection Examples

This document shows real examples of syntax error detection in PySwiftAST.

## Test Results Overview

```
Total Tests: 35
├── Core Functionality: 6 tests ✅
├── Python Features: 19 tests ✅
└── Syntax Errors: 10 tests ✅
```

All tests passing! ✅

## Error Detection Examples

### 1. Missing Colon

**Input:**
```python
if x > 3
    print("x is greater than 3")
```

**Output:**
```
✅ Parser correctly failed: Expected ':' after if condition at line 3
```

---

### 2. Invalid Indentation

**Input:**
```python
def foo():
    x = 1
   y = 2  # Wrong indentation level
    return x + y
```

**Output:**
```
✅ Parser correctly failed: IndentationError at line 4, column 4
```

---

### 3. Unexpected Token

**Input:**
```python
x = 5
y = @ 10  # Invalid operator
z = x + y
```

**Output:**
```
✅ Parser correctly failed: Unexpected token '@' at line 3
```

---

### 4. Mismatched Parentheses

**Input:**
```python
result = (1 + 2 * (3 + 4)
print(result)
```

**Output:**
```
✅ Parser correctly failed: Unexpected token '(' at line 3
```

---

### 5. Invalid Assignment Target

**Input:**
```python
5 = x
print(x)
```

**Output:**
```
✅ Parser correctly failed: Unexpected token '=' at line 2
```

---

### 6. Unexpected Indentation

**Input:**
```python
x = 1
    y = 2  # This should not be indented
z = 3
```

**Output:**
```
✅ Tokenizer/Parser correctly failed: IndentationError at line 3, column 5
```

---

### 7. Invalid Dedent Level

**Input:**
```python
def foo():
    if True:
        x = 1
      y = 2  # Dedent to invalid level
    return x + y
```

**Output:**
```
✅ Tokenizer/Parser correctly failed: IndentationError at line 5, column 7
```

---

### 8. Error Message Quality

**Test Code:**
```swift
let source = """
def foo()
    pass
"""

do {
    let _ = try parsePython(source)
} catch let error as ParseError {
    print(error.description)
}
```

**Output:**
```
Expected ':' after function signature at line 1
```

Error messages include:
- ✅ Clear description of the problem
- ✅ Line number
- ✅ Context about what was expected

---

## Error Types Detected

### Tokenization Errors
- **Indentation errors**: INDENT/DEDENT tracking
- **Invalid dedent**: Dedent to non-existent level
- **Unexpected indent**: Indent without reason

### Parse Errors
- **Missing syntax**: Colons, parentheses, brackets
- **Unexpected tokens**: Invalid operators or keywords
- **Invalid structures**: Wrong assignment targets

### Error Reporting Features
- Line numbers for all errors
- Descriptive messages
- Swift error handling integration
- Proper error types (ParseError, TokenizationError)

---

## Running Syntax Error Tests

```bash
# Run all syntax error tests
swift test --filter "test.*Error|testMissing|testInvalid|testUnexpected"

# Run specific error test
swift test --filter testMissingColon

# See detailed output
swift test --filter testInvalidIndentation 2>&1

# Count passing tests
swift test 2>&1 | grep "Test run with"
```

**Current Results:**
```
✔ Test run with 35 tests in 0 suites passed after 0.013 seconds.
```

---

## Known Limitations

### Unclosed Strings ⚠️
Currently, the tokenizer allows newlines in non-triple-quoted strings:

```python
message = "Hello, World!
print(message)
```

**Status**: Known limitation - should be fixed in tokenizer
**TODO**: Add validation to reject newlines in single/double quoted strings

---

## Future Improvements

1. **More Comprehensive Error Messages**
   - Show the actual code context
   - Suggest fixes for common mistakes
   - Multi-line error context

2. **Better Error Recovery**
   - Continue parsing after errors
   - Report multiple errors in one pass
   - Provide suggestions

3. **Additional Error Types**
   - Semantic errors (duplicate params, invalid names)
   - Type annotation validation
   - Decorator validation
   - More detailed indentation errors

4. **Error Visualization**
   - Color-coded output
   - Caret pointing to error location
   - "Did you mean..." suggestions

---

## Architecture

```
Source Code
    ↓
Tokenizer ──→ TokenizationError (indentation, invalid tokens)
    ↓
Parser ──────→ ParseError (syntax, structure)
    ↓
AST (Valid)
```

Each stage can detect and report errors appropriate to its level of analysis.
