# Decorators
@property
def name(self):
    return self._name

@name.setter
def name(self, value):
    self._name = value

@staticmethod
def static_method():
    return "static"

@classmethod
def class_method(cls):
    return cls()

@lru_cache(maxsize=128)
def fibonacci(n):
    if n < 2:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

@dataclass
class Person:
    name: str
    age: int
    email: str = ""

@app.route("/api/users")
@require_auth
def get_users():
    return users
