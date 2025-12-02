import PySwiftAST
import PySwiftCodeGen
import PyFormatters

// Example: Using BlackFormatter to format Python code

let sourceCode = """
def foo():
    pass
def bar():
    pass
class MyClass:
    def method1(self):
        pass
    def method2(self):
        pass
"""

// Parse the Python code
let parser = Parser(sourceCode)
if let module = try? parser.parse() {
    print("=== Original Code ===")
    print(module.toPythonCode())
    
    print("\n=== Black Formatted (Deep) ===")
    let formatter = BlackFormatter()
    let formatted = formatter.formatDeep(module)
    print(formatted.toPythonCode())
}
