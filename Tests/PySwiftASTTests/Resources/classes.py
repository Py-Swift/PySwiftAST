# Class definitions
class Person:
    pass

class Animal:
    def __init__(self, name):
        self.name = name
    
    def speak(self):
        return "Sound"

class Dog(Animal):
    def speak(self):
        return "Woof!"
