# Context managers
with open("file.txt") as f:
    content = f.read()

with open("input.txt") as infile, open("output.txt", "w") as outfile:
    outfile.write(infile.read())

async with AsyncClient() as client:
    data = await client.fetch()
