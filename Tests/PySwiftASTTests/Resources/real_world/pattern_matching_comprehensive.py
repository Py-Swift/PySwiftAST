"""
Comprehensive Pattern Matching (match/case) Examples
Python 3.10+ feature testing with all pattern types
"""
from typing import Union, List, Tuple, Dict, Any
from dataclasses import dataclass
from enum import Enum, auto


# Enums for pattern matching
class HTTPStatus(Enum):
    OK = 200
    CREATED = 201
    BAD_REQUEST = 400
    UNAUTHORIZED = 401
    FORBIDDEN = 403
    NOT_FOUND = 404
    SERVER_ERROR = 500


class Command(Enum):
    START = auto()
    STOP = auto()
    RESTART = auto()
    STATUS = auto()


# Dataclasses for structural pattern matching
@dataclass
class Point:
    x: int
    y: int


@dataclass
class Circle:
    center: Point
    radius: float


@dataclass
class Rectangle:
    top_left: Point
    width: float
    height: float


@dataclass
class User:
    name: str
    age: int
    role: str = "user"


# Basic literal pattern matching
def check_status_code(code: int) -> str:
    """Match against literal values"""
    match code:
        case 200:
            return "OK"
        case 201:
            return "Created"
        case 400:
            return "Bad Request"
        case 401:
            return "Unauthorized"
        case 403:
            return "Forbidden"
        case 404:
            return "Not Found"
        case 500:
            return "Internal Server Error"
        case _:
            return f"Unknown status: {code}"


# Enum pattern matching
def handle_command(cmd: Command) -> str:
    """Match against enum values"""
    match cmd:
        case Command.START:
            return "Starting service..."
        case Command.STOP:
            return "Stopping service..."
        case Command.RESTART:
            return "Restarting service..."
        case Command.STATUS:
            return "Checking status..."
        case _:
            return "Unknown command"


# Sequence pattern matching
def process_coordinates(coord: Tuple) -> str:
    """Match sequence patterns"""
    match coord:
        case (0, 0):
            return "Origin"
        case (0, y):
            return f"On Y-axis at {y}"
        case (x, 0):
            return f"On X-axis at {x}"
        case (x, y):
            return f"Point at ({x}, {y})"
        case _:
            return "Invalid coordinates"


def analyze_list(items: List) -> str:
    """Match list patterns with length"""
    match items:
        case []:
            return "Empty list"
        case [x]:
            return f"Single item: {x}"
        case [x, y]:
            return f"Two items: {x} and {y}"
        case [first, *rest]:
            return f"First: {first}, Rest: {rest}"
        case _:
            return "Unknown pattern"


def process_tuple_patterns(data: Tuple) -> str:
    """Match various tuple patterns"""
    match data:
        case (0, 0, 0):
            return "Origin in 3D"
        case (x, y, 0):
            return f"Point in XY plane: ({x}, {y})"
        case (x, 0, z):
            return f"Point in XZ plane: ({x}, {z})"
        case (0, y, z):
            return f"Point in YZ plane: ({y}, {z})"
        case (x, y, z):
            return f"3D point: ({x}, {y}, {z})"
        case _:
            return "Invalid 3D coordinates"


# Mapping pattern matching
def process_config(config: Dict[str, Any]) -> str:
    """Match dictionary patterns"""
    match config:
        case {"type": "database", "host": host, "port": port}:
            return f"Database at {host}:{port}"
        case {"type": "cache", "ttl": ttl}:
            return f"Cache with TTL: {ttl}"
        case {"type": "api", "url": url, "timeout": timeout}:
            return f"API at {url} with timeout {timeout}s"
        case {"type": config_type}:
            return f"Unknown config type: {config_type}"
        case _:
            return "Invalid configuration"


def extract_user_info(data: Dict) -> str:
    """Match with partial dictionary patterns"""
    match data:
        case {"name": name, "email": email, "admin": True}:
            return f"Admin user: {name} ({email})"
        case {"name": name, "email": email}:
            return f"Regular user: {name} ({email})"
        case {"name": name}:
            return f"User: {name} (no email)"
        case _:
            return "Invalid user data"


