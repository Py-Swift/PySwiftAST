#!/bin/bash
# Profile the parser using macOS sample tool
# This creates a statistical profile without code changes

set -e

cd "$(dirname "$0")"

echo "Building release binary..."
swift build -c release -Xswiftc -g

TEST_FILE="Tests/PySwiftASTTests/Resources/real_world/ml_pipeline.py"
ITERATIONS=10000

echo ""
echo "Starting profiled run..."
echo "File: $TEST_FILE"
echo "Iterations: $ITERATIONS"
echo "Duration: ~13 seconds"
echo ""

# Run the benchmark in background and get its PID
.build/release/pyswift-benchmark "$TEST_FILE" "$ITERATIONS" parse &
PID=$!

echo "Process PID: $PID"
echo "Sampling..."

# Sample the process
sample "$PID" 10 -file parser_profile.txt

# Wait for process to complete
wait "$PID"

echo ""
echo "Profile saved to: parser_profile.txt"
echo ""
echo "Top functions by sample count:"
echo "=============================="
grep -A 50 "Call graph:" parser_profile.txt | grep -E "^\s+[0-9]+" | head -20

echo ""
echo "Hot path analysis:"
echo "=================="
grep -A 20 "Heaviest stack" parser_profile.txt | head -25

echo ""
echo "Full report: parser_profile.txt"
