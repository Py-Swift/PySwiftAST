"""
Real-world API client with async/await, error handling, and type hints.
"""
from typing import Optional, Dict, List, Any, TypeVar, Generic
from dataclasses import dataclass
import asyncio
import json

T = TypeVar('T')

@dataclass
class APIResponse(Generic[T]):
    status: int
    data: Optional[T]
    error: Optional[str] = None
    headers: Dict[str, str] = None

class RateLimiter:
    def __init__(self, max_requests: int, window: float):
        self.max_requests = max_requests
        self.window = window
        self.requests: List[float] = []
    
    async def acquire(self):
        now = asyncio.get_event_loop().time()
        self.requests = [t for t in self.requests if now - t < self.window]
        
        if len(self.requests) >= self.max_requests:
            wait_time = self.window - (now - self.requests[0])
            await asyncio.sleep(wait_time)
        
        self.requests.append(now)

class APIClient:
    def __init__(self, base_url: str, api_key: str, rate_limit: int = 100):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.limiter = RateLimiter(rate_limit, 60.0)
        self.session = None
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    def _build_headers(self, extra: Optional[Dict[str, str]] = None) -> Dict[str, str]:
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json',
            'User-Agent': 'PySwiftAST/1.0'
        }
        if extra:
            headers.update(extra)
        return headers
    
    async def get(self, endpoint: str, params: Optional[Dict[str, Any]] = None) -> APIResponse[Dict]:
        await self.limiter.acquire()
        
        url = f'{self.base_url}/{endpoint.lstrip("/")}'
        headers = self._build_headers()
        
        try:
            response = await self._make_request('GET', url, headers=headers, params=params)
            data = await response.json()
            return APIResponse(status=response.status, data=data)
        except Exception as e:
            return APIResponse(status=500, data=None, error=str(e))
    
    async def post(self, endpoint: str, data: Dict[str, Any]) -> APIResponse[Dict]:
        await self.limiter.acquire()
        
        url = f'{self.base_url}/{endpoint.lstrip("/")}'
        headers = self._build_headers()
        
        try:
            response = await self._make_request('POST', url, headers=headers, json=data)
            result = await response.json()
            return APIResponse(status=response.status, data=result)
        except Exception as e:
            return APIResponse(status=500, data=None, error=str(e))
    
    async def batch_get(self, endpoints: List[str]) -> List[APIResponse[Dict]]:
        tasks = [self.get(endpoint) for endpoint in endpoints]
        return await asyncio.gather(*tasks, return_exceptions=True)

async def main():
    async with APIClient('https://api.example.com', 'secret-key') as client:
        user_response = await client.get('/users/123')
        
        if user_response.status == 200 and user_response.data:
            user = user_response.data
            print(f"User: {user['name']}, Email: {user['email']}")
        
        batch_results = await client.batch_get(['/posts/1', '/posts/2', '/posts/3'])
        successful = [r for r in batch_results if isinstance(r, APIResponse) and r.status == 200]
        print(f"Fetched {len(successful)}/{len(batch_results)} posts successfully")

if __name__ == '__main__':
    asyncio.run(main())
