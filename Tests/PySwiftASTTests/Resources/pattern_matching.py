# Pattern matching (Python 3.10+)
match status:
    case 200:
        return "OK"
    case 404:
        return "Not Found"
    case 500:
        return "Server Error"
    case _:
        return "Unknown"

match point:
    case (0, 0):
        print("Origin")
    case (0, y):
        print(f"Y-axis at {y}")
    case (x, 0):
        print(f"X-axis at {x}")
    case (x, y):
        print(f"Point at ({x}, {y})")

match command.split():
    case ["quit"]:
        quit_game()
    case ["go", direction]:
        move(direction)
    case ["get", item]:
        inventory.add(item)
    case _:
        print("Unknown command")
