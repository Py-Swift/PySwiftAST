#!/usr/bin/env python3
"""
Benchmark on large file (django_query.py - 2886 lines)
"""
import subprocess
import json
import statistics
import time
import ast

def run_swift_benchmark(file_path, iterations, mode):
    cmd = [".build/release/pyswift-benchmark", file_path, str(iterations), mode]
    result = subprocess.run(cmd, capture_output=True, text=True)
    times = json.loads(result.stdout)
    return [t * 1000 for t in times]

def benchmark_python(source, iterations, mode):
    times = []
    for _ in range(10):  # warmup
        if mode == "parse":
            ast.parse(source)
        else:  # roundtrip
            tree = ast.parse(source)
            regenerated = ast.unparse(tree)
            ast.parse(regenerated)
    
    for _ in range(iterations):
        start = time.perf_counter()
        if mode == "parse":
            ast.parse(source)
        else:
            tree = ast.parse(source)
            regenerated = ast.unparse(tree)
            ast.parse(regenerated)
        end = time.perf_counter()
        times.append((end - start) * 1000)
    
    return times

test_file = "Tests/PySwiftASTTests/Resources/test_files/django_query.py"
iterations = 50

with open(test_file, 'r') as f:
    source = f.read()

print("=" * 80)
print("LARGE FILE BENCHMARK (django_query.py - 2,886 lines, 111KB)")
print("=" * 80)

# Parsing
print("\n[1/2] Parsing benchmark...")
python_parse = benchmark_python(source, iterations, "parse")
swift_tok = run_swift_benchmark(test_file, iterations, "tokenize-utf8")
swift_parse_only = run_swift_benchmark(test_file, iterations, "parse")
swift_parse = [t + p for t, p in zip(swift_tok, swift_parse_only)]

py_median = statistics.median(python_parse)
sw_median = statistics.median(swift_parse)
parse_speedup = py_median / sw_median

print(f"  Python: {py_median:7.2f}ms")
print(f"  Swift:  {sw_median:7.2f}ms")
print(f"  Speedup: {parse_speedup:.2f}x {'✅' if parse_speedup >= 2.0 else ''}")

# Round-trip
print("\n[2/2] Round-trip benchmark...")
python_rt = benchmark_python(source, iterations, "roundtrip")
swift_rt = run_swift_benchmark(test_file, iterations, "roundtrip")

py_rt_median = statistics.median(python_rt)
sw_rt_median = statistics.median(swift_rt)
rt_speedup = py_rt_median / sw_rt_median

print(f"  Python: {py_rt_median:7.2f}ms")
print(f"  Swift:  {sw_rt_median:7.2f}ms")
print(f"  Speedup: {rt_speedup:.2f}x {'✅' if rt_speedup >= 1.5 else ''}")

print("\n" + "=" * 80)
print("SUMMARY:")
print(f"  Parsing:    {parse_speedup:.2f}x (target: 2.0x) {'✅' if parse_speedup >= 2.0 else '❌'}")
print(f"  Round-trip: {rt_speedup:.2f}x (target: 1.5x) {'✅' if rt_speedup >= 1.5 else '❌'}")
print("=" * 80)
