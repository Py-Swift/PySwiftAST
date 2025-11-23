# Exception handling
try:
    x = 1 / 0
except ZeroDivisionError:
    print("Cannot divide by zero")

try:
    dangerous_operation()
except ValueError as e:
    print(f"Value error: {e}")
except Exception:
    print("Unknown error")
finally:
    cleanup()

raise ValueError("Something went wrong")

assert x > 0, "x must be positive"
