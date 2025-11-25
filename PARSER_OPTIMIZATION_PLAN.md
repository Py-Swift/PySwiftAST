# Parser Optimization Opportunities

## Current State
- **Parser time**: ~1.3ms (21% of total pipeline)
- **Performance**: 1.09x faster than Python (Target: 2.0x)
- **Bottleneck**: Parser is now the main bottleneck after UTF-8 tokenizer optimization

## Identified Optimization Opportunities

### 1. **Inline Hot Path Functions** ⚡ (HIGH IMPACT)

Current hot functions called thousands of times:
```swift
private func currentToken() -> Token
private func advance()
private func isAtEnd() -> Bool
private func skipComments()
```

**Optimization:**
```swift
@inline(__always)
private func currentToken() -> Token {
    // Bounds check is compiler-optimized when inlined
    guard position < tokens.count else {
        return Token(type: .endmarker, value: "", line: 0, column: 0, endLine: 0, endColumn: 0)
    }
    return tokens[position]
}

@inline(__always)
private func advance() {
    if position < tokens.count {
        position += 1
    }
}

@inline(__always)
private func isAtEnd() -> Bool {
    return position >= tokens.count || tokens[position].type == .endmarker
}
```

**Expected Impact**: 5-10% improvement (reduces function call overhead in tight loops)

---

### 2. **Remove Redundant currentToken() Calls** 🔄 (MEDIUM IMPACT)

**Problem**: Many functions call `currentToken()` multiple times unnecessarily

Example from parseStatement():
```swift
private func parseStatement() throws -> Statement {
    let token = currentToken()  // Call 1
    
    switch token.type {
    case .pass:
        let line = token.line
        let col = token.column
        advance()
        consumeNewlineOrSemicolon()  // This calls currentToken() again!
        return .pass(...)
```

**Optimization**: Cache token at start of function
```swift
private func parseStatement() throws -> Statement {
    let token = currentToken()
    let tokenType = token.type  // Cache type for switch
    
    switch tokenType {
    case .pass:
        advance()
        // Pass cached token info if needed
        ...
```

**Expected Impact**: 3-5% improvement

---

### 3. **Array Pre-allocation** 📦 (MEDIUM IMPACT)

**Problem**: Many arrays grow dynamically without capacity hints

Current code:
```swift
private func parseStatements() throws -> [Statement] {
    var statements: [Statement] = []  // No capacity hint!
    
    while !isAtEnd() && currentToken().type != .endmarker {
        let stmt = try parseStatement()
        statements.append(stmt)
    }
    return statements
}
```

**Optimization**: Pre-allocate based on token count estimate
```swift
private func parseStatements() throws -> [Statement] {
    // Estimate: ~1 statement per 5-10 tokens
    let estimatedCount = max(10, tokens.count / 7)
    var statements: [Statement] = []
    statements.reserveCapacity(estimatedCount)
    
    while !isAtEnd() && currentToken().type != .endmarker {
        let stmt = try parseStatement()
        statements.append(stmt)
    }
    return statements
}
```

Apply to:
- `parseStatements()` - statement arrays
- `parseArguments()` - argument lists  
- `parseTuple()` - element lists
- `parseList()` - element arrays
- `parseDict()` - key/value pairs

**Expected Impact**: 5-8% improvement (reduces reallocation overhead)

---

### 4. **Reduce AST Node Allocation Overhead** 🏗️ (HIGH IMPACT)

**Problem**: Every node creates multiple nested structs

Example:
```swift
return .pass(Pass(lineno: line, colOffset: col, endLineno: line, endColOffset: col))
//           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//           Heap allocation for Pass struct + Statement enum wrapper
```

**Optimization Ideas**:

a) **Use value types more efficiently** (already using structs, good!)

b) **Pool common location info**:
```swift
// Instead of duplicating location in every node
struct SourceLocation {
    let line: Int
    let col: Int
    let endLine: Int
    let endCol: Int
}

// Reuse when possible
private var lastLocation: SourceLocation?

private func captureLocation() -> SourceLocation {
    let token = currentToken()
    return SourceLocation(line: token.line, col: token.column, 
                         endLine: token.endLine, endCol: token.endColumn)
}
```

