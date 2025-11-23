import Foundation
import PySwiftAST

// Example: Parse a simple Python function
let pythonCode = """
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

result = fibonacci(10)
"""

print("=== Parsing Python Code ===")
print(pythonCode)
print()

do {
    // Tokenize first
    print("=== Tokens ===")
    let tokens = try tokenizePython(pythonCode)
    for (index, token) in tokens.prefix(15).enumerated() {
        print("\(index): \(token.type) at line \(token.line):\(token.column)")
    }
    print("... (\(tokens.count) total tokens)")
    print()
    
    // Parse into AST
    print("=== AST ===")
    let module = try parsePython(pythonCode)
    
    switch module {
    case .module(let statements):
        print("Module with \(statements.count) statements:")
        for (index, stmt) in statements.enumerated() {
            print("\(index): \(describeStatement(stmt))")
        }
    default:
        print("Other module type")
    }
    
} catch {
    print("Error: \(error)")
}

func describeStatement(_ stmt: Statement) -> String {
    switch stmt {
    case .functionDef(let funcDef):
        return "FunctionDef: \(funcDef.name) with \(funcDef.body.count) statements in body"
    case .assign(let assign):
        return "Assign: \(assign.targets.count) target(s)"
    case .ifStmt(let ifStmt):
        return "If: with \(ifStmt.body.count) statements in body"
    case .returnStmt(let ret):
        return "Return: \(ret.value != nil ? "with value" : "empty")"
    case .expr(let expr):
        return "Expr: expression statement"
    case .pass:
        return "Pass"
    default:
        return "Other statement type"
    }
}
