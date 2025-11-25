#!/usr/bin/env python3
"""
Manual profiling by adding strategic timing measurements to Parser
"""
import subprocess
import sys
import json
import statistics

PARSER_FILE = "Sources/PySwiftAST/Parser.swift"

# Functions to profile (approximate line numbers)
PROFILE_FUNCTIONS = [
    ("parseExpression", "expression parsing"),
    ("parseAtom", "atom parsing"),  
    ("parseCall", "function call parsing"),
    ("parseName", "name/identifier parsing"),
    ("parseNumber", "number literal parsing"),
    ("parseString", "string literal parsing"),
    ("parseComparisonExpression", "comparison expression"),
    ("parseArithmeticExpression", "arithmetic expression"),
    ("parsePrimaryExpression", "primary expression"),
    ("parseStatement", "statement parsing"),
    ("parseIfStatement", "if statement"),
    ("parseWhileStatement", "while statement"),
    ("parseForStatement", "for statement"),
    ("parseFunctionDef", "function definition"),
    ("parseClassDef", "class definition"),
    ("currentToken", "token access"),
    ("advance", "token advance"),
]

def add_profiling():
    """Add timing code to Parser.swift"""
    print("Adding profiling instrumentation to Parser.swift...")
    
    # Read the file
    with open(PARSER_FILE, 'r') as f:
        content = f.read()
    
    # Add profiling imports at the top if not there
    if "import QuartzCore" not in content:
        content = "import QuartzCore\n" + content
    
    # Add profiling infrastructure after the class declaration
    profiling_code = """
    // MARK: - Profiling Infrastructure
    
    private static var profileData: [String: (count: Int, totalTime: Double)] = [:]
    private static let profilingEnabled = ProcessInfo.processInfo.environment["PROFILE_PARSER"] != nil
    
    @inline(__always)
    private func profile<T>(_ name: String, _ block: () throws -> T) rethrows -> T {
        guard Self.profilingEnabled else {
            return try block()
        }
        
        let start = CACurrentMediaTime()
        defer {
            let elapsed = CACurrentMediaTime() - start
            Self.profileData[name, default: (0, 0.0)] = (
                Self.profileData[name]?.count ?? 0 + 1,
                Self.profileData[name]?.totalTime ?? 0.0 + elapsed
            )
        }
        return try block()
    }
    
    public static func printProfile() {
        guard profilingEnabled else { return }
        
        print("\\n" + String(repeating: "=", count: 80))
        print("PARSER PROFILE")
        print(String(repeating: "=", count: 80))
        print(String(format: "%-40s %10s %15s %15s", "Function", "Calls", "Total (ms)", "Avg (μs)"))
        print(String(repeating: "-", count: 80))
        
        let sorted = profileData.sorted { $0.value.totalTime > $1.value.totalTime }
        for (name, data) in sorted {
            let avgMicros = (data.totalTime / Double(data.count)) * 1_000_000
            print(String(format: "%-40s %10d %15.3f %15.1f", 
                        String(name.prefix(40)),
                        data.count,
                        data.totalTime * 1000,
                        avgMicros))
        }
        print(String(repeating: "=", count: 80))
    }
"""
    
    # Find where to insert (after class declaration)
    insert_pos = content.find("private var position: Int = 0")
    if insert_pos == -1:
        print("Error: Could not find insertion point")
        sys.exit(1)
    
    # Find the end of the line
    insert_pos = content.find("\n", insert_pos) + 1
    
    content = content[:insert_pos] + profiling_code + content[insert_pos:]
    
    # Write back
    with open(PARSER_FILE, 'w') as f:
        f.write(content)
    
    print("✓ Added profiling infrastructure")

def remove_profiling():
    """Remove profiling code"""
    print("Removing profiling instrumentation...")
    subprocess.run(["git", "checkout", "--", PARSER_FILE], check=True)
    print("✓ Reverted changes")

def build():
    """Build the project"""
    print("\nBuilding...")
    result = subprocess.run(
        ["swift", "build", "-c", "release"],
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        print("Build failed:")
        print(result.stderr)
        sys.exit(1)
    print("✓ Build complete")

def run_profiled_benchmark():
    """Run benchmark with profiling enabled"""
    print("\nRunning profiled benchmark...")
    
    env = {"PROFILE_PARSER": "1"}
    result = subprocess.run(
        [".build/release/pyswift-benchmark",
         "Tests/PySwiftASTTests/Resources/real_world/ml_pipeline.py",
         "100",
         "parse"],
        env={**subprocess.os.environ, **env},
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print("Error running benchmark:")
        print(result.stderr)
        sys.exit(1)
    
    print(result.stdout)

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "clean":
        remove_profiling()
        return
    
    try:
        # Add profiling
        add_profiling()
        
        # Build
        build()
        
        # Run
        run_profiled_benchmark()
        
    finally:
        # Clean up
        remove_profiling()

if __name__ == "__main__":
    main()
