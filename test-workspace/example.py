# Yozakura - Python example
# These files are all gibberish, do not attempt to run them

#  Imports
from __future__ import annotations

import asyncio
import contextlib
import functools
import itertools
import re
import sys
from abc import ABC, abstractmethod
from collections import defaultdict, deque
from dataclasses import dataclass, field
from enum import Enum, auto, Flag
from pathlib import Path
from typing import (
    TYPE_CHECKING,
    Any,
    Callable,
    ClassVar,
    Generator,
    Generic,
    Iterator,
    Optional,
    Protocol,
    TypeVar,
    Union,
    overload,
)

if TYPE_CHECKING:
    from collections.abc import Sequence

#  Constants
VERSION: str = "1.0.0"
MAX_RETRIES: int = 3
PI: float = 3.14159265358979
PATTERN: re.Pattern[str] = re.compile(r"^[a-z][a-z0-9_]*$", re.IGNORECASE)

T = TypeVar("T")
K = TypeVar("K")
V = TypeVar("V")


#  Enums
class Color(Enum):
    RED = auto()
    GREEN = auto()
    BLUE = auto()

    def hex(self) -> str:
        mapping = {Color.RED: "#FF0000", Color.GREEN: "#00FF00", Color.BLUE: "#0000FF"}
        return mapping[self]


class Permission(Flag):
    READ = auto()
    WRITE = auto()
    EXECUTE = auto()
    ALL = READ | WRITE | EXECUTE


#  Dataclasses
@dataclass(frozen=True)
class Point:
    x: float
    y: float

    def distance_to(self, other: Point) -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5

    def __add__(self, other: Point) -> Point:
        return Point(self.x + other.x, self.y + other.y)


@dataclass
class Config:
    host: str = "localhost"
    port: int = 8080
    debug: bool = False
    tags: list[str] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)
    _cache: dict[str, Any] = field(default_factory=dict, init=False, repr=False)


#  Abstract Base Classes & Protocols
class Repository(ABC, Generic[T]):
    @abstractmethod
    def find_by_id(self, id: str) -> Optional[T]:
        ...

    @abstractmethod
    def save(self, entity: T) -> T:
        ...

    @abstractmethod
    def delete(self, id: str) -> None:
        ...

    def find_or_raise(self, id: str) -> T:
        entity = self.find_by_id(id)
        if entity is None:
            raise KeyError(f"Entity not found: {id!r}")
        return entity


class Drawable(Protocol):
    def draw(self, canvas: Any) -> None:
        ...

    def bounds(self) -> tuple[float, float, float, float]:
        ...


#  Decorators
def retry(retries: int = 3, delay: float = 1.0, exceptions: tuple[type[Exception], ...] = (Exception,)):
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> T:
            last_exc: Exception
            for attempt in range(retries + 1):
                try:
                    return func(*args, **kwargs)
                except exceptions as exc:
                    last_exc = exc
                    if attempt < retries:
                        import time
                        time.sleep(delay * 2**attempt)
            raise last_exc  # type: ignore[misc]
        return wrapper
    return decorator


def cached_property(func: Callable[[Any], T]) -> property:
    cache_attr = f"_cache_{func.__name__}"

    @functools.wraps(func)
    def getter(self: Any) -> T:
        if not hasattr(self, cache_attr):
            setattr(self, cache_attr, func(self))
        return getattr(self, cache_attr)

    return property(getter)


#  Classes
class Animal:
    _count: ClassVar[int] = 0

    def __init__(self, name: str, species: str) -> None:
        self._name = name
        self.species = species
        Animal._count += 1

    def __repr__(self) -> str:
        return f"{type(self).__name__}(name={self._name!r}, species={self.species!r})"

    def __str__(self) -> str:
        return f"{self._name} the {self.species}"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Animal):
            return NotImplemented
        return self._name == other._name and self.species == other.species

    def __hash__(self) -> int:
        return hash((self._name, self.species))

    @property
    def name(self) -> str:
        return self._name

    @name.setter
    def name(self, value: str) -> None:
        if not value.strip():
            raise ValueError("Name cannot be empty")
        self._name = value.strip()

    @classmethod
    def total(cls) -> int:
        return cls._count

    @staticmethod
    def validate_species(species: str) -> bool:
        return bool(PATTERN.match(species))


