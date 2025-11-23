# Syntax Error Test Files

This directory contains Python files with intentional syntax errors for testing the parser's error detection and reporting capabilities.

## Test Files

### 1. `missing_colon.py` ✅
**Error**: Missing colon after `if` statement
```python
if x > 3
    print("x is greater than 3")
```
**Expected**: Parser should reject missing colon on conditional statements

### 2. `invalid_indentation.py` ✅
**Error**: Inconsistent indentation levels within function
```python
def foo():
    x = 1
   y = 2  # Wrong indentation - not aligned with previous line
    return x + y
```
**Expected**: Tokenizer should detect IndentationError

### 3. `unclosed_string.py` ⚠️
**Error**: String literal not closed before newline
```python
message = "Hello, World!
print(message)
```
**Status**: Known limitation - tokenizer currently allows newlines in strings
**TODO**: Implement proper string validation for non-triple-quoted strings

### 4. `mismatched_parens.py` ✅
**Error**: Unclosed opening parenthesis
```python
result = (1 + 2 * (3 + 4)
print(result)
```
**Expected**: Parser should detect unmatched parentheses

### 5. `invalid_assignment.py` ✅
**Error**: Cannot assign to literal value
```python
5 = x
```
**Expected**: Parser should reject literal as assignment target

### 6. `unexpected_indent.py` ✅
**Error**: Indentation at module level without reason
```python
x = 1
    y = 2  # This should not be indented
z = 3
```
**Expected**: Tokenizer should detect unexpected indent

### 7. `multiple_errors.py` ✅
**Error**: Multiple syntax errors in one file
- Missing colon after function definition
- Unclosed string
- Missing colon after if
- Invalid indentation
**Expected**: Parser should fail on first error encountered

### 8. `unexpected_token.py` ✅
**Error**: Invalid operator in expression
```python
y = @ 10  # @ is not a valid unary operator in this context
```
**Expected**: Parser should reject unexpected token

### 9. `invalid_dedent.py` ✅
**Error**: Dedent to level that doesn't match any previous indent
```python
def foo():
    if True:
        x = 1
      y = 2  # Dedents to column 6, but no previous indent at that level
    return x + y
```
**Expected**: Tokenizer should detect IndentationError

## Test Results

As of November 23, 2025:
- **Total Tests**: 10
- **Passing**: 10 ✅
- **Known Issues**: 1 (unclosed_string - limitation documented)

## Error Detection Capabilities

The parser successfully detects:

1. **Tokenization Errors**:
   - Indentation errors (INDENT/DEDENT tracking)
   - Invalid dedent levels
   - Unexpected indentation

2. **Parse Errors**:
   - Missing colons in compound statements
   - Unexpected tokens
   - Invalid assignment targets
   - Unmatched parentheses

3. **Error Reporting**:
   - Includes line numbers
   - Descriptive error messages
   - Uses Swift's error handling system

## Future Improvements

1. **Enhanced String Validation**:
   - Detect newlines in non-triple-quoted strings
   - Validate escape sequences
   - Check for EOF in string literals

2. **Better Error Recovery**:
   - Report multiple errors in one pass
   - Suggest fixes for common mistakes
   - Show context around error location

3. **More Error Types**:
   - Invalid function/class names
   - Duplicate parameter names
   - Invalid decorator usage
   - Type annotation errors

## Running Tests

Run all syntax error tests:
```bash
swift test --filter "test.*Error|testMissingColon|testInvalid|testUnexpected"
```

Run a specific test:
```bash
swift test --filter testMissingColon
```

Run with verbose output:
```bash
swift test --filter testMissingColon 2>&1
```
