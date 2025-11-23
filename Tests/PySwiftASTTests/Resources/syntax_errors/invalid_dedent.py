# Invalid dedent level
def foo():
    if True:
        x = 1
      y = 2  # Dedent to invalid level (not aligned with any previous indent)
    return x + y
