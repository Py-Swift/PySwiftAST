#!/bin/zsh
set -e

echo "Profiling code generation with sample tool..."
echo "File: Tests/PySwiftASTTests/Resources/real_world/ml_pipeline.py"
echo "Iterations: 5000"
echo ""

# Run with sample profiler
sample .build/release/pyswift-benchmark 5 -file Tests/PySwiftASTTests/Resources/real_world/ml_pipeline.py 5000 codegen > codegen_profile.txt 2>&1 &
PID=$!

# Wait for process to complete
wait $PID

echo "Profiling complete. Analyzing results..."
echo ""

# Extract top functions
echo "=== TOP 20 HOTTEST FUNCTIONS (Code Generation) ==="
grep -A 5000 "Call graph:" codegen_profile.txt | grep "PySwiftCodeGen" | head -30 | sort -rn -k1 || echo "No profile data found"

echo ""
echo "Profile saved to: codegen_profile.txt"
