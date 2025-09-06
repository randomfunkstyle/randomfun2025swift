import httpx
from typing import TypeVar, Type

from config import Config
from models import (
    RegisterRequest, RegisterResponse,
    SelectRequest, SelectResponse,
    ExploreRequest, ExploreResponse,
    GuessRequest, GuessResponse,
    MapDescription, HTTPError
)

T = TypeVar('T')


class HTTPTaskClient:
    def __init__(self, config: Config):
        self.base_url = config.api_url
        self.team_id = config.team_id
        self.client = httpx.AsyncClient()

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.client.aclose()

    async def register(self, name: str, pl: str, email: str) -> RegisterResponse:
        request = RegisterRequest(name=name, pl=pl, email=email)
        return await self._post("/register", request, RegisterResponse)

    async def select_problem(self, problem_name: str) -> SelectResponse:
        request = SelectRequest(id=self.team_id, problemName=problem_name)
        return await self._post("/select", request, SelectResponse)

    async def explore(self, plans: list[str]) -> ExploreResponse:
        request = ExploreRequest(id=self.team_id, plans=plans)
        return await self._post("/explore", request, ExploreResponse)

    async def guess(self, map_description: MapDescription) -> GuessResponse:
        request = GuessRequest(id=self.team_id, map=map_description)
        return await self._post("/guess", request, GuessResponse)

    async def _post(self, endpoint: str, body: object, response_type: Type[T]) -> T:
        url = f"{self.base_url}{endpoint}"
        
        response = await self.client.post(
            url,
            json=body.to_dict(),
            headers={"Content-Type": "application/json"}
        )

        if response.status_code != 200:
            raise HTTPError(
                status_code=response.status_code,
                message=response.text
            )

        response_data = response.json()
        return response_type.from_dict(response_data)