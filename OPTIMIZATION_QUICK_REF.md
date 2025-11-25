# Quick Reference: Performance Optimization

## 🚀 Quick Start

```bash
# 1. Establish baseline
swift test -c release --filter PerformanceTests 2>&1 | tee current_run.txt
python3 scripts/check_performance.py current_run.txt

# 2. Check grammar for the feature you're optimizing
grep -A 10 "your_rule" Grammar/python.gram

# 3. Make ONE optimization change
# ... edit code ...

# 4. Test correctness
swift test

# 5. Test performance
swift test -c release --filter PerformanceTests 2>&1 | python3 scripts/check_performance.py

# 6. If improved, update history and commit
# If regressed, REVERT immediately
```

## ✅ Pre-Optimization Checklist

- [ ] Run baseline performance tests
- [ ] Check Grammar/python.gram for correctness
- [ ] Profile to identify actual hotspot
- [ ] Plan ONE specific optimization

## 🔄 Optimization Loop

```
1. Baseline → 2. Grammar Check → 3. Profile → 
4. Optimize ONE thing → 5. Test ALL → 6. Measure → 
7. Compare → Decision:
   ✅ Improved? → Update history + Commit → Loop
   ➡️ Neutral?  → Review code quality → Decide
   ❌ Regressed? → REVERT → Try different approach
```

## 📊 Key Metrics to Track

- **Parsing median** (primary): Currently 6.4ms, Goal: 4.3ms (2x vs Python)
- **Round-trip median**: Currently 29.6ms, Goal: 20.2ms (1.5x vs Python)
- **Test pass rate**: Must be 100% (all 80+ tests)

## 🚫 Never Do This

- ❌ Optimize without profiling
- ❌ Change multiple things at once
- ❌ Skip grammar verification
- ❌ Accept regressions
- ❌ Commit with failing tests

## ✅ Always Do This

- ✅ Measure before and after
- ✅ One optimization at a time
- ✅ Verify against Grammar/python.gram
- ✅ Run full test suite
- ✅ Update performance_history.json
- ✅ Document why the optimization works

## 📁 Key Files

- `OPTIMIZATION_GUIDELINES.md` - Full detailed guidelines
- `performance_history.json` - Performance tracking database
- `Grammar/python.gram` - Python 3.13 grammar (source of truth)
- `Tests/PySwiftASTTests/PerformanceTests.swift` - Performance test suite
- `scripts/check_performance.py` - Performance comparison tool

## 🎯 Current Goals

**Parsing**: 1.35x → 2.0x faster than Python (need 32% improvement)
**Round-trip**: 1.04x → 1.5x faster than Python (need 27% improvement)

## 📞 Common Commands

```bash
# Profile with Instruments
instruments -t "Time Profiler" .build/release/pyswift-benchmark \
  Tests/PySwiftASTTests/Resources/test_files/django_query.py 100 parse

# Search grammar
grep -n "expression" Grammar/python.gram

# Run all tests
swift test

# Run performance tests
swift test -c release --filter PerformanceTests

# Compare performance
python3 scripts/check_performance.py <test_output.txt>

# View history
cat performance_history.json | python3 -m json.tool
```

## 🏆 Success Pattern

```
✅ Profile identified parseExpression as 30% of runtime
✅ Checked grammar - implementation matches
✅ Reduced bounds checking using unsafelyUnwrapped
✅ All 80 tests pass
✅ Performance: 6.4ms → 6.1ms (4.7% improvement)
✅ Updated history with details
✅ Committed with clear message
```

## ⚠️ Failure Pattern (Don't Do This)

```
❌ "I think tokenization is slow" (no profiling)
❌ Changed 5 things at once
❌ Didn't check grammar
❌ 2 tests failing, "will fix later"
❌ Performance regressed 3%
❌ Committed anyway
```

---

**Remember**: Measure, don't guess. One thing at a time. Never break correctness.
