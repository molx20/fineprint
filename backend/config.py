"""
Configuration management for FinePrint backend.
Loads environment variables and provides application settings.
"""

from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # OpenAI Configuration
    openai_api_key: str
    openai_model: str = "gpt-4o"

    # Server Configuration
    port: int = 8001
    host: str = "0.0.0.0"
    debug: bool = True
    disable_scan_limits: bool = True  # Set to False in production

    # Database
    database_url: str = "sqlite:///./fineprint.db"

    # Scraping Configuration
    enable_dynamic_scraping: bool = True
    dynamic_scraping_timeout: int = 10  # seconds
    static_content_threshold: int = 200  # minimum chars to consider valid static scrape

    # CORS
    cors_origins: str = "http://localhost:*,http://127.0.0.1:*"

    class Config:
        env_file = ".env"
        case_sensitive = False

    @property
    def cors_origins_list(self) -> List[str]:
        """Parse CORS origins from comma-separated string."""
        return [origin.strip() for origin in self.cors_origins.split(",")]


# Global settings instance
settings = Settings()
