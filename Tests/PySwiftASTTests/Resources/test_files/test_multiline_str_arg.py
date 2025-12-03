raise TypeError(
    "Expected an Arrow-compatible tabular object (i.e. having an "
    "'_arrow_c_array__' or '__arrow_c_stream__' method), got "
    f"'{type(data).__name__}' instead."
)
