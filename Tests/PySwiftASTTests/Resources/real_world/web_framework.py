"""
Web API Framework Example
Features: FastAPI-style decorators, type hints, async, multiple inheritance, metaclasses
"""
from typing import (
    Any, Dict, List, Optional, Union, Callable, TypeVar, Generic,
    Protocol, runtime_checkable, Literal, Annotated, get_type_hints
)
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum
import asyncio
from functools import wraps
import inspect


# Type definitions
T = TypeVar('T')
Response = Dict[str, Any]
Handler = Callable[..., Union[Response, asyncio.Future[Response]]]


class HTTPMethod(str, Enum):
    """HTTP method types"""
    GET = "GET"
    POST = "POST"
    PUT = "PUT"
    DELETE = "DELETE"
    PATCH = "PATCH"
    OPTIONS = "OPTIONS"


@runtime_checkable
class Middleware(Protocol):
    """Protocol for middleware components"""
    
    async def process_request(self, request: 'Request') -> Optional['Request']:
        ...
    
    async def process_response(self, response: 'Response') -> 'Response':
        ...


@dataclass
class Request:
    """HTTP Request representation"""
    method: HTTPMethod
    path: str
    headers: Dict[str, str] = field(default_factory=dict)
    query_params: Dict[str, str] = field(default_factory=dict)
    body: Optional[Dict[str, Any]] = None
    
    @property
    def is_json(self) -> bool:
        return self.headers.get('Content-Type', '').startswith('application/json')
    
    def get_header(self, name: str, default: Optional[str] = None) -> Optional[str]:
        return self.headers.get(name.lower(), default)


@dataclass
class Response:
    """HTTP Response representation"""
    status_code: int = 200
    body: Dict[str, Any] = field(default_factory=dict)
    headers: Dict[str, str] = field(default_factory=dict)
    
    def set_header(self, name: str, value: str) -> 'Response':
        self.headers[name] = value
        return self
    
    def json(self) -> Dict[str, Any]:
        return {
            'status': self.status_code,
            'body': self.body,
            'headers': self.headers
        }


class Route:
    """Represents a single route in the application"""
    
    def __init__(
        self,
        path: str,
        method: HTTPMethod,
        handler: Handler,
        middleware: Optional[List[Middleware]] = None
    ):
        self.path = path
        self.method = method
        self.handler = handler
        self.middleware = middleware or []
        self._signature = inspect.signature(handler)
    
    async def execute(self, request: Request) -> Response:
        """Execute the route handler with middleware"""
        # Process request through middleware
        processed_request = request
        for mw in self.middleware:
            result = await mw.process_request(processed_request)
            if result is not None:
                processed_request = result
        
        # Execute handler
        if asyncio.iscoroutinefunction(self.handler):
            response = await self.handler(processed_request)
        else:
            response = self.handler(processed_request)
        
        # Process response through middleware (reversed)
        processed_response = response
        for mw in reversed(self.middleware):
            processed_response = await mw.process_response(processed_response)
        
        return processed_response
    
    def matches(self, path: str, method: HTTPMethod) -> bool:
        """Check if route matches path and method"""
        return self.path == path and self.method == method


class RouterMeta(type):
    """Metaclass for automatic route registration"""
    
    def __new__(mcs, name, bases, namespace, **kwargs):
        cls = super().__new__(mcs, name, bases, namespace)
        
        # Auto-register routes from decorated methods
        routes = []
        for attr_name in dir(cls):
            attr = getattr(cls, attr_name)
            if hasattr(attr, '_route_info'):
                route_info = attr._route_info
                routes.append((route_info['path'], route_info['method'], attr))
        
        cls._registered_routes = routes
        return cls


