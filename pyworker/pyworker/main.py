from config import Config
from api import ApiClient
from asyncio import run


async def main():
    config = Config.load()
    client = ApiClient(config)
    print(await client.select_problem("probatio"))
    print(f"Config: {config}")
    print("Hello from pyworker!")


if __name__ == "__main__":
    run(main())
