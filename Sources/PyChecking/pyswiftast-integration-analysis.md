# PySwiftAST Integration Analysis for SwiftyMonacoIDE

## Executive Summary

**Status**: We did **NOT** use the `PyChecker` protocol or `TypeChecker` class from PySwiftAST in our implementation.

Instead, we built a **custom type inference system** specifically for Monaco Editor hover/completion that:
- Uses the raw PySwiftAST module parsing directly
- Implements custom scope-aware variable tracking
- Provides Monaco-specific hover documentation
- Tracks variable chains and reassignments
- Handles class properties and annotations

## What We Built Instead

### Custom Components in SwiftyMonacoIDE

#### 1. **ASTCore** (`Sources/PythonASTCore/ASTCore.swift`)
A JavaScriptKit-free AST analyzer that provides:
- `getVariableType(_ name: String, at lineNumber: Int?) -> String?`
- `getPropertyType(className: String, propertyName: String) -> String?`
- `getClassProperties(at lineNumber: Int) -> [String: String]`
- `getClassContext(lineNumber: Int) -> String?`
- `getClassDefinition(lineNumber: Int) -> ClassInfo?`
- Custom `ScopeChain` for scope-aware variable resolution
- Variable chain tracking (e.g., `a = b = c = 5`)
- Cycle detection in variable chains
- Class-level annotation support (dataclass-style)

#### 2. **TypeInference** (`Sources/MonacoEditorWasm/TypeInference.swift`)
Monaco-specific type inference with:
- String-based inference for simple patterns *(could be in PySwiftAST)*
- AST-based inference with scope awareness *(could be in PySwiftAST)*
- Property inference for `self.property` patterns *(could be in PySwiftAST)*
- Class annotation support *(could be in PySwiftAST)*
- Fallback to pattern matching when AST fails *(could be in PySwiftAST)*
- Monaco hover documentation formatting *(editor-specific, stays in SwiftyMonacoIDE)*

#### 3. **ASTManager** (`Sources/MonacoEditorWasm/ASTManager.swift`)
WASM wrapper that:
- Throttles AST parsing (1000ms delay) *(editor-specific)*
- Integrates with JavaScriptKit *(editor-specific)*
- Tracks performance metrics *(editor-specific)*
- Bridges between Monaco and ASTCore *(editor-specific)*

**Note**: This is purely integration glue code and should NOT be part of PySwiftAST.

## Why PySwiftAST's PyChecker/TypeChecker Wasn't Used

### Architecture Mismatch

| **PySwiftAST TypeChecker** | **SwiftyMonacoIDE Needs** |
|---------------------------|---------------------------|
| Returns `[Diagnostic]` with errors/warnings | Returns `String?` with hover documentation |
| Full module analysis in one pass | Line-specific, on-demand queries |
| Type checking for correctness | Type **inference** for assistance |
| Errors for type mismatches | Best-effort type display |
| Scoped to function bodies | Cross-scope variable tracking |
| No performance metrics | Performance monitoring *(at app level)* |
| No editor integration | Editor hover/completion *(handled by SwiftyMonacoIDE)* |

### Specific Limitations of PyChecker Protocol

1. **API Design**
   ```swift
   // PyChecker only has this:
   func check(_ module: Module) -> [Diagnostic]
   
   // But we need:
   func getVariableType(_ name: String, at lineNumber: Int?) -> String?
   func getPropertyType(className: String, propertyName: String) -> String?
   func getClassProperties(at lineNumber: Int) -> [String: String]
   func getClassContext(lineNumber: Int) -> String?
   ```

