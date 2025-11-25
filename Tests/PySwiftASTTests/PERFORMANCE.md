# Performance Test Suite

This test suite tracks PySwiftAST's performance against Python's built-in `ast` module, with a goal of achieving **2x+ speedup** through optimization.

## Running Performance Tests

⚠️ **IMPORTANT**: Performance tests **MUST** be run in release mode:

```bash
swift test -c release --filter PerformanceTests
```

Debug builds are 3-4x slower and will show false "regressions".

## Current Performance

### Parsing (Django query.py - 2,886 lines)
- **Current**: 1.35x faster than Python
- **Goal**: 2.0x+ faster

### Round-trip (parse → generate → reparse)
- **Current**: 1.04x faster than Python
- **Goal**: 1.5x+ faster

## Test Coverage

The performance suite includes:

1. **`testParsingPerformance_Django`** - Measures pure parsing speed
   - Tokenizes Django's query.py once
   - Runs 100 parsing iterations
   - Compares median time vs Python ast.parse()

2. **`testRoundtripPerformance_Django`** - Measures full round-trip
   - Parse → Generate code → Reparse
   - Validates code generation correctness
   - Compares vs Python parse + unparse + reparse

3. **`testTokenizationPerformance`** - Isolates tokenization cost
   - Identifies lexer optimization opportunities
   - Currently: ~90ms median for Django file

4. **`testCodeGenerationPerformance`** - Isolates code gen cost
   - Currently: ~5ms median
   - Shows code gen is very fast relative to parsing

## Optimization Roadmap

Target: **2x+ speedup** over Python's ast module

### 1. Parsing Optimizations (Highest Impact)
- [ ] Reduce bounds checking overhead
- [ ] Use unsafe buffer pointers for hot paths  
- [ ] Optimize token lookahead
- [ ] Reduce AST node allocations
- [ ] Pool commonly used node types
- [ ] Optimize expression parsing precedence chain
- [ ] Inline hot path functions

### 2. Tokenization Optimizations
- [ ] UTF-8 string handling (avoid UTF-16 conversion)
- [ ] Reduce string allocations during scanning
- [ ] Optimize number parsing
- [ ] Fast path for common tokens
- [ ] Avoid redundant character lookups

### 3. Code Generation Optimizations
- [ ] Use string builders instead of concatenation
- [ ] Cache indentation strings
- [ ] Reduce protocol witness table lookups
- [ ] Batch string writing

### 4. Memory Optimizations
- [ ] Reduce AST node size (pack fields)
- [ ] Use value types where possible
- [ ] Arena allocation for AST nodes
- [ ] Reduce ARC overhead

### 5. Compiler Optimizations
- [ ] Profile-guided optimization
- [ ] Whole-module optimization
- [ ] Function specialization

## Profiling

Use Instruments to find hotspots:

```bash
# Build for profiling
swift build -c release

# Run with Instruments
instruments -t "Time Profiler" .build/release/pyswift-benchmark \
  Tests/PySwiftASTTests/Resources/test_files/django_query.py 100 parse
```

## Performance Tracking

The test suite tracks:
- Min, median, mean, P95, P99, max latencies
- Speedup vs Python baseline
- Automatic regression detection (fails if <80% of target)

Example output:
```
======================================================================
PARSING PERFORMANCE TEST - Django query.py
Build mode: RELEASE ✅
======================================================================

PySwiftAST Parsing (100 iterations):
  Min:       5.973 ms
  Median:    6.426 ms  <- Primary metric
  Mean:      6.529 ms
  P95:       7.100 ms
  P99:       7.577 ms
  Max:       7.577 ms

Performance vs Python ast.parse():
  Current speedup: 1.35x
  Target speedup:  1.35x
  ✅ PASS: Meeting current target
  🎯 Room for optimization: Target is 2.0x+
======================================================================
```

## Continuous Integration

Add to CI pipeline:

```yaml
- name: Performance Tests
  run: swift test -c release --filter PerformanceTests
```

This ensures performance doesn't regress with new changes.

## Benchmarking Guidelines

1. **Always use release builds** (`-c release`)
2. **Run multiple iterations** (100+ for stable results)
3. **Include warmup runs** (10 runs before measurement)
4. **Compare medians** (more stable than means)
5. **Track P95/P99** (catch tail latencies)
6. **Use same hardware** (results vary across machines)

## Next Steps

1. Profile with Instruments to identify hotspots
2. Implement low-hanging fruit optimizations
3. Measure impact with this test suite
4. Iterate until 2x+ speedup achieved
