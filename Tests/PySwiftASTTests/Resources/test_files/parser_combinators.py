"""
Parser combinator library demonstrating advanced Python features.
"""
from typing import Callable, TypeVar, Generic, Union, Tuple, List, Optional
from dataclasses import dataclass
from abc import ABC, abstractmethod

T = TypeVar('T')
U = TypeVar('U')

@dataclass
class ParseResult(Generic[T]):
    success: bool
    value: Optional[T] = None
    remaining: str = ""
    error: Optional[str] = None

class Parser(Generic[T], ABC):
    @abstractmethod
    def parse(self, input_str: str) -> ParseResult[T]:
        pass
    
    def __or__(self, other: 'Parser[T]') -> 'Parser[T]':
        return OrParser(self, other)
    
    def __and__(self, other: 'Parser[U]') -> 'Parser[Tuple[T, U]]':
        return SequenceParser(self, other)
    
    def map(self, fn: Callable[[T], U]) -> 'Parser[U]':
        return MapParser(self, fn)
    
    def many(self) -> 'Parser[List[T]]':
        return ManyParser(self)
    
    def optional(self) -> 'Parser[Optional[T]]':
        return OptionalParser(self)

class CharParser(Parser[str]):
    def __init__(self, char: str):
        self.char = char
    
    def parse(self, input_str: str) -> ParseResult[str]:
        if not input_str:
            return ParseResult(False, error=f"Expected '{self.char}', got EOF")
        
        if input_str[0] == self.char:
            return ParseResult(True, self.char, input_str[1:])
        else:
            return ParseResult(False, error=f"Expected '{self.char}', got '{input_str[0]}'")

class StringParser(Parser[str]):
    def __init__(self, string: str):
        self.string = string
    
    def parse(self, input_str: str) -> ParseResult[str]:
        if input_str.startswith(self.string):
            return ParseResult(True, self.string, input_str[len(self.string):])
        else:
            return ParseResult(False, error=f"Expected '{self.string}'")

class RegexParser(Parser[str]):
    def __init__(self, pattern: str):
        import re
        self.pattern = re.compile(pattern)
    
    def parse(self, input_str: str) -> ParseResult[str]:
        match = self.pattern.match(input_str)
        if match:
            matched_str = match.group()
            return ParseResult(True, matched_str, input_str[len(matched_str):])
        else:
            return ParseResult(False, error=f"Pattern '{self.pattern.pattern}' did not match")

class OrParser(Parser[T]):
    def __init__(self, left: Parser[T], right: Parser[T]):
        self.left = left
        self.right = right
    
    def parse(self, input_str: str) -> ParseResult[T]:
        result = self.left.parse(input_str)
        if result.success:
            return result
        return self.right.parse(input_str)

class SequenceParser(Parser[Tuple[T, U]]):
    def __init__(self, first: Parser[T], second: Parser[U]):
        self.first = first
        self.second = second
    
    def parse(self, input_str: str) -> ParseResult[Tuple[T, U]]:
        first_result = self.first.parse(input_str)
        if not first_result.success:
            return ParseResult(False, error=first_result.error)
        
        second_result = self.second.parse(first_result.remaining)
        if not second_result.success:
            return ParseResult(False, error=second_result.error)
        
        return ParseResult(True, (first_result.value, second_result.value), second_result.remaining)

class MapParser(Parser[U]):
    def __init__(self, parser: Parser[T], fn: Callable[[T], U]):
        self.parser = parser
        self.fn = fn
    
    def parse(self, input_str: str) -> ParseResult[U]:
        result = self.parser.parse(input_str)
        if result.success:
            return ParseResult(True, self.fn(result.value), result.remaining)
        return ParseResult(False, error=result.error)

class ManyParser(Parser[List[T]]):
    def __init__(self, parser: Parser[T]):
        self.parser = parser
    
    def parse(self, input_str: str) -> ParseResult[List[T]]:
        values = []
        remaining = input_str
        
        while True:
            result = self.parser.parse(remaining)
            if not result.success:
                break
            values.append(result.value)
            remaining = result.remaining
        
        return ParseResult(True, values, remaining)

class OptionalParser(Parser[Optional[T]]):
    def __init__(self, parser: Parser[T]):
        self.parser = parser
    
    def parse(self, input_str: str) -> ParseResult[Optional[T]]:
        result = self.parser.parse(input_str)
        if result.success:
            return result
        return ParseResult(True, None, input_str)

def char(c: str) -> Parser[str]:
    return CharParser(c)

def string(s: str) -> Parser[str]:
    return StringParser(s)

def regex(pattern: str) -> Parser[str]:
    return RegexParser(pattern)

def between(open_p: Parser, close_p: Parser, content: Parser[T]) -> Parser[T]:
    return (open_p & content & close_p).map(lambda x: x[1])

digit = regex(r'\d')
digits = digit.many().map(lambda ds: ''.join(ds))
integer = digits.map(int)

lparen = char('(')
rparen = char(')')
comma = char(',')

def list_parser() -> Parser[List[int]]:
    return between(
        lparen,
        rparen,
        (integer & (comma & integer).many()).map(lambda x: [x[0]] + [i for _, i in x[1]])
    )

if __name__ == '__main__':
    parser = list_parser()
    result = parser.parse("(1,2,3,4,5)")
    if result.success:
        print(f"Parsed: {result.value}")
    else:
        print(f"Error: {result.error}")
