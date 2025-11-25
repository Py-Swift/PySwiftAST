# Swift Algorithms Usage in PySwiftAST

This document describes how to use swift-algorithms methods for optimizing PySwiftAST.

## Installation Status

✅ **Installed**: swift-algorithms 1.2.0+
✅ **Available in**: PySwiftAST, PySwiftCodeGen targets
✅ **Tests**: All 80 tests passing

## Import Statement

```swift
import Algorithms
```

## Useful Methods for Parser Optimization

### 1. `windows(ofCount:)` - Token Lookahead

**Use case**: Peek at next N tokens without consuming them

```swift
// Example: Check if next 3 tokens form a pattern
let tokens = tokenizer.tokenize()
for window in tokens.windows(ofCount: 3) {
    if window[0].type == .name && 
       window[1].type == .leftParen && 
       window[2].type == .rightParen {
        // Found pattern: name()
    }
}
```

**Benefit**: O(1) access to sliding windows, no need to manually track indices

### 2. `chunked(by:)` - Group Similar Tokens

**Use case**: Group consecutive tokens by type or property

```swift
// Example: Split tokens into logical groups
let tokenGroups = tokens.chunked(by: { prev, curr in
    prev.line == curr.line  // Group tokens on same line
})

for group in tokenGroups {
    // Process each line's tokens together
}
```

**Benefit**: Automatic grouping with lazy evaluation

### 3. `adjacentPairs()` - Compare Consecutive Elements

**Use case**: Check relationships between adjacent tokens

```swift
// Example: Find operator precedence issues
for (left, right) in tokens.adjacentPairs() {
    if left.type == .operator && right.type == .operator {
        // Handle consecutive operators
    }
}
```

**Benefit**: Cleaner than manual index arithmetic

### 4. `indexed()` - Maintain Real Indices

**Use case**: Keep track of actual collection indices (better than `enumerated()`)

```swift
// Example: Process tokens with their actual positions
for (index, token) in tokens.indexed() {
    // index is the actual collection index, not just a counter
    if needsContext {
        let prev = tokens[tokens.index(before: index)]
    }
}
```

**Benefit**: Real indices, not just 0-based counters

### 5. `striding(by:)` - Skip Elements Efficiently

**Use case**: Process every Nth element

```swift
// Example: Sample tokens for profiling
let sampleTokens = tokens.striding(by: 10)  // Every 10th token
```

**Benefit**: Lazy evaluation, doesn't create intermediate arrays

## Potential Optimization Targets

### Parser Hot Paths

1. **Expression precedence chain** (`parseExpression()` → `parseTerm()` → `parseFactor()`)
   - Use `windows()` for multi-token lookahead
   - Use `adjacentPairs()` for operator precedence

2. **Statement parsing** (complex statements with multiple clauses)
   - Use `chunked(by:)` to group statement parts
   - Use `indexed()` to maintain position context

3. **AST traversal** (visitors, transformers)
   - Use `striding(by:)` for sampling during profiling
   - Use `adjacentPairs()` for parent-child relationships

### Code Generation

1. **Indentation tracking**
   - Use `reductions()` to track cumulative indentation
   - Use `chunked(on:)` to group by indentation level

2. **Line joining**
   - Use `joined(by:)` for efficient string building
   - Use `interspersed(with:)` for separators

## Performance Considerations

### ✅ When to Use

- **Lazy evaluation needed**: All algorithms support lazy evaluation
- **Complex iteration patterns**: Cleaner than manual index management
- **Functional style**: More declarative code

### ⚠️ When to Avoid

- **Simple iteration**: Don't add complexity for basic loops
- **Hot paths with proven performance**: Profile first!
- **Character-level operations**: Won't help with String.Index O(n) issue

## Current Bottlenecks (Don't Use Algorithms Here)

1. **Tokenization** (88ms) - String.Index O(n) operations
   - Need: UTF8 view or character array conversion
   - Algorithms won't help: Problem is at Swift String level

2. **Token array allocation** - Initial tokenization
   - Need: Pre-sized array or buffer reuse
   - Algorithms won't help: Allocation happens before iteration

## Example Optimization Pattern

```swift
// BEFORE: Manual iteration with index tracking
var i = 0
while i < tokens.count - 2 {
    if tokens[i].type == .keyword && 
       tokens[i+1].type == .name &&
       tokens[i+2].type == .colon {
        // Process pattern
    }
    i += 1
}

// AFTER: Using windows()
for window in tokens.windows(ofCount: 3) {
    if window[0].type == .keyword && 
       window[1].type == .name &&
       window[2].type == .colon {
        // Process pattern - cleaner, less error-prone
    }
}
```

## Measurement Guidelines

Before using algorithms in hot paths:

1. **Profile first**: Use Instruments to identify actual bottleneck
2. **Baseline**: Measure current performance
3. **Apply**: Use algorithm method
4. **Measure**: Check if improvement is >5%
5. **Keep or revert**: Follow OPTIMIZATION_GUIDELINES.md

## Links

- [Swift Algorithms Documentation](https://swiftpackageindex.com/apple/swift-algorithms/documentation/algorithms)
- [GitHub Repository](https://github.com/apple/swift-algorithms)
- [API Proposals](https://github.com/apple/swift-algorithms/tree/main/Guides)

## Status

- **Current**: Library integrated, ready to use
- **Next**: Profile parser to find actual hotspots
- **Goal**: 2.0x parsing speedup, 1.5x round-trip speedup
