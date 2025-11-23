# Control flow statements
if True:
    x = 1
else:
    x = 2

if x > 0:
    print("positive")
elif x < 0:
    print("negative")
else:
    print("zero")

while x < 10:
    x += 1
    if x == 5:
        break

for i in range(10):
    if i % 2 == 0:
        continue
    print(i)
