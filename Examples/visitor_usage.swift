import PySwiftAST
import PyAstVisitors

// Example 1: Count function definitions
let source1 = """
def hello():
    print("Hello")

def world():
    print("World")

class MyClass:
    def method(self):
        pass
"""

let module1 = try parsePython(source1)
let counter = DefinitionCounter()
module1.accept(visitor: counter)

print("Functions: \(counter.functionCount)")      // 3 (hello, world, method)
print("Classes: \(counter.classCount)")           // 1 (MyClass)
print("Async functions: \(counter.asyncFunctionCount)")  // 0

// Example 2: Find all variables
let source2 = """
x = 10
y: int = 20
z += 5
result = x + y
"""

let module2 = try parsePython(source2)
let finder = VariableFinder()
module2.accept(visitor: finder)

print("\nVariables found:")
for (name, kind) in finder.variables.sorted(by: { $0.key < $1.key }) {
    print("  \(name): \(kind)")
}

// Example 3: Collect all imports
let source3 = """
import os
import sys
from math import sqrt, pi
from typing import List, Dict
"""

let module3 = try parsePython(source3)
let importCollector = ImportCollector()
module3.accept(visitor: importCollector)

print("\nImports found:")
for imp in importCollector.imports.sorted() {
    print("  \(imp)")
}

// Example 4: Custom visitor - count return statements
class ReturnCounter: ASTVisitor {
    var count = 0
    
    func visit(_ node: Return) {
        count += 1
    }
}

let source4 = """
def foo():
    if True:
        return 1
    return 2

def bar():
    return 3
"""

let module4 = try parsePython(source4)
let returnCounter = ReturnCounter()
module4.accept(visitor: returnCounter)

print("\nReturn statements: \(returnCounter.count)")  // 3

// Example 5: Find all function calls
let source5 = """
print("hello")
len([1, 2, 3])
result = str(42)
obj.method()
"""

let module5 = try parsePython(source5)
let callFinder = CallFinder()
module5.accept(visitor: callFinder)

print("\nFunction calls found:")
for call in callFinder.calls {
    print("  \(call)")
}