c) **Lazy initialization for optional fields**:
```swift
// Current: Always allocates optional arrays
struct FunctionDef {
    var decorators: [Expression] = []  // Always allocated
    var typeParams: [TypeParam]? = nil
}

// Better: Use nil for empty arrays
struct FunctionDef {
    var decorators: [Expression]?  // nil when empty
    var typeParams: [TypeParam]?
}
```

**Expected Impact**: 10-15% improvement (reduces memory pressure and allocations)

---

### 5. **Fast Path for Common Patterns** 🚀 (HIGH IMPACT)

**Problem**: Expressions are parsed generically, even simple ones

**Optimization**: Add fast paths for common patterns:
```swift
private func parseExpression() throws -> Expression {
    // FAST PATH: Check for common single-token expressions
    let token = currentToken()
    
    switch token.type {
    case .name(let id):
        // Common case: bare identifier
        let next = peekNext()
        if next.type == .newline || next.type == .semicolon || next.type == .comma {
            advance()
            return .name(Name(id: id, ctx: .load, 
                             lineno: token.line, colOffset: token.column,
                             endLineno: token.endLine, endColOffset: token.endColumn))
        }
        
    case .number(let n):
        // Common case: numeric literal
        let next = peekNext()
        if next.type == .newline || next.type == .semicolon || next.type == .comma {
            advance()
            return .constant(Constant(value: .number(n), ...))
        }
        
    default:
        break
    }
    
    // SLOW PATH: Full expression parsing
    return try parseFullExpression()
}
```

**Expected Impact**: 15-20% improvement (most expressions are simple)

---

### 6. **Specialize Token Type Checks** 🎯 (MEDIUM IMPACT)

**Problem**: Token type enum comparisons involve associated values

Current:
```swift
if currentToken().type == .newline {  // Enum comparison
    advance()
}
```

**Optimization**: Add helper for common checks
```swift
@inline(__always)
private func isNewline() -> Bool {
    if case .newline = currentToken().type { return true }
    return false
}

@inline(__always)
private func isName() -> Bool {
    if case .name = currentToken().type { return true }
    return false
}
```

**Expected Impact**: 2-3% improvement

---

### 7. **Reduce Switch Statement Overhead** 🔀 (LOW-MEDIUM IMPACT)

**Problem**: Large switch statements in parseStatement() and parseExpression()

**Optimization**: Use lookup table for keyword dispatch:
```swift
// Build at initialization
private lazy var statementParsers: [TokenType: () throws -> Statement] = [
    .pass: parsePass,
    .return: parseReturn,
    .break: parseBreak,
    // ... etc
]

private func parseStatement() throws -> Statement {
    let tokenType = currentToken().type
    
    // Fast lookup instead of switch
    if let parser = statementParsers[tokenType] {
        return try parser()
    }
    
    // Fall through to expression statement
    return try parseExpressionStatement()
}
```

**Expected Impact**: 3-5% improvement (reduces branch mispredictions)

---

### 8. **Token Stream Preprocessing** 🔧 (EXPERIMENTAL)

**Problem**: Parser repeatedly skips comments/newlines

**Optimization**: Pre-filter token stream:
```swift
public init(tokens: [Token]) {
    // Filter out comments at initialization
    self.tokens = tokens.filter { token in
        if case .comment = token.type { return false }
        // Keep type comments though
        return true
    }
    self.position = 0
}
```

**Trade-off**: 
- ✅ Faster parsing (no comment skipping in loops)
- ❌ Loses comment positions (might need comments for AST)

**Expected Impact**: 5-8% improvement IF comments aren't needed in AST

---

### 9. **Use UnsafePointer for Token Array** ⚠️ (ADVANCED, HIGH RISK)

**Problem**: Array bounds checking on every access

**Optimization**:
```swift
private let tokens: [Token]
private let tokensPtr: UnsafeBufferPointer<Token>
private var position: Int = 0

public init(tokens: [Token]) {
    self.tokens = tokens
    self.tokensPtr = UnsafeBufferPointer(start: tokens.withUnsafeBufferPointer { $0.baseAddress! },
                                          count: tokens.count)
}

@inline(__always)
private func currentToken() -> Token {
    return tokensPtr[position]  // No bounds check
}
```

