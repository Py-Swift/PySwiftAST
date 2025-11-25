#!/usr/bin/env python3
"""
Comprehensive profiling script for PySwiftAST parser
Uses multiple profiling approaches to find bottlenecks
"""
import subprocess
import json
import statistics
import sys

def run_benchmark(file_path, iterations, mode):
    """Run benchmark and return detailed timing"""
    cmd = [".build/release/pyswift-benchmark", file_path, str(iterations), mode]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)
    times = json.loads(result.stdout)
    return [t * 1000 for t in times]

def profile_components():
    """Profile each component separately"""
    test_file = "Tests/PySwiftASTTests/Resources/real_world/ml_pipeline.py"
    iterations = 100
    
    print("=" * 80)
    print("COMPONENT-LEVEL PROFILING")
    print("=" * 80)
    print(f"Test file: {test_file}")
    print(f"Iterations: {iterations}\n")
    
    # Tokenization with old tokenizer
    print("[1/4] Old Character-based tokenizer...")
    old_tok = run_benchmark(test_file, iterations, "tokenize")
    old_tok_median = statistics.median(old_tok)
    print(f"  Median: {old_tok_median:.3f}ms")
    
    # Tokenization with UTF8 tokenizer
    print("\n[2/4] UTF-8 byte-based tokenizer...")
    utf8_tok = run_benchmark(test_file, iterations, "tokenize-utf8")
    utf8_tok_median = statistics.median(utf8_tok)
    print(f"  Median: {utf8_tok_median:.3f}ms")
    print(f"  Speedup: {old_tok_median / utf8_tok_median:.1f}x")
    
    # Parsing (pre-tokenized)
    print("\n[3/4] Parser (tokens → AST)...")
    parse = run_benchmark(test_file, iterations, "parse")
    parse_median = statistics.median(parse)
    print(f"  Median: {parse_median:.3f}ms")
    
    # Round-trip
    print("\n[4/4] Full round-trip...")
    roundtrip = run_benchmark(test_file, iterations, "roundtrip")
    rt_median = statistics.median(roundtrip)
    print(f"  Median: {rt_median:.3f}ms")
    
    # Analysis
    print("\n" + "=" * 80)
    print("BOTTLENECK ANALYSIS")
    print("=" * 80)
    
    total = utf8_tok_median + parse_median + (rt_median - utf8_tok_median - parse_median)
    codegen = rt_median - utf8_tok_median - parse_median
    
    print(f"\nPipeline breakdown (estimated):")
    print(f"  Tokenization: {utf8_tok_median:6.3f}ms ({utf8_tok_median/rt_median*100:5.1f}%)")
    print(f"  Parsing:      {parse_median:6.3f}ms ({parse_median/rt_median*100:5.1f}%)")
    print(f"  Code Gen:     {codegen:6.3f}ms ({codegen/rt_median*100:5.1f}%)")
    print(f"  Round-trip:   {rt_median:6.3f}ms (100.0%)")
    
    print(f"\nMain bottleneck: ", end="")
    max_component = max([
        (utf8_tok_median, "Tokenization"),
        (parse_median, "Parsing"),
        (codegen, "Code Generation")
    ])
    print(f"{max_component[1]} ({max_component[0]:.3f}ms)")
    
    return {
        'tokenization': utf8_tok_median,
        'parsing': parse_median,
        'codegen': codegen,
        'roundtrip': rt_median
    }

def suggest_next_steps(breakdown):
    """Suggest optimizations based on profiling"""
    print("\n" + "=" * 80)
    print("OPTIMIZATION RECOMMENDATIONS")
    print("=" * 80)
    
    total = breakdown['roundtrip']
    
    # Sort by time spent
    components = [
        (breakdown['tokenization'], 'Tokenization', [
            "Already optimized with UTF-8 tokenizer (18.8x faster)",
            "Further optimization unlikely to help significantly"
        ]),
        (breakdown['parsing'], 'Parsing', [
            "Use Instruments Time Profiler to find hot functions",
            "Look for excessive allocations or copy operations",
            "Consider caching frequently accessed tokens",
            "Optimize expression parsing (likely the hottest path)"
        ]),
        (breakdown['codegen'], 'Code Generation', [
            "Profile string building operations",
            "Check for unnecessary string allocations",
            "Consider using ContiguousArray for better cache locality",
            "Look for repeated indentation calculations"
        ])
    ]
    
    components.sort(reverse=True)
    
    print("\nPriority order (by time spent):\n")
    for i, (time, name, suggestions) in enumerate(components, 1):
        pct = (time / total) * 100
        print(f"{i}. {name}: {time:.3f}ms ({pct:.1f}%)")
        for suggestion in suggestions:
            print(f"   - {suggestion}")
        print()

def print_instruments_instructions():
    """Print instructions for using Instruments"""
    print("=" * 80)
    print("PROFILING WITH INSTRUMENTS")
    print("=" * 80)
    print("""
To profile with Instruments Time Profiler:

1. Build the benchmark tool:
   swift build -c release

2. Run with Instruments Time Profiler:
   instruments -t "Time Profiler" \\
     -D profile.trace \\
     .build/release/pyswift-benchmark \\
     Tests/PySwiftASTTests/Resources/real_world/ml_pipeline.py 1000 parse

3. Open the trace file:
   open profile.trace

4. In Instruments, look for:
   - Call Tree view (heaviest stack traces)
   - Functions taking >5% of total time
   - Self time vs Total time
   - Hot path through recursive functions

5. Focus on:
   - Parser.parseExpression and related functions
   - Token access patterns (currentToken, advance)
   - AST node creation/allocation
   - String operations

Alternative: Use Xcode's Instruments directly:
   - Open in Xcode: xed .
   - Product → Profile
   - Choose "Time Profiler" template
   - Run pyswift-benchmark target
""")

def main():
    # Component profiling
    breakdown = profile_components()
    
    # Suggestions
    suggest_next_steps(breakdown)
    
    # Instruments instructions
    print_instruments_instructions()

if __name__ == "__main__":
    main()
