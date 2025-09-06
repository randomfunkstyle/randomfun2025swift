import os
from dataclasses import dataclass
from dotenv import load_dotenv


@dataclass
class Config:
    team_id: str
    api_url: str
    
    @classmethod
    def load(cls) -> "Config":
        """Load configuration from .env file."""
        load_dotenv()
        
        team_id = os.getenv("TEAM_ID", "")
        api_url = os.getenv("API_URL", "")
        
        return cls(team_id=team_id, api_url=api_url)