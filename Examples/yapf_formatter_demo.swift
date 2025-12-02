import PySwiftAST
import PySwiftCodeGen
import PyFormatters

// Example: Using YAPFFormatter for PEP 8 compliant formatting

let code = """
import os
import sys
MY_CONSTANT = 42
class Calculator:
    def add(self, a, b):
        def inner():
            return a + b
        return inner()
    def subtract(self, a, b):
        return a - b
def main():
    calc = Calculator()
    print(calc.add(1, 2))
main()
"""

// Parse the code
let parser = Parser(code)
let module = try! parser.parseModule()

// Format with YAPF style (PEP 8 compliant)
let formatter = YAPFFormatter()
let formatted = formatter.formatDeep(module)

// Generate formatted Python code
print("=== YAPF Formatted (PEP 8) ===")
print(formatted.toPython())

/* Expected output:
=== YAPF Formatted (PEP 8) ===
import os
import sys

MY_CONSTANT = 42


class Calculator:

    def add(self, a, b):

        def inner():
            return a + b

        return inner()

    def subtract(self, a, b):
        return a - b


def main():
    calc = Calculator()
    print(calc.add(1, 2))


main()
*/
