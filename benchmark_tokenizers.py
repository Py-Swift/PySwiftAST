#!/usr/bin/env python3
"""
Benchmark comparison: Old Tokenizer vs UTF8Tokenizer
"""
import subprocess
import json
import statistics

def run_benchmark(file_path, iterations, mode):
    cmd = [".build/release/pyswift-benchmark", file_path, str(iterations), mode]
    result = subprocess.run(cmd, capture_output=True, text=True)
    times = json.loads(result.stdout)
    return [t * 1000 for t in times]  # Convert to ms

def main():
    test_file = "Tests/PySwiftASTTests/Resources/real_world/ml_pipeline.py"
    iterations = 100
    
    print("=" * 70)
    print("TOKENIZER PERFORMANCE COMPARISON")
    print("=" * 70)
    print(f"Test file: {test_file}")
    print(f"Iterations: {iterations}")
    print()
    
    # Old tokenizer
    print("Benchmarking old Character-based tokenizer...")
    old_times = run_benchmark(test_file, iterations, "tokenize")
    old_median = statistics.median(old_times)
    old_min = min(old_times)
    old_max = max(old_times)
    
    print(f"  Median: {old_median:.3f}ms")
    print(f"  Min:    {old_min:.3f}ms")
    print(f"  Max:    {old_max:.3f}ms")
    print()
    
    # New tokenizer
    print("Benchmarking new UTF-8 byte-based tokenizer...")
    new_times = run_benchmark(test_file, iterations, "tokenize-utf8")
    new_median = statistics.median(new_times)
    new_min = min(new_times)
    new_max = max(new_times)
    
    print(f"  Median: {new_median:.3f}ms")
    print(f"  Min:    {new_min:.3f}ms")
    print(f"  Max:    {new_max:.3f}ms")
    print()
    
    # Calculate speedup
    speedup = old_median / new_median
    improvement = ((old_median - new_median) / old_median) * 100
    
    print("=" * 70)
    print("RESULTS:")
    print(f"  Speedup:     {speedup:.1f}x faster")
    print(f"  Improvement: {improvement:.1f}% reduction in time")
    print(f"  Time saved:  {old_median - new_median:.3f}ms per tokenization")
    print("=" * 70)

if __name__ == "__main__":
    main()
