import PySwiftAST
import PySwiftCodeGen
import PyFormatters

// Example: Comparing Black vs Google formatters

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
    
    print("\n=== Black Formatter ===")
    let blackFormatter = BlackFormatter()
    let blackFormatted = blackFormatter.formatDeep(module)
    print(blackFormatted.toPythonCode())
    
    print("\n=== Google Formatter ===")
    let googleFormatter = GoogleFormatter()
    let googleFormatted = googleFormatter.formatDeep(module)
    print(googleFormatted.toPythonCode())
    
    print("\n=== Using Protocol ===")
    let formatters: [PyFormatter] = [BlackFormatter(), GoogleFormatter()]
    for (index, formatter) in formatters.enumerated() {
        print("\nFormatter \(index + 1):")
        let formatted = formatter.formatDeep(module)
        print(formatted.toPythonCode())
    }
}
