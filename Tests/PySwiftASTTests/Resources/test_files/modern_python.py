# Modern Python Features Test File
# Tests f-strings, type hints, and other recent additions

from typing import Union, Optional
from dataclasses import dataclass

# Type alias with Python 3.12+ syntax
type Point = tuple[int, int]
type Result = str | None

# F-strings with conversion specifiers
def debug_repr(obj):
    """Test f-string conversion specifiers"""
    # !r for repr, !s for str, !a for ascii
    debug_info = f"Object: {obj!r}, String: {obj!s}, ASCII: {obj!a}"
    return debug_info

# F-strings with format specs
def format_numbers(value: float, count: int):
    """Test f-string format specifications"""
    formatted = f"Value: {value:.2f}, Count: {count:04d}"
    percentage = f"Percent: {value * 100:.1f}%"
    return formatted, percentage

# Mixed f-string and regular string concatenation
def create_warning(name: str, error_type: type):
    """Test mixed string concatenation"""
    message = (
        f"Warning: {name} encountered "
        f"error of type {error_type.__name__} "
        "which is not recoverable. "
        "Please check the documentation."
    )
    return message

# Type annotations with union syntax
def process_data(data: str | int | None) -> dict[str, Union[str, int]]:
    """Test union type annotations"""
    if data is None:
        return {}
    return {"value": data, "type": type(data).__name__}

# Relative imports pattern
def import_example():
    """Demonstrates that .. in imports works"""
    # These would be actual imports in a package:
    # from ..parent import something
    # from ...grandparent import other_thing
    pass

# Dictionary with comments
def create_config():
    """Test comments in dictionary literals"""
    config = {
        "host": "localhost",
        # Production settings
        "port": 8080,
        "debug": False,
        # Advanced options
        "timeout": 30,
    }
    return config

# Function call with comments in arguments
def complex_call():
    """Test comments in function arguments"""
    result = some_function(
        arg1="value1",
        # This is an important parameter
        arg2="value2",
        arg3="value3",
        # More configuration
        arg4="value4",
    )
    return result

# Chained method calls with f-strings
def chain_methods(text: str, replacement: str | None = None):
    """Test method chaining with type hints"""
    result = (
        text.strip()
        .lower()
        .replace(" ", "_")
        .replace("-", "_")
    )
    if replacement:
        result = f"modified_{result}_{replacement}"
    return result

# Raw strings in function calls
def html_escape(html: str) -> str:
    """Test raw strings in method calls"""
    escaped = html.replace("<", r"&lt;")
    escaped = escaped.replace(">", r"&gt;")
    escaped = escaped.replace("&", r"&amp;")
    return escaped

# Set with comments
def create_tags():
    """Test comments in set literals"""
    tags = {
        "python",
        # Important tags
        "swift",
        "parser",
        # Additional categories
        "ast",
        "compiler",
    }
    return tags

@dataclass
class Config:
    """Test dataclass with type hints"""
    name: str
    value: int | float
    description: Optional[str] = None
    
    def to_dict(self) -> dict[str, str | int | float | None]:
        """Convert to dictionary with union return type"""
        return {
            "name": self.name,
            "value": self.value,
            "description": self.description,
        }

# Complex f-string with method calls and attributes
def describe_object(obj):
    """Test complex f-string expressions"""
    description = f"Object of type {type(obj).__name__} with id {id(obj)}"
    if hasattr(obj, "__dict__"):
        attrs = f"Attributes: {list(obj.__dict__.keys())!r}"
        description = f"{description}. {attrs}"
    return description

if __name__ == "__main__":
    # Test various features
    print(debug_repr({"key": "value"}))
    print(format_numbers(3.14159, 42))
    print(create_warning("test", ValueError))
    print(process_data(123))
    print(html_escape("<div>Hello & goodbye</div>"))
    print(describe_object(Config("test", 42)))
