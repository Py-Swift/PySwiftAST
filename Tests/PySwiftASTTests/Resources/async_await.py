# Async/await syntax
async def fetch_data(url):
    response = await http_client.get(url)
    return response.json()

async def main():
    tasks = [fetch_data(url) for url in urls]
    results = await asyncio.gather(*tasks)
    return results

# Async generators
async def async_range(count):
    for i in range(count):
        await asyncio.sleep(0.1)
        yield i

# Async comprehensions
async def process():
    results = [await fetch(url) async for url in urls]
    return results
