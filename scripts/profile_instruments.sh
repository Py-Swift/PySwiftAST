#!/bin/bash

# Profile PySwiftAST with Instruments
# Usage: ./scripts/profile_instruments.sh

echo "Building release version for profiling..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo ""
echo "Build complete. Now run with Instruments:"
echo ""
echo "1. Open Instruments (Cmd+I in Xcode, or open /Applications/Xcode.app/Contents/Applications/Instruments.app)"
echo "2. Select 'Time Profiler' template"
echo "3. Choose target: .build/release/PySwiftASTPackageTests"
echo "4. Click Record to start profiling"
echo ""
echo "Or use command line:"
echo "  xcrun xctrace record --template 'Time Profiler' --launch -- swift test -c release --filter testRoundtripPerformance_Django"
echo ""
echo "For immediate simple profiling, running test now..."

swift test -c release --filter testTokenizationPerformance 2>&1 | grep -A 20 "TOKENIZATION"
