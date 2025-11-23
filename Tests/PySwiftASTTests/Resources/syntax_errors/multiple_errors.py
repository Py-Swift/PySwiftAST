# Multiple syntax errors in one file
def broken_function()  # Missing colon
    x = "unclosed string
    if x == 1  # Missing colon
        print(x)
   y = 2  # Wrong indentation
    return x + y
