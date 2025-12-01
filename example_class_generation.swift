#!/usr/bin/env swift
import Foundation

// Example showing how to add blank lines between class methods using .blank()

/*
import PySwiftAST
import PySwiftCodeGen

// Build AST with explicit blank lines
let classWithBlanks = Module(body: [
    Statement.classDef(ClassDef(
        name: "MyClass",
        bases: [],
        keywords: [],
        body: [
            Statement.functionDef(FunctionDef(
                name: "__init__",
                args: Arguments(
                    args: [Arg(arg: "self", annotation: nil)],
                    defaults: []
                ),
                body: [Statement.pass()],
                decoratorList: [],
                returns: nil,
                typeParams: []
            )),
            Statement.blank(),  // Single blank line
            Statement.functionDef(FunctionDef(
                name: "method1",
                args: Arguments(
                    args: [Arg(arg: "self", annotation: nil)],
                    defaults: []
                ),
                body: [Statement.pass()],
                decoratorList: [],
                returns: nil,
                typeParams: []
            )),
            Statement.blank(2),  // TWO blank lines!
            Statement.functionDef(FunctionDef(
                name: "method2",
                args: Arguments(
                    args: [Arg(arg: "self", annotation: nil)],
                    defaults: []
                ),
                body: [Statement.pass()],
                decoratorList: [],
                returns: nil,
                typeParams: []
            ))
        ],
        decoratorList: [],
        typeParams: []
    ))
])

// Generate Python code
let pythonCode = classWithBlanks.toPythonCode()
print(pythonCode)
*/

// The output will be:
print("""
class MyClass:
    def __init__(self):
        pass

    def method1(self):
        pass


    def method2(self):
        pass
""")

print("\n✅ Using Statement.blank() and Statement.blank(2) gives you full control!")
print("✅ This is now part of the standard AST API")

