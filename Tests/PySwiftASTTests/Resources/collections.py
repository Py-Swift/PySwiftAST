# Collections and data structures
# Lists
numbers = [1, 2, 3, 4, 5]
mixed = [1, "two", 3.0, True, None]
nested = [[1, 2], [3, 4], [5, 6]]

# Tuples
point = (10, 20)
single = (1,)
unpacking = a, b, c = 1, 2, 3

# Sets
unique = {1, 2, 3, 4, 5}
empty_set = set()

# Dictionaries
person = {"name": "Alice", "age": 30, "city": "NYC"}
nested_dict = {
    "user1": {"name": "Alice", "score": 100},
    "user2": {"name": "Bob", "score": 95}
}

# Dictionary unpacking
merged = {**dict1, **dict2}

# Starred expressions
first, *rest = [1, 2, 3, 4, 5]
*start, last = [1, 2, 3, 4, 5]
a, *middle, b = [1, 2, 3, 4, 5]

# Slicing
sublist = numbers[1:4]
reversed_list = numbers[::-1]
every_other = numbers[::2]