**Expected Impact**: 5-10% improvement
**Risk**: HIGH - Undefined behavior if used incorrectly

---

### 10. **Benchmark-Driven Optimization** 📊 (META)

**Process**:
1. Profile parser with Instruments
2. Find hottest functions (likely parseExpression, parseAtom, etc.)
3. Apply micro-optimizations to hot paths only
4. Measure each change

**Tools**:
```bash
# Profile with Instruments
instruments -t "Time Profiler" .build/release/pyswift-benchmark file.py 100 parse

# Or use swift's built-in profiling
swift build -c release -Xswiftc -profile-generate
# Run benchmark
swift build -c release -Xswiftc -profile-use=...
```

---

## Recommended Implementation Order

### Phase 1: Low-Hanging Fruit (Expected: 15-20% improvement)
1. ✅ Inline hot path functions (`@inline(__always)`)
2. ✅ Array pre-allocation (easy, safe)
3. ✅ Remove redundant currentToken() calls

**Expected Result**: 1.09x → 1.30x vs Python

---

### Phase 2: Structural Improvements (Expected: 15-25% improvement)  
4. ✅ Fast paths for common expressions
5. ✅ Specialize token type checks
6. ✅ Reduce AST allocation overhead

**Expected Result**: 1.30x → 1.55x vs Python

---

### Phase 3: Advanced Optimizations (Expected: 10-15% improvement)
7. ✅ Benchmark-driven profiling
8. ✅ Consider token stream preprocessing (if safe)
9. ⚠️ Switch lookup tables (measure first!)
10. ⚠️ UnsafePointer (only if desperate!)

**Expected Result**: 1.55x → 1.75x vs Python (possibly 2.0x with profile-guided optimization)

---

## Implementation Strategy

Following `.clinerules`:
1. ✅ Establish current baseline (1.09x)
2. ✅ Pick ONE optimization
3. ✅ Implement it
4. ✅ Run all 81 tests
5. ✅ Benchmark (compare to baseline)
6. ✅ If improvement < 2%, REVERT
7. ✅ If improvement ≥ 2%, KEEP and document
8. ✅ Repeat with next optimization

---

## Code Examples

### Example 1: Inline hot paths
```swift
// BEFORE:
private func currentToken() -> Token {
    guard position < tokens.count else {
        return Token(type: .endmarker, value: "", line: 0, column: 0, endLine: 0, endColumn: 0)
    }
    return tokens[position]
}

// AFTER:
@inline(__always)
private func currentToken() -> Token {
    guard position < tokens.count else {
        return Token(type: .endmarker, value: "", line: 0, column: 0, endLine: 0, endColumn: 0)
    }
    return tokens[position]
}
```

### Example 2: Array pre-allocation
```swift
// BEFORE:
var statements: [Statement] = []

// AFTER:
var statements: [Statement] = []
statements.reserveCapacity(max(10, tokens.count / 7))
```

### Example 3: Fast path for simple expressions
```swift
// BEFORE: Always goes through full expression parsing

// AFTER:
private func parseExpression() throws -> Expression {
    // Fast path: simple name/number/string
    let token = currentToken()
    switch token.type {
    case .name(let id) where peekNext().type.isTerminator():
        advance()
        return .name(Name(id: id, ctx: .load, ...))
    default:
        return try parseFullExpression()
    }
}
```

---

## Measurement Plan

For each optimization:
```bash
# Baseline
swift test --filter testParsingPerformance

# After change
swift test --filter testParsingPerformance

# Compare
python3 benchmark_vs_python.py
```

Track in performance_history.json:
- Parsing time before/after
- Speedup vs Python
- Test results (must be 81/81)
- Memory usage (if significant)

---

## Expected Final Results

With all Phase 1 & 2 optimizations:
- **Current**: 1.09x faster than Python
- **Target**: 2.0x faster than Python
- **Realistic**: 1.5-1.8x faster than Python
- **Optimistic**: 1.8-2.0x with profile-guided optimization

**Conclusion**: Parser has significant optimization potential. The UTF-8 tokenizer removed the #1 bottleneck, now it's time to optimize the parser itself!
