# Performance Optimization Guidelines

## 📋 Overview

This document provides a systematic approach to optimizing PySwiftAST's parser and code generator. Follow these guidelines for every optimization iteration to ensure improvements are measurable, safe, and tracked.

## 🎯 Optimization Goals

- **Primary**: Achieve 2.0x+ speedup over Python's ast.parse() (currently 1.35x)
- **Secondary**: Achieve 1.5x+ speedup on round-trip (currently 1.04x)
- **Constraint**: Never regress - each change must improve or maintain performance

## ✅ Pre-Optimization Checklist

Before making ANY optimization changes:

1. **[ ] Establish baseline** - Run performance tests and record current metrics
2. **[ ] Update tracking** - Log baseline in `performance_history.json`
3. **[ ] Grammar check** - Review `Grammar/python.gram` for the feature being optimized
4. **[ ] Identify target** - Profile to find actual hotspots (don't guess!)

## 🔄 Optimization Workflow

### Step 1: Establish Baseline

```bash
# Run performance tests in release mode
swift test -c release --filter PerformanceTests 2>&1 | tee optimization_log.txt

# Extract key metrics and save to performance_history.json
```

Record:
- Parsing median time
- Round-trip median time
- Tokenization time
- Code generation time
- Date/time of measurement
- Git commit hash

### Step 2: Grammar Verification

**ALWAYS** reference `Grammar/python.gram` before changing parser logic:

```bash
# Open grammar file
open Grammar/python.gram

# Search for relevant rules
grep -n "keyword_pattern" Grammar/python.gram
```

**Key principle**: Our parser implementation MUST match Python 3.13's grammar. Any deviation is a bug, not an optimization opportunity.

### Step 3: Profile and Identify Hotspots

```bash
# Build for profiling
swift build -c release

# Profile with Instruments (Time Profiler)
instruments -t "Time Profiler" .build/release/pyswift-benchmark \
  Tests/PySwiftASTTests/Resources/test_files/django_query.py 100 parse

# Or use sampling profiler
sample pyswift-benchmark 5 -f profiling_output.txt
```

Focus on:
- Functions with highest self-time
- Functions called most frequently
- Memory allocations in hot paths
- Unexpected overhead (ARC, protocol dispatch, etc.)

### Step 4: Make Targeted Changes

**ONE OPTIMIZATION AT A TIME**

Good example:
```
✅ Optimize parseExpression() to reduce bounds checking
```

Bad example:
```
❌ Optimize parseExpression(), parseStatement(), and tokenization
```

Keep changes:
- **Small** - Easy to review and understand
- **Focused** - One optimization per commit
- **Measurable** - Clear before/after comparison

### Step 5: Verify Correctness

**ALL tests must pass** - Optimization is worthless if it breaks correctness:

```bash
# Run full test suite
swift test

# Expected output: All tests passing
# If ANY test fails, revert the optimization
```

Critical tests:
- All 80+ existing parser tests
- Django query.py round-trip test
- Error detection tests
- Code generation tests

### Step 6: Measure Performance Impact

```bash
# Run performance tests
swift test -c release --filter PerformanceTests

# Compare against baseline in performance_history.json
```

**Decision Matrix**:
- **Improved** (>2% faster): ✅ Keep change, update history
- **Neutral** (±2%): 🤔 Keep if simplifies code, otherwise revert
- **Regressed** (>2% slower): ❌ REVERT immediately

### Step 7: Update Performance History

Add entry to `performance_history.json`:

```json
{
  "timestamp": "2025-11-25T10:30:00Z",
  "commit": "abc1234",
  "optimization": "Reduced bounds checking in parseExpression",
  "parsing_median_ms": 6.123,
  "roundtrip_median_ms": 28.456,
  "speedup_vs_python": 1.42,
  "status": "improved",
  "notes": "5% improvement by using unsafelyUnwrapped in hot path"
}
```

### Step 8: Commit with Context

```bash
git add -A
git commit -m "perf: Reduce bounds checking in parseExpression

- Used unsafelyUnwrapped for token access in hot path
- Parsing: 6.426ms -> 6.123ms (4.7% improvement)
- Overall speedup: 1.35x -> 1.42x vs Python
- All 80 tests passing
- Django round-trip validated

Profiling showed parseExpression() spending 15% of time on bounds
checking. Since we always validate position before accessing, this
check is redundant in the hot path."

git push
```

## 📊 Performance Tracking

### performance_history.json Structure

```json
{
  "baseline": {
    "date": "2025-11-25",
    "commit": "5748452",
    "parsing_median_ms": 6.426,
    "roundtrip_median_ms": 29.551,
    "tokenization_median_ms": 89.266,
    "codegen_median_ms": 4.865,
    "speedup_vs_python_parsing": 1.35,
    "speedup_vs_python_roundtrip": 1.04
  },
  "history": [
    {
      "date": "2025-11-25T10:30:00Z",
      "commit": "abc1234",
      "optimization": "Description of optimization",
      "parsing_median_ms": 6.123,
      "roundtrip_median_ms": 28.456,
      "speedup_vs_python_parsing": 1.42,
      "speedup_vs_python_roundtrip": 1.06,
      "delta_parsing_percent": -4.7,
      "delta_roundtrip_percent": -3.7,
      "status": "improved",
      "tests_passing": true,
      "notes": "Details about the change"
    }
  ]
}
```

## 🚫 Common Pitfalls to Avoid

### ❌ DON'T: Optimize Without Profiling
**Wrong**: "I think parseExpression is slow, let me optimize it"
**Right**: "Profiling shows parseExpression is 30% of runtime, optimize it"

### ❌ DON'T: Batch Multiple Optimizations
**Wrong**: Optimize 5 things, then test
**Right**: Optimize 1 thing, test, measure, commit, repeat

### ❌ DON'T: Skip Grammar Verification
**Wrong**: Change parser logic based on assumptions
**Right**: Check Grammar/python.gram to ensure correctness

### ❌ DON'T: Accept Regressions
**Wrong**: "It's only 5% slower, but the code is cleaner"
**Right**: "5% regression means we're on the wrong track, revert"

### ❌ DON'T: Break Tests
**Wrong**: Optimize now, fix tests later
**Right**: All tests must pass before committing

## 🎯 Optimization Priority List

Based on profiling and component analysis:

### High Priority (Biggest Impact)
1. **Parsing hot paths** (~6.4ms total)
   - Expression parsing precedence chain
   - Token lookahead optimization
   - AST node allocation reduction

2. **Tokenization** (~90ms total)
   - UTF-8 string handling
   - Character scanning efficiency
   - Number parsing optimization

### Medium Priority
3. **Code generation** (~5ms total)
   - String building vs concatenation
   - Indentation caching

4. **Round-trip overhead**
   - Reduce re-parsing cost
   - Optimize generated code structure

### Low Priority (Already Fast)
5. Minor improvements
   - Memory pooling
   - Cache optimization

## 🔧 Optimization Techniques

### Safe Optimizations (Try First)

1. **Algorithm improvements**
   - Better data structures
   - Reduced complexity (O(n²) → O(n))
   - Caching repeated computations

2. **Memory optimizations**
   - Reduce allocations
   - Reuse buffers
   - Stack vs heap allocation

3. **Compiler hints**
   - `@inline(__always)` for tiny hot functions
   - `@_optimize(speed)` for hot paths
   - Whole-module optimization (already enabled)

### Advanced Optimizations (Use Carefully)

4. **Unsafe operations** (only after profiling proves benefit)
   - `unsafelyUnwrapped` (when bounds already checked)
   - `withUnsafeBufferPointer` (for array iteration)
   - `UnsafePointer` (for string scanning)

   **Rule**: Only use unsafe if:
   - ✅ Profiling shows significant benefit (>5% improvement)
   - ✅ Safety guaranteed by surrounding logic
   - ✅ Thoroughly documented why it's safe

5. **Protocol optimization**
   - Replace protocol types with concrete types
   - Use `final` classes to enable devirtualization
   - Avoid existentials in hot paths

## 📝 Grammar Reference Workflow

When modifying parser logic:

```bash
# 1. Identify the grammar rule
grep -A 10 "expression:" Grammar/python.gram

# 2. Understand the rule structure
# 3. Ensure implementation matches grammar exactly
# 4. Check for any edge cases in grammar comments
```

**Example**:
```python
# Grammar says:
expression:
    | disjunction 'if' disjunction 'else' expression
    | disjunction
    | lambdef

# Implementation must handle in this order:
# 1. Try lambda
# 2. Try if-expression
# 3. Fall back to disjunction
```

## 🧪 Testing Requirements

Every optimization must pass:

```bash
# 1. Full test suite
swift test
# Must show: ✔ Test run with 80 tests passed

# 2. Performance tests
swift test -c release --filter PerformanceTests
# Must show: ✔ All 4 performance tests passed

# 3. Django round-trip (the stress test)
swift test -c release --filter testDjangoQueryRoundTrip
# Must show: ✅ Round-trip complete

# 4. Compare performance history
python3 scripts/check_performance.py  # Tool to compare history
```

## 📈 Success Metrics

Track these metrics per optimization:

1. **Parsing median time** (primary metric)
2. **Speedup vs Python** (relative metric)
3. **P99 latency** (consistency metric)
4. **Test pass rate** (correctness metric)
5. **Code complexity** (maintainability metric)

## 🎓 Learning from Python's Implementation

Python's ast module is highly optimized. Study their approach:

```bash
# Python's parser is in C
# Location: https://github.com/python/cpython/tree/main/Parser

# Key techniques they use:
# - Hand-written recursive descent
# - Minimal allocations
# - Direct memory manipulation
# - Token lookahead buffering
```

We can achieve similar performance in Swift by:
- Using value types where possible
- Minimizing ARC overhead
- Reducing protocol dispatch
- Strategic use of unsafe operations

## 🔄 Iteration Cycle Summary

```
┌─────────────────────────────────────────────────────────┐
│ 1. Baseline → 2. Profile → 3. Optimize ONE thing →     │
│ 4. Test → 5. Measure → 6. Record →                     │
│ ┌─────────────────────────────────┐                    │
│ │ Improved? → Commit & Continue   │                    │
│ │ Neutral?  → Review & Decide     │                    │
│ │ Regressed? → REVERT & Try Again │                    │
│ └─────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

## 📞 Quick Reference Commands

```bash
# Establish baseline
swift test -c release --filter PerformanceTests 2>&1 | tee baseline.txt

# Check grammar
grep -n "your_rule" Grammar/python.gram

# Profile
instruments -t "Time Profiler" .build/release/pyswift-benchmark ...

# Test everything
swift test && swift test -c release --filter PerformanceTests

# Compare performance
git diff performance_history.json

# Commit optimization
git commit -m "perf: [description] - X.X% improvement"
```

## 🎯 Current Status & Next Steps

**Baseline** (as of 2025-11-25, commit 5748452):
- Parsing: 6.426ms median (1.35x vs Python, target: 2.0x)
- Round-trip: 29.551ms median (1.04x vs Python, target: 1.5x)

**Top 3 Next Optimizations** (based on profiling):
1. Optimize expression parsing precedence chain
2. Reduce tokenization overhead (UTF-8 handling)
3. Minimize AST node allocations

---

**Remember**: 
- ✅ Measure, don't guess
- ✅ One change at a time  
- ✅ Never break correctness
- ✅ Always check grammar
- ✅ Track every change