class Dog(Animal):
    def __init__(self, name: str) -> None:
        super().__init__(name, "Canis lupus familiaris")
        self._tricks: list[str] = []

    def learn(self, trick: str) -> "Dog":
        self._tricks.append(trick)
        return self

    def perform(self) -> list[str]:
        return [f"{self.name} performs: {trick}" for trick in self._tricks]

    def __iter__(self) -> Iterator[str]:
        return iter(self._tricks)


#  Generators
def fibonacci() -> Generator[int, None, None]:
    a, b = 0, 1
    while True:
        yield a
        a, b = b, a + b


def chunked(iterable: Iterator[T], size: int) -> Generator[list[T], None, None]:
    chunk: list[T] = []
    for item in iterable:
        chunk.append(item)
        if len(chunk) == size:
            yield chunk
            chunk = []
    if chunk:
        yield chunk


#  Comprehensions
squares = [x**2 for x in range(10)]
even_squares = [x**2 for x in range(10) if x % 2 == 0]
matrix = [[i * j for j in range(1, 4)] for i in range(1, 4)]

square_map = {x: x**2 for x in range(10)}
word_lengths = {word: len(word) for word in ["hello", "world", "python"]}

unique_mods = {x % 7 for x in range(50)}

sum_gen = sum(x**2 for x in range(100))
any_large = any(x > 90 for x in range(100))

#  Context Managers
@contextlib.contextmanager
def managed_resource(name: str) -> Generator[dict[str, Any], None, None]:
    resource: dict[str, Any] = {"name": name, "active": True}
    try:
        print(f"Acquiring {name}")
        yield resource
    except Exception as exc:
        print(f"Error in {name}: {exc}")
        raise
    finally:
        resource["active"] = False
        print(f"Released {name}")


#  Type Hints & Overloads
@overload
def process(value: str) -> str: ...
@overload
def process(value: int) -> int: ...
@overload
def process(value: list[Any]) -> list[Any]: ...

def process(value: Union[str, int, list[Any]]) -> Union[str, int, list[Any]]:
    if isinstance(value, str):
        return value.upper()
    elif isinstance(value, int):
        return value * 2
    return [process(v) for v in value]  # type: ignore[arg-type]


#  Async
async def fetch_data(url: str) -> dict[str, Any]:
    await asyncio.sleep(0.1)  # simulate I/O
    return {"url": url, "status": 200, "data": []}


async def gather_results(*urls: str) -> list[dict[str, Any]]:
    tasks = [asyncio.create_task(fetch_data(url)) for url in urls]
    return await asyncio.gather(*tasks, return_exceptions=True)  # type: ignore[return-value]


async def stream_items(items: list[T]) -> AsyncGenerator[T, None]:
    for item in items:
        await asyncio.sleep(0)
        yield item


#  Exception Hierarchy
class AppError(Exception):
    def __init__(self, message: str, code: str, *, cause: Optional[Exception] = None) -> None:
        super().__init__(message)
        self.code = code
        self.__cause__ = cause

    def __str__(self) -> str:
        return f"[{self.code}] {super().__str__()}"


class ValidationError(AppError):
    def __init__(self, field: str, message: str) -> None:
        super().__init__(message, "VALIDATION_ERROR")
        self.field = field


class NotFoundError(AppError):
    def __init__(self, resource: str, id: Any) -> None:
        super().__init__(f"{resource} with id {id!r} not found", "NOT_FOUND")
        self.resource = resource
        self.id = id


#  Match / Case (Python 3.10+)
def handle_command(command: dict[str, Any]) -> str:
    match command:
        case {"action": "create", "type": str(t), "data": dict(d)}:
            return f"Creating {t} with {d}"
        case {"action": "delete", "id": int(i)}:
            return f"Deleting item {i}"
        case {"action": "update", "id": int(i), **rest}:
            return f"Updating {i} with {rest}"
        case {"action": action}:
            return f"Unknown action: {action}"
        case _:
            return "Invalid command"


#  Walrus Operator
data = [1, 4, 9, 16, 25, 36]
if (n := len(data)) > 5:
    print(f"List is long: {n} items")

while chunk := data[:3]:
    data = data[3:]
