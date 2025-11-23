# Complex real-world example
from typing import Optional, List, Dict
from dataclasses import dataclass
from functools import lru_cache

@dataclass
class User:
    id: int
    name: str
    email: str
    age: Optional[int] = None

class UserRepository:
    def __init__(self, db_connection):
        self._db = db_connection
        self._cache: Dict[int, User] = {}
    
    @lru_cache(maxsize=100)
    def get_user(self, user_id: int) -> Optional[User]:
        if user_id in self._cache:
            return self._cache[user_id]
        
        try:
            with self._db.cursor() as cursor:
                cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
                row = cursor.fetchone()
                
                if row:
                    user = User(
                        id=row["id"],
                        name=row["name"],
                        email=row["email"],
                        age=row.get("age")
                    )
                    self._cache[user_id] = user
                    return user
        except Exception as e:
            print(f"Error fetching user {user_id}: {e}")
            raise
        
        return None
    
    async def get_users(self, filters: Optional[Dict] = None) -> List[User]:
        query = "SELECT * FROM users"
        params = []
        
        if filters:
            conditions = [f"{k} = ?" for k in filters.keys()]
            query += " WHERE " + " AND ".join(conditions)
            params = list(filters.values())
        
        async with self._db.cursor() as cursor:
            await cursor.execute(query, params)
            rows = await cursor.fetchall()
            
            return [
                User(
                    id=row["id"],
                    name=row["name"],
                    email=row["email"],
                    age=row.get("age")
                )
                for row in rows
            ]

def main():
    repo = UserRepository(get_db_connection())
    
    # Get single user
    user = repo.get_user(1)
    if user:
        print(f"Found user: {user.name}")
    
    # Async get all users
    users = await repo.get_users({"age": 30})
    print(f"Found {len(users)} users aged 30")

if __name__ == "__main__":
    main()
