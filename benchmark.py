#!/usr/bin/env python3
"""
Benchmark: PySwiftAST vs Python's built-in ast module

Compares parsing performance on Django's query.py (2,886 lines)
"""

import ast
import time
import subprocess
import json
from pathlib import Path

def benchmark_python_ast(file_path: Path, iterations: int = 100):
    """Benchmark Python's built-in ast module"""
    source = file_path.read_text()
    
    # Warmup
    for _ in range(10):
        ast.parse(source)
    
    # Benchmark
    times = []
    for _ in range(iterations):
        start = time.perf_counter()
        ast.parse(source)
        end = time.perf_counter()
        times.append(end - start)
    
    return times

def benchmark_pyswift_ast(file_path: Path, iterations: int = 100):
    """Benchmark PySwiftAST parser"""
    # Use the built executable
    benchmark_exe = Path(".build/release/pyswift-benchmark")
    
    if not benchmark_exe.exists():
        print(f"Error: {benchmark_exe} not found. Run: swift build -c release")
        return None
    
    try:
        # Run Swift benchmark
        result = subprocess.run(
            [str(benchmark_exe), str(file_path), str(iterations)],
            capture_output=True,
            text=True,
            timeout=120
        )
        
        if result.returncode != 0:
            print(f"Swift benchmark error: {result.stderr}")
            return None
        
        times = json.loads(result.stdout.strip())
        return times
    except subprocess.TimeoutExpired:
        print("Swift benchmark timed out")
        return None
    except Exception as e:
        print(f"Error running Swift benchmark: {e}")
        return None

def calculate_stats(times):
    """Calculate statistics from timing data"""
    if not times:
        return None
    
    sorted_times = sorted(times)
    n = len(sorted_times)
    
    return {
        'min': min(sorted_times) * 1000,  # Convert to ms
        'max': max(sorted_times) * 1000,
        'mean': sum(sorted_times) / n * 1000,
        'median': sorted_times[n // 2] * 1000,
        'p95': sorted_times[int(n * 0.95)] * 1000,
        'p99': sorted_times[int(n * 0.99)] * 1000,
    }

def main():
    django_file = Path("Tests/PySwiftASTTests/Resources/test_files/django_query.py")
    
    if not django_file.exists():
        print(f"Error: {django_file} not found")
        return
    
    # Check if benchmark executable exists
    benchmark_exe = Path(".build/release/pyswift-benchmark")
    if not benchmark_exe.exists():
        print("Building benchmark executable...")
        result = subprocess.run(
            ["swift", "build", "-c", "release"],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print(f"Build failed: {result.stderr}")
            return
        print("Build complete!")
        print()
    
    print("=" * 70)
    print("PySwiftAST vs Python ast Benchmark")
    print("=" * 70)
    print(f"File: {django_file.name}")
    print(f"Size: {django_file.stat().st_size:,} bytes")
    print(f"Lines: {len(django_file.read_text().splitlines()):,}")
    print()
    
    iterations = 100
    print(f"Running {iterations} iterations (with 10 warmup runs)...")
    print()
    
    # Benchmark Python ast
    print("Benchmarking Python's ast module...")
    python_times = benchmark_python_ast(django_file, iterations)
    python_stats = calculate_stats(python_times)
    
    # Benchmark PySwiftAST
    print("Benchmarking PySwiftAST...")
    swift_times = benchmark_pyswift_ast(django_file, iterations)
    swift_stats = calculate_stats(swift_times) if swift_times else None
    
    # Display results
    print()
    print("=" * 70)
    print("RESULTS")
    print("=" * 70)
    print()
    
    print("Python ast module:")
    if python_stats:
        print(f"  Min:    {python_stats['min']:8.3f} ms")
        print(f"  Median: {python_stats['median']:8.3f} ms")
        print(f"  Mean:   {python_stats['mean']:8.3f} ms")
        print(f"  P95:    {python_stats['p95']:8.3f} ms")
        print(f"  P99:    {python_stats['p99']:8.3f} ms")
        print(f"  Max:    {python_stats['max']:8.3f} ms")
    print()
    
    print("PySwiftAST:")
    if swift_stats:
        print(f"  Min:    {swift_stats['min']:8.3f} ms")
        print(f"  Median: {swift_stats['median']:8.3f} ms")
        print(f"  Mean:   {swift_stats['mean']:8.3f} ms")
        print(f"  P95:    {swift_stats['p95']:8.3f} ms")
        print(f"  P99:    {swift_stats['p99']:8.3f} ms")
        print(f"  Max:    {swift_stats['max']:8.3f} ms")
        print()
        
        # Calculate speedup/slowdown
        ratio = python_stats['median'] / swift_stats['median']
        if ratio > 1:
            print(f"✨ PySwiftAST is {ratio:.2f}x FASTER than Python ast")
        else:
            print(f"PySwiftAST is {1/ratio:.2f}x slower than Python ast")
    else:
        print("  [Benchmark failed]")
    
    print()
    print("=" * 70)

if __name__ == "__main__":
    main()