# Class pattern matching
def describe_shape(shape: Union[Circle, Rectangle, Point]) -> str:
    """Match against class instances"""
    match shape:
        case Point(x=0, y=0):
            return "Origin point"
        case Point(x=x, y=y) if x == y:
            return f"Diagonal point at ({x}, {y})"
        case Point(x=x, y=y):
            return f"Point at ({x}, {y})"
        case Circle(center=Point(x=0, y=0), radius=r):
            return f"Circle centered at origin with radius {r}"
        case Circle(center=center, radius=r):
            return f"Circle at {center} with radius {r}"
        case Rectangle(top_left=Point(x=x, y=y), width=w, height=h):
            return f"Rectangle at ({x}, {y}) with size {w}x{h}"
        case _:
            return "Unknown shape"


# Guard clauses (if conditions in patterns)
def categorize_number(n: int) -> str:
    """Pattern matching with guards"""
    match n:
        case 0:
            return "Zero"
        case n if n < 0:
            return "Negative"
        case n if n > 0 and n <= 10:
            return "Small positive"
        case n if n > 10 and n <= 100:
            return "Medium positive"
        case n if n > 100:
            return "Large positive"
        case _:
            return "Unknown"


def validate_user_age(user: User) -> str:
    """Pattern matching with multiple guards"""
    match user:
        case User(name=name, age=age) if age < 0:
            return f"Invalid age for {name}"
        case User(name=name, age=age) if age < 13:
            return f"{name} is a child ({age} years)"
        case User(name=name, age=age) if age < 18:
            return f"{name} is a teenager ({age} years)"
        case User(name=name, age=age, role="admin") if age >= 18:
            return f"{name} is an adult admin ({age} years)"
        case User(name=name, age=age) if age >= 18:
            return f"{name} is an adult ({age} years)"
        case _:
            return "Unknown user"


# OR patterns
def check_boundary_value(x: int) -> str:
    """Match multiple patterns with |"""
    match x:
        case 0 | 1:
            return "Zero or one"
        case 10 | 20 | 30:
            return "Multiple of 10 (10, 20, or 30)"
        case 100 | 200 | 300:
            return "Hundreds"
        case _:
            return "Other value"


def check_direction(coord: Tuple[int, int]) -> str:
    """OR patterns with tuples"""
    match coord:
        case (0, 1) | (0, -1):
            return "Vertical movement"
        case (1, 0) | (-1, 0):
            return "Horizontal movement"
        case (1, 1) | (-1, -1) | (1, -1) | (-1, 1):
            return "Diagonal movement"
        case (0, 0):
            return "No movement"
        case _:
            return "Complex movement"


# AS patterns (capture patterns)
def process_nested_list(data: List) -> str:
    """Use 'as' to capture sub-patterns"""
    match data:
        case [x, y] as pair:
            return f"Pair {pair}: {x} and {y}"
        case [first, *rest] as full_list:
            return f"List {full_list}: first={first}, rest={rest}"
        case _:
            return "Not a list pattern"


def analyze_nested_structure(obj: Any) -> str:
    """Capture nested patterns"""
    match obj:
        case {"type": "user", "data": {"name": name, "age": age} as user_data}:
            return f"User data: {user_data}, name={name}, age={age}"
        case {"type": "config", "settings": settings as s}:
            return f"Config with settings: {s}"
        case _:
            return "Unknown structure"


# Nested pattern matching
def parse_json_response(response: Dict) -> str:
    """Complex nested pattern matching"""
    match response:
        case {
            "status": "success",
            "data": {
                "user": {"id": user_id, "name": name},
                "items": [*items]
            }
        }:
            return f"Success: User {name} (ID: {user_id}) with {len(items)} items"
        
        case {
            "status": "error",
            "error": {"code": code, "message": msg}
        }:
            return f"Error {code}: {msg}"
        
        case {"status": "pending"}:
            return "Request pending"
        
        case _:
            return "Unknown response format"


def process_command_args(cmd: List) -> str:
    """Match command line argument patterns"""
    match cmd:
        case ["git", "clone", url]:
            return f"Cloning repository: {url}"
        case ["git", "commit", "-m", message]:
            return f"Committing with message: {message}"
        case ["git", "push", remote, branch]:
            return f"Pushing to {remote}/{branch}"
        case ["git", "pull"]:
            return "Pulling from default remote"
        case ["git", *args]:
            return f"Git command with args: {args}"
        case _:
            return "Not a git command"


