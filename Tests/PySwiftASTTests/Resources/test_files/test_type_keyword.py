# Python 3.12 type statement
type Point = tuple[float, float]
type Vector = list[float]

def distance(p1: Point, p2: Point) -> float:
    return ((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2) ** 0.5
