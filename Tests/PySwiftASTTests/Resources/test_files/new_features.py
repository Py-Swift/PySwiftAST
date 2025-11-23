# Test file for all newly implemented features

# 1. Class inheritance
class Animal:
    pass

class Dog(Animal):
    pass

class Cat(Animal, metaclass=type):
    pass

# 2. If-expressions (ternary operator)
x = 5
y = 10 if x > 3 else 20
z = "positive" if x > 0 else "zero" if x == 0 else "negative"

# 3. Elif chains
if x > 10:
    print("large")
elif x > 5:
    print("medium")
elif x > 0:
    print("small")
else:
    print("zero or negative")

# 4. Ellipsis literal
def unimplemented():
    ...

# 5. Different number formats
hex_num = 0xFF
binary_num = 0b1010
octal_num = 0o777
float_num = 3.14159
complex_num = 1 + 2j
scientific = 1.5e10

# 6. Type annotations - variables
name: str = "Alice"
age: int = 30
height: float
scores: list[int] = [95, 87, 92]

# 7. Type annotations - functions
def greet(name: str, age: int = 0) -> str:
    return f"Hello {name}"

def process_data(
    data: list[int],
    *args: int,
    verbose: bool = False,
    **kwargs: str
) -> dict[str, int]:
    return {}

async def fetch(url: str) -> bytes:
    return b""

# 8. Assignment target validation
valid_target = 42  # This should work
# 5 = invalid  # This would fail (uncomment to test)
