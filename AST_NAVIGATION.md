# Quick Reference: Finding AST Node Definitions

## By Category

### Statements
- **Functions & Classes**: `Statements/FunctionDef.swift`, `Statements/ClassDef.swift`
- **Control Flow**: `Statements/ControlFlow.swift` - if, while, for, break, continue, pass, return
- **Assignments**: `Statements/Assignments.swift` - assign, augmented assign, annotated assign, delete
- **Imports**: `Statements/Imports.swift` - import, from...import
- **Exceptions**: `Statements/ExceptionHandling.swift` - raise, try, assert
- **Context Managers**: `Statements/ContextManagers.swift` - with, async with
- **Pattern Matching**: `Statements/PatternMatching.swift` - match statement
- **Other**: `Statements/Miscellaneous.swift` - global, nonlocal, expr, type alias

### Expressions
- **Operations**: `Expressions/BinaryOperations.swift` - +, -, *, /, comparisons, and, or, not
- **Functions**: `Expressions/Lambda.swift` - lambda expressions
- **Conditionals**: `Expressions/IfExpression.swift` - ternary operator
- **Collections**: `Expressions/Collections.swift` - dict, set, list, tuple literals
- **Comprehensions**: `Expressions/Comprehensions.swift` - list/set/dict comps, generators
- **Async**: `Expressions/AsyncAwaitYield.swift` - await, yield, yield from
- **Access**: `Expressions/CallAndAccess.swift` - function calls, obj.attr, obj[key], slicing
- **Literals**: `Expressions/Literals.swift` - numbers, strings, bools, None, names
- **F-Strings**: `Expressions/FStrings.swift` - formatted strings
- **Special**: `Expressions/NamedAndStarred.swift` - walrus operator, starred expressions

## By Python Feature

### Looking for...
- **Type hints** → `Statements/FunctionDef.swift`, `Statements/Miscellaneous.swift` (TypeAlias)
- **Decorators** → `Statements/FunctionDef.swift`, `Statements/ClassDef.swift`
- **Async/await** → `Expressions/AsyncAwaitYield.swift`, `Statements/FunctionDef.swift`, `Statements/ControlFlow.swift`
- **Pattern matching** → `Statements/PatternMatching.swift`, `Patterns.swift`
- **Type parameters (Python 3.12+)** → `TypeParameters.swift`
- **F-strings** → `Expressions/FStrings.swift`
- **Comprehensions** → `Expressions/Comprehensions.swift`
- **Context managers** → `Statements/ContextManagers.swift`
- **Exception handling** → `Statements/ExceptionHandling.swift`

## Common Lookups

| Looking for | File |
|-------------|------|
| `def`, `async def` | `Statements/FunctionDef.swift` |
| `class` | `Statements/ClassDef.swift` |
| `if`, `elif`, `else` | `Statements/ControlFlow.swift` |
| `for`, `while` | `Statements/ControlFlow.swift` |
| `return`, `break`, `continue`, `pass` | `Statements/ControlFlow.swift` |
| `=`, `+=`, etc. | `Statements/Assignments.swift` |
| `import`, `from...import` | `Statements/Imports.swift` |
| `try`, `except`, `raise` | `Statements/ExceptionHandling.swift` |
| `with` | `Statements/ContextManagers.swift` |
| `match`, `case` | `Statements/PatternMatching.swift` |
| `lambda` | `Expressions/Lambda.swift` |
| `x if y else z` | `Expressions/IfExpression.swift` |
| `[...]`, `{...}`, `(...)` | `Expressions/Collections.swift` |
| `[x for x in ...]` | `Expressions/Comprehensions.swift` |
| `await`, `yield` | `Expressions/AsyncAwaitYield.swift` |
| `f"..."` | `Expressions/FStrings.swift` |
| `obj.attr`, `func()`, `obj[i]` | `Expressions/CallAndAccess.swift` |
| Numbers, strings, `True`, `False`, `None` | `Expressions/Literals.swift` |
| `:=` (walrus), `*args` | `Expressions/NamedAndStarred.swift` |

## Core Files

- **Base types**: `ASTNode.swift`, `Module.swift`
- **Enums**: `Statement.swift`, `Expression.swift`
- **Operators**: `Operators.swift` - all operator enums
- **Helpers**: `HelperTypes.swift` - Arguments, Keywords, Alias, etc.
- **Patterns**: `Patterns.swift` - pattern matching patterns
- **Type params**: `TypeParameters.swift` - type parameters (PEP 695)

## Tips

1. **Use IDE search**: Press Cmd+Shift+O (or Ctrl+Shift+P) and type the struct name
2. **Grep for names**: `grep -r "struct FunctionDef" Sources/PySwiftAST/AST/`
3. **Check the enum**: Look in `Statement.swift` or `Expression.swift` to see all cases
4. **Read the README**: `Sources/PySwiftAST/AST/README.md` has the full structure
