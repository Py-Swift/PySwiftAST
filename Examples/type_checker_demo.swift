import PySwiftAST
import PyChecking

// Example: Using TypeChecker for static type analysis

let code = """
# Type-annotated variables
x: int = 5
y: str = "hello"
z: int = "wrong"  # Type error!

# Function with annotations
def add(a: int, b: int) -> int:
    return a + b

def greet(name: str) -> str:
    return "Hello, " + name

def broken(x: int) -> str:
    return x  # Type error: returning int instead of str

# Type inference
numbers = [1, 2, 3]
message = "test"
result = add(10, 20)

# Mixed types
def process(value: int) -> int:
    temp = value * 2
    return temp

bad_result = process("not an int")  # Would need flow analysis
"""

// Parse the code
let parser = Parser(code)
guard let module = try? parser.parse() else {
    print("Failed to parse code")
    exit(1)
}

// Run type checker
let checker = TypeChecker()
let diagnostics = checker.check(module)

// Display results
print("=== Type Checking Results ===")
print()

if diagnostics.isEmpty {
    print("✓ No type errors found")
} else {
    print("Found \(diagnostics.count) issue(s):")
    print()
    
    for diagnostic in diagnostics.sorted(by: { $0.line < $1.line }) {
        print(diagnostic)
    }
}

/* Expected output:
=== Type Checking Results ===

Found 2 issue(s):

3:0: error: Type mismatch: cannot assign str to z of type int [type-checker]
13:4: error: Return type mismatch: expected str, got int [type-checker]
*/
