# Type annotations and type parameters (Python 3.12+)
def greet(name: str) -> str:
    return f"Hello, {name}!"

def add(a: int, b: int) -> int:
    return a + b

def process_items(items: list[str]) -> dict[str, int]:
    return {item: len(item) for item in items}

# Type alias (Python 3.12+)
type Point = tuple[float, float]
type Vector = list[float]
type Matrix[T] = list[list[T]]

# Generic functions with type parameters
def first[T](items: list[T]) -> T:
    return items[0]

def make_pair[T, U](a: T, b: U) -> tuple[T, U]:
    return (a, b)

# Class with type parameters
class Box[T]:
    def __init__(self, value: T):
        self.value = value
    
    def get(self) -> T:
        return self.value
