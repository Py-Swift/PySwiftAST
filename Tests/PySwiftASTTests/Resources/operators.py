# Operators and expressions
# Arithmetic
result = 10 + 5 - 3 * 2 / 4 // 2 % 3 ** 2

# Comparison
is_equal = x == y
is_not_equal = x != y
is_greater = x > y
is_less = x < y
is_ge = x >= y
is_le = x <= y

# Logical
and_result = True and False
or_result = True or False
not_result = not True

# Bitwise
bit_and = 5 & 3
bit_or = 5 | 3
bit_xor = 5 ^ 3
bit_not = ~5
left_shift = 5 << 1
right_shift = 5 >> 1

# Assignment operators
x += 1
x -= 1
x *= 2
x /= 2
x //= 2
x %= 2
x **= 2
x &= 1
x |= 1
x ^= 1
x <<= 1
x >>= 1

# Walrus operator (Python 3.8+)
if (n := len(data)) > 10:
    print(f"Large dataset: {n} items")

# Ternary operator
max_val = a if a > b else b
