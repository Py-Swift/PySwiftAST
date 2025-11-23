# AST Module Structure

The Python AST types are now organized into a modular structure for better maintainability.

## Directory Structure

```
Sources/PySwiftAST/AST/
├── ASTNode.swift                  # Base protocol
├── Module.swift                   # Module types
├── Statement.swift                # Statement enum
├── Expression.swift               # Expression enum
├── Operators.swift                # Operator enums
├── HelperTypes.swift             # Common helper types
├── TypeParameters.swift          # Type parameter types (Python 3.12+)
├── Patterns.swift                # Pattern matching types (Python 3.10+)
│
├── Statements/
│   ├── FunctionDef.swift         # Function & async function definitions
│   ├── ClassDef.swift            # Class definition
│   ├── ControlFlow.swift         # if, while, for, break, continue, pass, return
│   ├── Assignments.swift         # assign, aug_assign, ann_assign, delete
│   ├── Imports.swift             # import, import from
│   ├── ExceptionHandling.swift  # raise, try, try-star, assert
│   ├── ContextManagers.swift    # with, async with
│   ├── PatternMatching.swift    # match statement
│   └── Miscellaneous.swift      # global, nonlocal, expr, type alias
│
└── Expressions/
    ├── BinaryOperations.swift    # BoolOp, BinOp, UnaryOp, Compare
    ├── Lambda.swift              # Lambda expressions
    ├── IfExpression.swift        # Conditional expressions
    ├── Collections.swift         # Dict, Set, List, Tuple
    ├── Comprehensions.swift      # List/Set/Dict comprehensions, generators
    ├── AsyncAwaitYield.swift     # await, yield, yield from
    ├── CallAndAccess.swift       # Call, Attribute, Subscript, Slice
    ├── Literals.swift            # Constant, ConstantValue, Name
    ├── FStrings.swift            # FormattedValue, JoinedStr
    └── NamedAndStarred.swift     # NamedExpr, Starred
```

## Organization Principles

### 1. **Core Types** (Root Level)
- `ASTNode.swift` - Base protocol defining location information
- `Module.swift` - Top-level module types
- `Statement.swift` - Statement enum that references all statement types
- `Expression.swift` - Expression enum that references all expression types
- `Operators.swift` - Operator enums (BoolOperator, Operator, UnaryOperator, CmpOp, ExprContext)

### 2. **Statements** (Organized by Category)
- **Function/Class Definitions** - Code organization constructs
- **Control Flow** - Branching and looping
- **Assignments** - Variable binding and modification
- **Imports** - Module importing
- **Exception Handling** - Error handling
- **Context Managers** - Resource management
- **Pattern Matching** - Match statements (Python 3.10+)
- **Miscellaneous** - Other statement types

### 3. **Expressions** (Organized by Purpose)
- **Binary Operations** - Arithmetic, boolean, and comparison operations
- **Lambda** - Anonymous functions
- **Conditional** - Ternary operator
- **Collections** - Data structure literals
- **Comprehensions** - Generator expressions and comprehensions
- **Async/Await** - Asynchronous programming
- **Call and Access** - Function calls, attribute/subscript access
- **Literals** - Constants and names
- **F-Strings** - Formatted string literals
- **Named/Starred** - Special expression types

### 4. **Helper Types** (Supporting Structures)
- `HelperTypes.swift` - Arguments, Keywords, Alias, WithItem, etc.
- `TypeParameters.swift` - Type parameters (Python 3.12+)
- `Patterns.swift` - Pattern matching patterns (Python 3.10+)

## Benefits of This Structure

1. **Maintainability** - Easy to find and modify specific AST node types
2. **Clarity** - Related types are grouped together
3. **Scalability** - Easy to add new types without cluttering a single file
4. **Navigation** - Quick file searching by category
5. **Compile Times** - Swift can compile files in parallel

## Usage

All types are still imported through the main module:

```swift
import PySwiftAST

// All AST types are available
let stmt: Statement = .functionDef(...)
let expr: Expression = .name(...)
```

## File Naming Convention

- **Descriptive names** - Files named by their primary content or category
- **PascalCase** - Following Swift conventions
- **No "Other"** - All files have specific, meaningful names
- **Avoid conflicts** - No duplicate filenames across directories

## Total Files

- **8** core files (root level)
- **9** statement files
- **9** expression files
- **26 files total** (vs. 1 monolithic file)

Average file size: ~30-100 lines (vs. 837 lines in original)