# Complex real-world example
def route_http_request(request: Dict[str, Any]) -> str:
    """Pattern match HTTP request routing"""
    match request:
        # GET requests
        case {
            "method": "GET",
            "path": "/",
            "headers": headers
        }:
            return "Home page"
        
        case {
            "method": "GET",
            "path": path,
            "query": {"id": user_id}
        } if path.startswith("/users/"):
            return f"Get user {user_id}"
        
        case {
            "method": "GET",
            "path": "/api/v1/users",
            "query": {"page": page, "limit": limit}
        }:
            return f"List users: page {page}, limit {limit}"
        
        # POST requests
        case {
            "method": "POST",
            "path": "/api/v1/users",
            "body": {"name": name, "email": email}
        }:
            return f"Create user: {name} ({email})"
        
        case {
            "method": "POST",
            "path": path,
            "body": body
        } if path.startswith("/api/"):
            return f"POST to {path} with body"
        
        # PUT/PATCH requests
        case {
            "method": "PUT" | "PATCH",
            "path": path,
            "body": updates
        }:
            return f"Update {path}: {updates}"
        
        # DELETE requests
        case {
            "method": "DELETE",
            "path": path
        }:
            return f"Delete resource at {path}"
        
        # Error cases
        case {"method": method} if method not in ["GET", "POST", "PUT", "PATCH", "DELETE"]:
            return f"Invalid HTTP method: {method}"
        
        case _:
            return "Invalid request format"


# Wildcard and capture combinations
def complex_pattern_example(data: Any) -> str:
    """Demonstrate various pattern combinations"""
    match data:
        # Exact match
        case [1, 2, 3]:
            return "Exact sequence [1, 2, 3]"
        
        # Capture with wildcard
        case [1, _, 3]:
            return "Sequence [1, any, 3]"
        
        # Multiple wildcards
        case [_, _, _]:
            return "Any 3-element sequence"
        
        # Star pattern with capture
        case [first, *middle, last]:
            return f"First: {first}, Middle: {middle}, Last: {last}"
        
        # Nested patterns
        case [[x, y], [a, b]]:
            return f"2x2 matrix: [{x}, {y}], [{a}, {b}]"
        
        # Mixed patterns
        case {"key": [x, *rest], "value": v}:
            return f"Dict with list key: first={x}, rest={rest}, value={v}"
        
        case _:
            return "No match"


# Testing function
def test_all_patterns():
    """Test all pattern matching examples"""
    print("=== Literal Patterns ===")
    print(check_status_code(200))
    print(check_status_code(404))
    print(check_status_code(999))
    
    print("\n=== Enum Patterns ===")
    print(handle_command(Command.START))
    print(handle_command(Command.STATUS))
    
    print("\n=== Sequence Patterns ===")
    print(process_coordinates((0, 0)))
    print(process_coordinates((5, 0)))
    print(process_coordinates((3, 4)))
    
    print("\n=== List Patterns ===")
    print(analyze_list([]))
    print(analyze_list([1]))
    print(analyze_list([1, 2, 3, 4, 5]))
    
    print("\n=== Mapping Patterns ===")
    print(process_config({"type": "database", "host": "localhost", "port": 5432}))
    print(process_config({"type": "cache", "ttl": 3600}))
    
    print("\n=== Class Patterns ===")
    print(describe_shape(Point(0, 0)))
    print(describe_shape(Circle(Point(0, 0), 5.0)))
    print(describe_shape(Rectangle(Point(10, 20), 100, 50)))
    
    print("\n=== Guard Patterns ===")
    print(categorize_number(0))
    print(categorize_number(-5))
    print(categorize_number(5))
    print(categorize_number(50))
    
    print("\n=== OR Patterns ===")
    print(check_boundary_value(0))
    print(check_boundary_value(10))
    print(check_direction((0, 1)))
    print(check_direction((1, 1)))
    
    print("\n=== Nested Patterns ===")
    response = {
        "status": "success",
        "data": {
            "user": {"id": 123, "name": "Alice"},
            "items": ["a", "b", "c"]
        }
    }
    print(parse_json_response(response))
    
    print("\n=== HTTP Routing ===")
    request = {
        "method": "GET",
        "path": "/api/v1/users",
        "query": {"page": 1, "limit": 10}
    }
    print(route_http_request(request))


if __name__ == "__main__":
    test_all_patterns()
