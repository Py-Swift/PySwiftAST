# PyFormatters

Code formatters for Python AST, providing automated code style enforcement.

## Overview

PyFormatters provides formatters that transform Python AST trees to enforce specific code styles. All formatters conform to the `PyFormatter` protocol.

Currently includes:

- **BlackFormatter**: Enforces [Black](https://black.readthedocs.io/) code style rules

## PyFormatter Protocol

All formatters implement this protocol:

```swift
public protocol PyFormatter {
    /// Format top-level statements only
    func format(_ module: Module) -> Module
    
    /// Recursively format all nested structures
    func formatDeep(_ module: Module) -> Module
}
```

## Features

### BlackFormatter

Implements Black's blank line rules:

- **Module level**: 2 blank lines before/after functions and classes
- **Class level**: 
  - 1 blank line after class docstring
  - 1 blank line between methods
- **Function level**: 
  - 1 blank line before/after inner function definitions
  - No blank line after function docstrings (unless inner function follows)

## Usage

```swift
import PySwiftAST
import PySwiftCodeGen
import PyFormatters

// Parse Python code
let parser = Parser(sourceCode)
let module = try parser.parse()

// Apply Black formatting (protocol conformance)
let formatter: PyFormatter = BlackFormatter()
let formatted = formatter.formatDeep(module)

// Generate formatted Python code
let output = formatted.toPythonCode()
```

## API

### BlackFormatter

```swift
public struct BlackFormatter {
    public init()
    
    /// Format top-level statements only
    public func format(_ module: Module) -> Module
    
    /// Recursively format all nested structures
    public func formatDeep(_ module: Module) -> Module
}
```

#### Methods

- **`format(_:)`**: Applies Black's blank line rules to module-level statements only. Doesn't recurse into function/class bodies.

- **`formatDeep(_:)`**: Recursively applies formatting rules at all nesting levels (module, class body, function body).

## Example

**Input:**
```python
def foo():
    pass
def bar():
    pass
class MyClass:
    def method1(self):
        pass
    def method2(self):
        pass
```

**Output (Black formatted):**
```python
def foo():
    pass


def bar():
    pass


class MyClass:
    def method1(self):
        pass

    def method2(self):
        pass
```

## Implementation Details

- Uses `Statement.blank()` API for explicit blank line control
- Preserves AST round-trip integrity
- Detects docstrings (string literals as first statement)
- Handles all statement types (if/while/for/try/etc.)

## Future Formatters

Planned additions:
- PEP 8 formatter (with configurable options)
- Custom formatters with user-defined rules
- Import sorting/organization
- Line length enforcement

All future formatters will conform to `PyFormatter` for consistent API.