2. **No Query API**
   - PyChecker is designed for **batch analysis** (check entire module)
   - We need **interactive queries** (what's the type of this variable at this line?)
   - No methods for "get type at cursor position"

3. **Wrong Return Type**
   - Returns `[Diagnostic]` (error messages)
   - We need formatted hover text with markdown
   - We need `nil` when type is unknown (not an error)

4. **No Scope-Aware Queries**
   - TypeChecker tracks scopes internally but doesn't expose them
   - We need: "What variables are accessible at line 42?"
   - We need: "What's the type of `x` at line 15 vs line 50?"

5. **No Class Context API**
   - No way to ask "What class am I in at line X?"
   - No way to get class properties for autocomplete
   - No support for class-level type annotations (dataclass patterns)

6. **No Documentation Extraction**
   - Doesn't extract or expose docstrings
   - No way to get function/class documentation for IDE tooltips

## What PyChecker/TypeChecker Could Add

### Missing APIs for Interactive Use

To make PyChecker/TypeChecker usable for IDE features, it would need:

```swift
// MARK: - Query APIs (NEW)

extension TypeChecker {
    /// Get the type of a symbol at a specific location
    func getTypeAt(name: String, line: Int, column: Int) -> PythonType?
    
    /// Get all symbols accessible at a specific location
    func getSymbolsAt(line: Int, column: Int) -> [(name: String, type: PythonType)]
    
    /// Get the containing class/function at a location
    func getScopeAt(line: Int, column: Int) -> Scope?
    
    /// Get class properties (for autocomplete)
    func getClassMembers(className: String) -> [Member]
    
    /// Get function signature (for hover/signature help)
    func getFunctionSignature(functionName: String) -> FunctionSignature?
}

// MARK: - Incremental Analysis (NEW)

extension TypeChecker {
    /// Parse and update only changed portions
    mutating func updateCode(changes: [TextChange]) -> [Diagnostic]
    
    /// Get cached diagnostics without re-analyzing
    func getCachedDiagnostics() -> [Diagnostic]
}

// MARK: - Type Formatting (NEW)

extension PythonType {
    /// Format type for display (e.g., "list[str]", "dict[int, str]")
    func toDisplayString() -> String
    
    /// Format type with more detail (e.g., "List of strings", "Dictionary mapping int to str")
    func toDetailedString() -> String
}

// Note: Conversion to editor-specific formats (Markdown, Monaco types, LSP types)
// is the responsibility of the consuming application, NOT PySwiftAST.

// MARK: - Position-based Queries (NEW)

public struct Position: Sendable {
    let line: Int
    let column: Int
}

public struct Range: Sendable {
    let start: Position
    let end: Position
}

public struct Member: Sendable {
    let name: String
    let type: PythonType
    let kind: MemberKind // property, method, classmethod, staticmethod
    let documentation: String?
}

public enum MemberKind: Sendable {
    case property
    case method
    case classMethod
    case staticMethod
    case nestedClass
}

public struct FunctionSignature: Sendable {
    let parameters: [(name: String, type: PythonType?)]
    let returnType: PythonType?
    let documentation: String?
}

public struct Scope: Sendable {
    let kind: ScopeKind
    let name: String?
    let range: Range
}

public enum ScopeKind: Sendable {
    case module
    case function
    case classScope
    case method
}
```

### What Could Be Refactored into TypeChecker

From our custom implementation, these could be upstreamed to PySwiftAST:

#### 1. **Scope Chain Resolution**
Our `ScopeChain` struct in ASTCore:
```swift
struct ScopeChain {
    let localStatements: [Statement]
    let classStatements: [Statement]?
    let globalStatements: [Statement]
    let lineNumber: Int?
    
    func findVariable(_ name: String) -> String?
}
```

**Recommendation**: Add to `TypeEnvironment` in TypeChecker with public query API.

#### 2. **Variable Chain Tracking**
Our support for `a = b = c = 5`:
```swift
// Tracks chains like: total_revenue += amount
// Or: x = y = z = 10
func findVariableInChain(_ name: String, statements: [Statement]) -> String?
```

**Recommendation**: Add to TypeChecker's `checkAssign()` method.

#### 3. **Class-Level Annotation Support**
Our support for dataclass-style annotations:
```swift
class Order:
    order_id: int
    customer_name: str
    items: list
```

**Recommendation**: Enhance TypeChecker's `checkAnnAssign()` to track class-level annotations.

#### 4. **Expression Type Description**
Our `describeExpression()` that handles:
- Subscript types: `list[str]`, `dict[int, str]`
- Constant inference: `"text"` → `str`, `42` → `int`
- Complex generics: `dict[str, list[int]]`

**Recommendation**: Add to TypeChecker as `PythonType.fromExpression()`.

#### 5. **Class Context Detection**
Our `getClassContext(lineNumber:)` and `getClassDefinition(lineNumber:)`:
```swift
// Returns: "Database" when at line 45 inside Database class
func getClassContext(lineNumber: Int) -> String?

// Returns: ClassInfo with name and full code
func getClassDefinition(lineNumber: Int) -> ClassInfo?
```

**Recommendation**: Add to TypeChecker as position-based queries.

#### 6. **Statement End Line Calculation**
Our `getStatementEndLine()` that handles:
- Function bodies (last statement in body)
- Class bodies (last statement in class)
- Fallback to large number (999999) for unknown types

**Recommendation**: Add to PySwiftAST core as `Statement.endLine` property.

### Additional Refactoring Opportunities

#### 7. **Modernize TypeChecker to Use PyAstVisitors**

**Context**: TypeChecker was written before PyAstVisitors existed. It currently does manual pattern matching on statements.

**Current TypeChecker Pattern** (manual recursion):
```swift
private mutating func checkStatement(_ stmt: Statement) -> [Diagnostic] {
    var diagnostics: [Diagnostic] = []
    
    switch stmt {
    case .assign(let assign):
        diagnostics.append(contentsOf: checkAssign(assign))
    case .annAssign(let annAssign):
        diagnostics.append(contentsOf: checkAnnAssign(annAssign))
    case .functionDef(let funcDef):
        diagnostics.append(contentsOf: checkFunctionDef(funcDef))
    // ... manual cases for each statement type
    default:
        break
    }
    
    return diagnostics
}
```

**Recommended: Use PyAstVisitors** (declarative pattern):
```swift
import PyAstVisitors

public struct TypeChecker: PyChecker {
    private var diagnostics: [Diagnostic] = []
    private var typeEnvironment: TypeEnvironment
    
    public func check(_ module: Module) -> [Diagnostic] {
        var checker = TypeCheckingVisitor(typeEnvironment: TypeEnvironment())
        checker.visit(module)
        return checker.diagnostics
    }
}

private struct TypeCheckingVisitor: StatementVisitor, ExpressionVisitor {
    var diagnostics: [Diagnostic] = []
    var typeEnvironment: TypeEnvironment
    
    // Automatically called for each statement type
    mutating func visit(_ assign: Assign) {
        let valueType = inferType(assign.value)
        for target in assign.targets {
            if case .name(let name) = target {
                if let existingType = typeEnvironment.getType(name.id) {
                    if !existingType.isCompatible(with: valueType) {
                        diagnostics.append(.error(
                            checkerId: "type-checker",
                            message: "Type mismatch: cannot assign \(valueType) to \(name.id) of type \(existingType)",
                            line: assign.lineno,
                            column: assign.colOffset
                        ))
                    }
                } else {
                    typeEnvironment.setType(name.id, type: valueType)
                }
            }
        }
    }
    
    mutating func visit(_ annAssign: AnnAssign) {
        let annotatedType = TypeAnnotationParser.parse(annAssign.annotation)
        if case .name(let name) = annAssign.target {
            typeEnvironment.setType(name.id, type: annotatedType)
            if let value = annAssign.value {
                let valueType = inferType(value)
                if !annotatedType.isCompatible(with: valueType) {
                    diagnostics.append(.error(
                        checkerId: "type-checker",
                        message: "Type mismatch: cannot assign \(valueType) to \(name.id): \(annotatedType)",
                        line: annAssign.lineno,
                        column: annAssign.colOffset
                    ))
                }
            }
        }
    }
    
    mutating func visit(_ functionDef: FunctionDef) {
        typeEnvironment.pushScope()
        
        for arg in functionDef.args.args {
            if let annotation = arg.annotation {
                let paramType = TypeAnnotationParser.parse(annotation)
                typeEnvironment.setType(arg.arg, type: paramType)
            }
        }
        
        let expectedReturn = functionDef.returns.map { TypeAnnotationParser.parse($0) }
        typeEnvironment.setReturnType(expectedReturn)
        
        // Visit function body statements automatically
        for statement in functionDef.body {
            visit(statement)
        }
        
        typeEnvironment.popScope()
    }
    
    // ... other visitor methods for different statement types
}
```

**Benefits of Using PyAstVisitors**:
1. **Cleaner Code**: No manual switch statements, no recursive traversal code
2. **Automatic Traversal**: Visitor pattern handles walking the AST tree
3. **Separation of Concerns**: Each statement type gets its own method
4. **Extensibility**: Easy to add new checks without modifying traversal logic
5. **Consistency**: Same pattern used throughout PySwiftAST ecosystem
6. **Less Boilerplate**: Don't need to manually handle nested structures

**Recommendation**: Refactor TypeChecker to use `StatementVisitor` and `ExpressionVisitor` from PyAstVisitors package.

#### 8. **CRITICAL: Upstream PythonASTCore Analysis Logic to TypeChecker**

**The Real Goal**: Stop duplicating analysis. TypeChecker should do the heavy lifting, SwiftyMonacoIDE should just consume the results.

**Current Problem**:
- We built `PythonASTCore/ASTCore.swift` with ~800 lines of analysis logic
- TypeChecker in PySwiftAST has similar logic but doesn't expose it for IDE use
- We're doing analysis TWICE: once for type checking, again for hover/completion
- This is wasteful and creates maintenance burden

**What PythonASTCore Contains That TypeChecker Should Have**:

1. **Scope-Aware Variable Resolution** (`ScopeChain`, `findScopeChain`)
   - Tracks local, class, and global scopes
   - Resolves variable types based on line number
   - Handles variable shadowing correctly
   ```swift
   // This entire logic should be in TypeChecker.getTypeAt()
   func getVariableType(_ name: String, at lineNumber: Int?) -> String?
   ```

2. **Variable Chain Tracking** (`findVariableInChain`)
   - Handles `a = b = c = 5`
   - Follows reassignments: `x = y; y = 10`
   - Detects cycles: `a = b; b = a`
   ```swift
   // TypeChecker should track this during checkAssign()
   ```

3. **Class Property Resolution** (`getPropertyType`, `searchPropertyInStatements`)
   - Finds properties in `__init__` assignments
   - Tracks class-level annotations
   - Handles `self.property` patterns
   ```swift
   // TypeChecker should expose this via getClassMembers()
   ```

4. **Class Context Detection** (`getClassContext`, `findClassContainingLine`)
   - Determines which class you're inside at a given line
   - Returns class definition with code
   ```swift
   // TypeChecker should expose via getScopeAt()
   ```

5. **Expression Type Description** (`describeExpression`, `describeSubscriptSlice`)
   - Handles subscript types: `list[str]`, `dict[int, str]`
   - Infers constant types: `"text"` → `str`, `42` → `int`
   - Complex generics: `dict[str, list[int]]`
   ```swift
   // TypeChecker already has inferType(), should expose it as PythonType.fromExpression()
   ```

6. **Statement End Line Calculation** (`getStatementEndLine`)
   - Critical for determining scope boundaries
   - Handles all statement types with fallback
   ```swift
   // Should be Statement.endLine property in PySwiftAST core
   ```

**Proposed Architecture After Refactoring**:

```swift
// IN PySwiftAST - TypeChecker does ALL the analysis
public struct TypeChecker: PyChecker {
    private var visitor: TypeCheckingVisitor
    
    public func check(_ module: Module) -> [Diagnostic] {
        visitor.visit(module)
        return visitor.diagnostics
    }
    
    // NEW: Query APIs that expose analysis results
    public func getTypeAt(name: String, line: Int, column: Int) -> PythonType? {
        return visitor.typeEnvironment.getType(name, at: line)
    }
    
    public func getSymbolsAt(line: Int, column: Int) -> [(name: String, type: PythonType)] {
        return visitor.typeEnvironment.getAllSymbolsInScope(at: line)
    }
    
    public func getClassMembers(className: String) -> [Member] {
        return visitor.classRegistry.getMembers(className)
    }
    
    public func getScopeAt(line: Int, column: Int) -> Scope? {
        return visitor.scopeTracker.getScopeAt(line: line)
    }
}

private struct TypeCheckingVisitor: StatementVisitor {
    var typeEnvironment: TypeEnvironment  // Enhanced with our ScopeChain logic
    var classRegistry: ClassRegistry      // Tracks all classes and their members
    var scopeTracker: ScopeTracker        // Tracks scope boundaries (our findClassContainingLine)
    
    // All our analysis logic moves here
}

// IN SwiftyMonacoIDE - Just query TypeChecker for results
class ASTManager {
    private var typeChecker: TypeChecker?
    
    func parseCode(_ code: String) {
        let module = try parsePython(code)
        var checker = TypeChecker()
        _ = checker.check(module)  // Run analysis once
        self.typeChecker = checker  // Cache for queries
    }
    
    func getVariableType(_ name: String, at lineNumber: Int) -> String? {
        guard let checker = typeChecker else { return nil }
        
        // Just query - no analysis!
        if let pythonType = checker.getTypeAt(name: name, line: lineNumber, column: 0) {
            return formatTypeForHover(pythonType)  // Format for Monaco
        }
        return nil
    }
    
    func getClassProperties(at lineNumber: Int) -> [String: String] {
        guard let checker = typeChecker,
              let scope = checker.getScopeAt(line: lineNumber, column: 0),
              case .classScope = scope.kind,
              let className = scope.name else {
            return [:]
        }
        
        // Just query - no analysis!
        let members = checker.getClassMembers(className: className)
        return Dictionary(uniqueKeysWithValues: members.map { 
            ($0.name, formatType($0.type))
        })
    }
}
```

**What Gets Eliminated from SwiftyMonacoIDE**:
- ❌ ~800 lines of `PythonASTCore/ASTCore.swift` analysis logic
- ❌ `ScopeChain` struct (moves to TypeChecker's TypeEnvironment)
- ❌ `findScopeChain()`, `findVariableInChain()` (moves to TypeChecker)
- ❌ `getClassContext()`, `findClassContainingLine()` (moves to TypeChecker)
- ❌ `describeExpression()`, `inferSimpleType()` (already in TypeChecker)
- ❌ All the manual AST traversal code

**What Remains in SwiftyMonacoIDE**:
- ✅ `ASTManager` - thin wrapper around TypeChecker
- ✅ `TypeInference` - formats PythonType for Monaco markdown
- ✅ Monaco hover/completion providers
- ✅ JavaScriptKit/WASM bindings
- ✅ Performance monitoring
- ✅ String literal detection

**Benefits**:
1. **No Duplicate Analysis**: TypeChecker does it once, queries are fast lookups
2. **Consistency**: One source of truth for types
3. **Maintainability**: Analysis logic in one place (PySwiftAST)
4. **Reusability**: Other IDEs can use the same TypeChecker
5. **Testability**: Analysis logic tested in PySwiftAST, Monaco integration tested separately
6. **Performance**: Analysis done once per parse, queries are O(1) lookups

**This Is The Key Insight**: 
Don't build a parallel analysis system in SwiftyMonacoIDE. 
Enhance TypeChecker to expose its analysis results, then just query it.

## Recommendations for PySwiftAST

### Critical Realization

**The PythonASTCore code we wrote (~800 lines) should NOT exist as separate code.**

All the analysis logic (scope resolution, variable tracking, class detection, expression typing) should be **inside TypeChecker**, not duplicated in consuming applications. TypeChecker should:
1. **Analyze once** during `check(module)`
2. **Cache results** in internal registries (TypeEnvironment, ClassRegistry, ScopeTracker)
3. **Expose queries** to retrieve analysis results without re-analyzing

This way, SwiftyMonacoIDE (and any other IDE) just calls TypeChecker queries instead of reimplementing analysis.

### Immediate Priority (Foundation)

0. **Modernize TypeChecker to Use PyAstVisitors**
   - Replace manual switch/case pattern matching with visitor pattern
   - Leverage `StatementVisitor` and `ExpressionVisitor` protocols
   - Cleaner, more maintainable code
   - **This should be done FIRST** as it's internal refactoring that doesn't change the API

### Short Term (High Value, Low Effort)

1. **Add Position-based Query API** 🔥 *CRITICAL*
   - `getTypeAt(name:line:column:)` - expose TypeEnvironment lookups
   - `getSymbolsAt(line:column:)` - expose scope contents
   - `getScopeAt(line:column:)` - expose scope tracking
   - **Impact**: Eliminates need for PythonASTCore's scope analysis code

2. **Add Type Formatting**
   - `PythonType.toDisplayString()` for simple display
   - `PythonType.toDetailedString()` for verbose descriptions
   - Handle complex generics readably
   - *(Editor-specific markdown/HTML formatting stays in consuming app)*

3. **Export Type Environment** 🔥 *CRITICAL*
   - Make `TypeEnvironment` public with query methods
   - Add `getCurrentScope()` method
   - Add `getAllSymbolsInScope(at:)` method
   - **Impact**: Eliminates need for PythonASTCore's ScopeChain struct

### Medium Term (IDE Integration)

4. **Add Class Member Queries** 🔥 *CRITICAL*
   - `getClassMembers(className:)` → properties, methods
   - `getClassDefinition(at:)` → ClassDef + location
   - Support for `@dataclass`, `@property`, etc.
   - **Impact**: Eliminates need for PythonASTCore's class property resolution code

5. **Add Function Signature Queries**
   - `getFunctionSignature(name:)` → params + return type
   - Support for overloads (if Python typing supports it)
   - Documentation extraction from docstrings

6. **Incremental Parsing Support**
   - `updateRange(change:)` for partial re-analysis
   - Caching of type information
   - Invalidation only for affected scopes

### Long Term (Performance & Polish)

7. **Performance Metrics** *(Optional)*
   - Timing for parse/check phases
   - Complexity warnings for large files
   - Note: Throttling/debouncing is consumer responsibility

8. **Advanced Type Features**
   - Union types: `str | int | None`
   - Generic class inference: `List[Product]`
   - Protocol/structural typing
   - Type narrowing in conditionals

## Migration Path

If PySwiftAST adds these APIs, SwiftyMonacoIDE could migrate:

### Phase 1: Query API *(Eliminates ~400 lines)*
Replace our custom `ASTCore.getVariableType()` with `TypeChecker.getTypeAt()`.
Replace our custom `ScopeChain` with TypeChecker's TypeEnvironment queries.

### Phase 2: Class Support *(Eliminates ~300 lines)*
Replace our custom class detection with `TypeChecker.getClassMembers()`.
Replace our custom `getClassContext()` with `TypeChecker.getScopeAt()`.

### Phase 3: Full Integration *(Eliminates ~800 lines total)*
Delete `PythonASTCore/ASTCore.swift` entirely.
Use TypeChecker as single source of truth.
Keep only Monaco-specific formatting in SwiftyMonacoIDE.

### What Would Remain Custom (in SwiftyMonacoIDE)
- Monaco-specific hover formatting (markdown templates)
- Monaco CompletionItem/Marker conversions
- Performance monitoring UI (CPU usage display)
- JavaScriptKit integration (WASM bindings)
- String literal detection for hover
- Keyword documentation
- Throttling/debouncing of parse calls

**Important**: PySwiftAST should remain **editor-agnostic**. All Monaco/JavaScriptKit integration stays in SwiftyMonacoIDE.

## Summary

**Current State**:
- ✅ We have a **working** type inference system
- ✅ Handles scope, classes, properties, annotations
- ✅ Integrated with Monaco hover/completion
- ✅ All 65 tests passing
- ❌ Not using PySwiftAST's PyChecker/TypeChecker

**Gap Analysis**:
- PyChecker protocol: **Too batch-oriented**, no query API
- TypeChecker class: **Right idea**, wrong interface for IDE use
- Missing: Position-based queries, member lookup, scope inspection

**Recommendation**:
1. **First**: Refactor TypeChecker to use PyAstVisitors (internal improvement)
2. **Second**: Add query APIs to expose TypeChecker's analysis results (NEW PUBLIC API)
3. **Third**: Upstream our PythonASTCore analysis logic into TypeChecker internals
4. **Then**: SwiftyMonacoIDE migrates to use TypeChecker queries, deletes PythonASTCore
5. Keep Monaco-specific formatting code in SwiftyMonacoIDE

**The Goal**: TypeChecker becomes a **queryable type analysis engine**, not just a diagnostic tool.

**Key Insight**:
PyChecker/TypeChecker is designed for **static analysis** (find bugs).
We need **language server protocol** features (provide assistance).
These are related but different use cases requiring different APIs.

**Most Important Insight**:
Don't duplicate analysis in consuming applications.
TypeChecker should analyze once and expose results via queries.
This makes it usable for IDEs without requiring custom analysis code.

**Important Separation of Concerns**:
- **PySwiftAST**: Pure Python AST parsing and type analysis (editor-agnostic)
- **SwiftyMonacoIDE**: Editor integration, Monaco API, JavaScriptKit, WASM, UI formatting
- PySwiftAST should NEVER depend on or know about Monaco, JavaScriptKit, or any specific editor
