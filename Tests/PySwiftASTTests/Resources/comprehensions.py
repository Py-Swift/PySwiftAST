# List comprehensions
squares = [x**2 for x in range(10)]
evens = [x for x in range(20) if x % 2 == 0]
matrix = [[i * j for j in range(3)] for i in range(3)]

# Set comprehensions
unique_squares = {x**2 for x in range(-5, 6)}

# Dict comprehensions
square_dict = {x: x**2 for x in range(5)}
filtered_dict = {k: v for k, v in data.items() if v > 0}

# Generator expressions
gen = (x**2 for x in range(100))
filtered_gen = (x for x in range(1000) if x % 7 == 0)
