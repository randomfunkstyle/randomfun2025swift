from dataclasses import dataclass
from dataclasses_json import dataclass_json
from typing import List


@dataclass_json
@dataclass
class RegisterRequest:
    name: str
    pl: str
    email: str


@dataclass_json
@dataclass
class RegisterResponse:
    id: str


@dataclass_json
@dataclass
class SelectRequest:
    id: str
    problemName: str


@dataclass_json
@dataclass
class SelectResponse:
    problemName: str


@dataclass_json
@dataclass
class ExploreRequest:
    id: str
    plans: List[str]


@dataclass_json
@dataclass
class ExploreResponse:
    results: List[List[int]]
    queryCount: int


@dataclass_json
@dataclass
class RoomDoor:
    room: int
    door: int


@dataclass_json
@dataclass
class Connection:
    from_: RoomDoor
    to: RoomDoor

    def __str__(self) -> str:
        return f"Connection({self.from_.room}.{self.from_.door}, -> {self.to.room}.{self.to.door})"


@dataclass_json
@dataclass
class MapDescription:
    rooms: List[int]
    startingRoom: int
    connections: List[Connection]


@dataclass_json
@dataclass
class GuessRequest:
    id: str
    map: MapDescription


@dataclass_json
@dataclass
class GuessResponse:
    correct: bool


class HTTPError(Exception):
    def __init__(self, status_code: int, message: str):
        self.status_code = status_code
        self.message = message
        super().__init__(f"HTTP Error {status_code}: {message}")