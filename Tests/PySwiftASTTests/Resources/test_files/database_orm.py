"""
Database ORM with metaclasses, descriptors, and context managers.
"""
from typing import Any, Dict, List, Optional, Type, TypeVar, ClassVar
from abc import ABC, abstractmethod
import sqlite3
from contextlib import contextmanager

T = TypeVar('T', bound='Model')

class Field:
    def __init__(self, field_type: str, primary_key: bool = False, nullable: bool = True):
        self.field_type = field_type
        self.primary_key = primary_key
        self.nullable = nullable
        self.name = None
    
    def __set_name__(self, owner, name):
        self.name = name
    
    def __get__(self, obj, objtype=None):
        if obj is None:
            return self
        return obj.__dict__.get(self.name)
    
    def __set__(self, obj, value):
        if value is None and not self.nullable:
            raise ValueError(f"Field {self.name} cannot be null")
        obj.__dict__[self.name] = value

class IntegerField(Field):
    def __init__(self, primary_key: bool = False, nullable: bool = True):
        super().__init__('INTEGER', primary_key, nullable)

class TextField(Field):
    def __init__(self, max_length: Optional[int] = None, nullable: bool = True):
        super().__init__('TEXT', nullable=nullable)
        self.max_length = max_length
    
    def __set__(self, obj, value):
        if value is not None and self.max_length and len(value) > self.max_length:
            raise ValueError(f"Text too long: {len(value)} > {self.max_length}")
        super().__set__(obj, value)

class BooleanField(Field):
    def __init__(self, default: bool = False, nullable: bool = True):
        super().__init__('INTEGER', nullable=nullable)
        self.default = default

class ModelMeta(type):
    def __new__(mcs, name, bases, namespace):
        if name == 'Model':
            return super().__new__(mcs, name, bases, namespace)
        
        fields = {}
        for key, value in namespace.items():
            if isinstance(value, Field):
                fields[key] = value
        
        namespace['_fields'] = fields
        namespace['_table_name'] = namespace.get('_table_name', name.lower())
        
        cls = super().__new__(mcs, name, bases, namespace)
        return cls

class Model(metaclass=ModelMeta):
    _fields: ClassVar[Dict[str, Field]]
    _table_name: ClassVar[str]
    
    def __init__(self, **kwargs):
        for name, field in self._fields.items():
            value = kwargs.get(name)
            setattr(self, name, value)
    
    @classmethod
    def create_table(cls, connection: sqlite3.Connection):
        fields_sql = []
        for name, field in cls._fields.items():
            sql = f"{name} {field.field_type}"
            if field.primary_key:
                sql += " PRIMARY KEY"
            if not field.nullable:
                sql += " NOT NULL"
            fields_sql.append(sql)
        
        create_sql = f"CREATE TABLE IF NOT EXISTS {cls._table_name} ({', '.join(fields_sql)})"
        connection.execute(create_sql)
        connection.commit()
    
    def save(self, connection: sqlite3.Connection):
        field_names = list(self._fields.keys())
        values = [getattr(self, name) for name in field_names]
        placeholders = ', '.join(['?'] * len(field_names))
        
        sql = f"INSERT INTO {self._table_name} ({', '.join(field_names)}) VALUES ({placeholders})"
        cursor = connection.execute(sql, values)
        connection.commit()
        
        if hasattr(self, 'id') and self.id is None:
            self.id = cursor.lastrowid
    
    @classmethod
    def find_by_id(cls: Type[T], connection: sqlite3.Connection, id_value: int) -> Optional[T]:
        sql = f"SELECT * FROM {cls._table_name} WHERE id = ?"
        cursor = connection.execute(sql, (id_value,))
        row = cursor.fetchone()
        
        if row:
            field_names = list(cls._fields.keys())
            kwargs = {name: value for name, value in zip(field_names, row)}
            return cls(**kwargs)
        return None
    
    @classmethod
    def find_all(cls: Type[T], connection: sqlite3.Connection) -> List[T]:
        sql = f"SELECT * FROM {cls._table_name}"
        cursor = connection.execute(sql)
        rows = cursor.fetchall()
        
        field_names = list(cls._fields.keys())
        results = []
        for row in rows:
            kwargs = {name: value for name, value in zip(field_names, row)}
            results.append(cls(**kwargs))
        return results
    
    def __repr__(self):
        field_strs = [f"{name}={getattr(self, name)!r}" for name in self._fields]
        return f"{self.__class__.__name__}({', '.join(field_strs)})"

class User(Model):
    _table_name = 'users'
    
    id = IntegerField(primary_key=True)
    username = TextField(max_length=50, nullable=False)
    email = TextField(nullable=False)
    is_active = BooleanField(default=True)

class Post(Model):
    _table_name = 'posts'
    
    id = IntegerField(primary_key=True)
    user_id = IntegerField(nullable=False)
    title = TextField(max_length=200, nullable=False)
    content = TextField()
    published = BooleanField(default=False)

@contextmanager
def database_connection(db_path: str):
    conn = sqlite3.connect(db_path)
    try:
        yield conn
    finally:
        conn.close()

def main():
    with database_connection(':memory:') as conn:
        User.create_table(conn)
        Post.create_table(conn)
        
        user = User(id=None, username='alice', email='alice@example.com', is_active=True)
        user.save(conn)
        
        post = Post(id=None, user_id=user.id, title='Hello World', content='My first post!', published=True)
        post.save(conn)
        
        found_user = User.find_by_id(conn, user.id)
        print(f"Found user: {found_user}")
        
        all_posts = Post.find_all(conn)
        print(f"All posts: {all_posts}")

if __name__ == '__main__':
    main()
