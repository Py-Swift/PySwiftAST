# F-strings and string formatting
name = "World"
age = 30

# Basic f-strings
greeting = f"Hello, {name}!"
message = f"{name} is {age} years old"

# F-strings with expressions
result = f"2 + 2 = {2 + 2}"
formatted = f"Pi is approximately {3.14159:.2f}"
aligned = f"{name:>10}"

# Multi-line f-strings
text = f"""
Name: {name}
Age: {age}
Status: {"Adult" if age >= 18 else "Minor"}
"""

# F-strings with debugging (Python 3.8+)
x = 42
debug = f"{x=}"  # prints "x=42"

# Nested f-strings
nested = f"Result: {f'{x * 2}'}"