class Router(metaclass=RouterMeta):
    """Base router class with metaclass-based registration"""
    
    def __init__(self):
        self.routes: List[Route] = []
        self.middleware: List[Middleware] = []
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup routes from class definition"""
        if hasattr(self.__class__, '_registered_routes'):
            for path, method, handler in self.__class__._registered_routes:
                self.add_route(path, method, handler)
    
    def add_route(
        self,
        path: str,
        method: HTTPMethod,
        handler: Handler
    ) -> 'Router':
        """Add a route to the router"""
        route = Route(path, method, handler, middleware=self.middleware.copy())
        self.routes.append(route)
        return self
    
    def use(self, middleware: Middleware) -> 'Router':
        """Add middleware to router"""
        self.middleware.append(middleware)
        return self
    
    async def handle_request(self, request: Request) -> Response:
        """Handle incoming request"""
        for route in self.routes:
            if route.matches(request.path, request.method):
                return await route.execute(request)
        
        return Response(
            status_code=404,
            body={'error': 'Route not found', 'path': request.path}
        )


# Decorators for route registration
def route(path: str, method: HTTPMethod = HTTPMethod.GET):
    """Decorator for registering routes"""
    def decorator(func: Handler) -> Handler:
        func._route_info = {'path': path, 'method': method}
        return func
    return decorator


def get(path: str):
    """Shorthand for GET routes"""
    return route(path, HTTPMethod.GET)


def post(path: str):
    """Shorthand for POST routes"""
    return route(path, HTTPMethod.POST)


def put(path: str):
    """Shorthand for PUT routes"""
    return route(path, HTTPMethod.PUT)


def delete(path: str):
    """Shorthand for DELETE routes"""
    return route(path, HTTPMethod.DELETE)


# Dependency injection decorator
def inject_dependencies(**dependencies):
    """Decorator to inject dependencies into handler"""
    def decorator(func: Handler) -> Handler:
        @wraps(func)
        async def wrapper(request: Request) -> Response:
            # Get function signature and inject dependencies
            sig = inspect.signature(func)
            kwargs = {}
            
            for param_name, param in sig.parameters.items():
                if param_name == 'request':
                    kwargs[param_name] = request
                elif param_name in dependencies:
                    kwargs[param_name] = dependencies[param_name]
            
            if asyncio.iscoroutinefunction(func):
                return await func(**kwargs)
            else:
                return func(**kwargs)
        
        return wrapper
    return decorator


# Validation decorator
def validate_request(schema: Dict[str, type]):
    """Decorator to validate request body against schema"""
    def decorator(func: Handler) -> Handler:
        @wraps(func)
        async def wrapper(request: Request) -> Response:
            if request.body is None:
                return Response(
                    status_code=400,
                    body={'error': 'Request body required'}
                )
            
            # Validate schema
            errors = []
            for field, expected_type in schema.items():
                if field not in request.body:
                    errors.append(f"Missing required field: {field}")
                elif not isinstance(request.body[field], expected_type):
                    errors.append(
                        f"Invalid type for {field}: "
                        f"expected {expected_type.__name__}, "
                        f"got {type(request.body[field]).__name__}"
                    )
            
            if errors:
                return Response(
                    status_code=400,
                    body={'errors': errors}
                )
            
            if asyncio.iscoroutinefunction(func):
                return await func(request)
            else:
                return func(request)
        
        return wrapper
    return decorator


# Example application using the framework
class UserAPI(Router):
    """Example API with multiple routes"""
    
    def __init__(self):
        super().__init__()
        self.users: Dict[int, Dict[str, Any]] = {}
        self.next_id = 1
    
    @get('/users')
    async def list_users(self, request: Request) -> Response:
        """List all users"""
        limit = int(request.query_params.get('limit', 10))
        offset = int(request.query_params.get('offset', 0))
        
        users_list = list(self.users.values())[offset:offset + limit]
        
        return Response(
            status_code=200,
            body={
                'users': users_list,
                'total': len(self.users),
                'limit': limit,
                'offset': offset
            }
        )
    
    @get('/users/{id}')
    async def get_user(self, request: Request) -> Response:
        """Get a specific user"""
        user_id = int(request.path.split('/')[-1])
        
        if user_id not in self.users:
            return Response(
                status_code=404,
                body={'error': f'User {user_id} not found'}
            )
        
        return Response(
            status_code=200,
            body=self.users[user_id]
        )
    
    @post('/users')
    @validate_request({'name': str, 'email': str})
    async def create_user(self, request: Request) -> Response:
        """Create a new user"""
        user_data = request.body
        user_id = self.next_id
        self.next_id += 1
        
        user = {
            'id': user_id,
            'name': user_data['name'],
            'email': user_data['email'],
            'created_at': 'now'
        }
        
        self.users[user_id] = user
        
        return Response(
            status_code=201,
            body=user
        ).set_header('Location', f'/users/{user_id}')
    
    @put('/users/{id}')
    @validate_request({'name': str, 'email': str})
    async def update_user(self, request: Request) -> Response:
        """Update an existing user"""
        user_id = int(request.path.split('/')[-1])
        
        if user_id not in self.users:
            return Response(
                status_code=404,
                body={'error': f'User {user_id} not found'}
            )
        
        self.users[user_id].update(request.body)
        
        return Response(
            status_code=200,
            body=self.users[user_id]
        )
    
    @delete('/users/{id}')
    async def delete_user(self, request: Request) -> Response:
        """Delete a user"""
        user_id = int(request.path.split('/')[-1])
        
        if user_id not in self.users:
            return Response(
                status_code=404,
                body={'error': f'User {user_id} not found'}
            )
        
        del self.users[user_id]
        
        return Response(status_code=204, body={})


# Complex async operations
async def main():
    """Demonstration of the API framework"""
    api = UserAPI()
    
    # Create test requests
    requests = [
        Request(
            method=HTTPMethod.POST,
            path='/users',
            body={'name': 'Alice', 'email': 'alice@example.com'}
        ),
        Request(
            method=HTTPMethod.POST,
            path='/users',
            body={'name': 'Bob', 'email': 'bob@example.com'}
        ),
        Request(
            method=HTTPMethod.GET,
            path='/users',
            query_params={'limit': '10', 'offset': '0'}
        ),
    ]
    
    # Process requests concurrently
    responses = await asyncio.gather(*[
        api.handle_request(req) for req in requests
    ])
    
    # Print results
    for i, response in enumerate(responses):
        print(f"Request {i + 1}: {response.json()}")


if __name__ == '__main__':
    asyncio.run(main())
