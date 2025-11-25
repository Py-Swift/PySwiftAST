#!/usr/bin/env python3
"""
Comprehensive benchmark: PySwiftAST vs Python ast module
Tests both tokenization and full round-trip performance
"""
import subprocess
import json
import statistics
import time
import ast
import sys

def run_swift_benchmark(file_path, iterations, mode):
    """Run Swift benchmark and return times in ms"""
    cmd = [".build/release/pyswift-benchmark", file_path, str(iterations), mode]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running Swift benchmark: {result.stderr}")
        sys.exit(1)
    times = json.loads(result.stdout)
    return [t * 1000 for t in times]  # Convert to ms

def benchmark_python_tokenize(source, iterations):
    """Benchmark Python tokenization"""
    import tokenize
    import io
    
    times = []
    # Warmup
    for _ in range(10):
        list(tokenize.generate_tokens(io.StringIO(source).readline))
    
    # Benchmark
    for _ in range(iterations):
        start = time.perf_counter()
        list(tokenize.generate_tokens(io.StringIO(source).readline))
        end = time.perf_counter()
        times.append((end - start) * 1000)
    
    return times

def benchmark_python_parse(source, iterations):
    """Benchmark Python AST parsing"""
    times = []
    # Warmup
    for _ in range(10):
        ast.parse(source)
    
    # Benchmark
    for _ in range(iterations):
        start = time.perf_counter()
        ast.parse(source)
        end = time.perf_counter()
        times.append((end - start) * 1000)
    
    return times

def benchmark_python_roundtrip(source, iterations):
    """Benchmark Python parse -> unparse -> reparse"""
    times = []
    # Warmup
    for _ in range(10):
        tree = ast.parse(source)
        regenerated = ast.unparse(tree)
        ast.parse(regenerated)
    
    # Benchmark
    for _ in range(iterations):
        start = time.perf_counter()
        tree = ast.parse(source)
        regenerated = ast.unparse(tree)
        ast.parse(regenerated)
        end = time.perf_counter()
        times.append((end - start) * 1000)
    
    return times

def print_comparison(title, swift_times, python_times):
    """Print comparison statistics"""
    swift_median = statistics.median(swift_times)
    python_median = statistics.median(python_times)
    speedup = python_median / swift_median
    
    print(f"\n{title}:")
    print(f"  Python:  {python_median:6.3f}ms (min: {min(python_times):.3f}ms, max: {max(python_times):.3f}ms)")
    print(f"  Swift:   {swift_median:6.3f}ms (min: {min(swift_times):.3f}ms, max: {max(swift_times):.3f}ms)")
    
    if speedup > 1.0:
        print(f"  Result:  Swift is {speedup:.2f}x FASTER ✅")
    elif speedup < 1.0:
        print(f"  Result:  Swift is {1/speedup:.2f}x SLOWER ❌")
    else:
        print(f"  Result:  Equal performance")
    
    return speedup

def main():
    test_file = "Tests/PySwiftASTTests/Resources/real_world/ml_pipeline.py"
    iterations = 100
    
    # Read source
    with open(test_file, 'r') as f:
        source = f.read()
    
    lines = source.count('\n') + 1
    size = len(source)
    
    print("=" * 80)
    print("PYSWIFTAST vs PYTHON PERFORMANCE COMPARISON")
    print("=" * 80)
    print(f"Test file:  {test_file}")
    print(f"File size:  {size:,} bytes, {lines} lines")
    print(f"Iterations: {iterations}")
    print("=" * 80)
    
    # 1. Tokenization comparison
    print("\n[1/3] Benchmarking TOKENIZATION...")
    print("  Python tokenize module...")
    python_tok_times = benchmark_python_tokenize(source, iterations)
    print("  Swift UTF8Tokenizer...")
    swift_tok_times = run_swift_benchmark(test_file, iterations, "tokenize-utf8")
    tok_speedup = print_comparison("TOKENIZATION", swift_tok_times, python_tok_times)
    
    # 2. Parsing comparison
    print("\n[2/3] Benchmarking PARSING (tokenization + parse)...")
    print("  Python ast.parse...")
    python_parse_times = benchmark_python_parse(source, iterations)
    print("  Swift Parser (with UTF8Tokenizer)...")
    # Note: Swift "parse" mode pre-tokenizes, so we need to add tokenization time
    swift_parse_only = run_swift_benchmark(test_file, iterations, "parse")
    swift_parse_times = [p + t for p, t in zip(swift_parse_only, swift_tok_times)]
    parse_speedup = print_comparison("PARSING (full)", swift_parse_times, python_parse_times)
    
    # 3. Round-trip comparison
    print("\n[3/3] Benchmarking ROUND-TRIP (parse -> codegen -> reparse)...")
    print("  Python ast.parse -> ast.unparse -> ast.parse...")
    python_rt_times = benchmark_python_roundtrip(source, iterations)
    print("  Swift full round-trip...")
    swift_rt_times = run_swift_benchmark(test_file, iterations, "roundtrip")
    rt_speedup = print_comparison("ROUND-TRIP", swift_rt_times, python_rt_times)
    
    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Tokenization:  Swift is {tok_speedup:5.2f}x {'faster ✅' if tok_speedup > 1 else 'slower ❌'}")
    print(f"Parsing:       Swift is {parse_speedup:5.2f}x {'faster ✅' if parse_speedup > 1 else 'slower ❌'}")
    print(f"Round-trip:    Swift is {rt_speedup:5.2f}x {'faster ✅' if rt_speedup > 1 else 'slower ❌'}")
    print("=" * 80)
    
    # Goal assessment
    print("\nGOAL ASSESSMENT:")
    print(f"  Target: 2.0x faster parsing    -> {'✅ ACHIEVED' if parse_speedup >= 2.0 else f'❌ Not yet ({parse_speedup:.2f}x)'}")
    print(f"  Target: 1.5x faster round-trip -> {'✅ ACHIEVED' if rt_speedup >= 1.5 else f'❌ Not yet ({rt_speedup:.2f}x)'}")
    print("=" * 80)

if __name__ == "__main__":
    main()
