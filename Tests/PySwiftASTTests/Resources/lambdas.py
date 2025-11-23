# Lambda expressions
square = lambda x: x**2
add = lambda a, b: a + b
greet = lambda name: f"Hello, {name}!"

# Lambda in higher-order functions
numbers = [1, 2, 3, 4, 5]
doubled = list(map(lambda x: x * 2, numbers))
evens = list(filter(lambda x: x % 2 == 0, numbers))
product = reduce(lambda x, y: x * y, numbers)

# Lambda with default arguments
func = lambda x, y=10: x + y
