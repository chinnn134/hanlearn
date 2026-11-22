from pathlib import Path
from typing import Literal
from urllib.parse import urlsplit

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

REPO_ROOT = Path(__file__).resolve().parents[3]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=REPO_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: Literal["local", "staging", "production"] = "local"
    firebase_project_id: str | None = None
    firebase_token_clock_skew_seconds: int = Field(default=0, ge=0, le=600)
    dictionary_db_path: Path = (
        REPO_ROOT / "backend/data/dictionary/hanlearn_dictionary.sqlite3"
    )
    allowed_origins: str = Field(default="http://localhost:3000")
    ocr_service_url: str | None = None
    ocr_service_api_key: str | None = None
    ocr_timeout_seconds: int = Field(default=30, ge=1, le=120)
    max_image_bytes: int = Field(default=8 * 1024 * 1024, ge=1, le=32 * 1024 * 1024)
    max_image_pixels: int = Field(default=20_000_000, ge=1, le=100_000_000)

    @field_validator("allowed_origins")
    @classmethod
    def validate_origins(cls, value: str) -> str:
        origins = [origin.strip() for origin in value.split(",")]
        if not origins or any(not origin for origin in origins):
            raise ValueError("ALLOWED_ORIGINS must contain explicit origins")
        for origin in origins:
            parsed = urlsplit(origin)
            if (
                parsed.scheme not in {"http", "https"}
                or not parsed.hostname
                or parsed.path
                or parsed.query
                or parsed.fragment
                or parsed.username
                or parsed.password
                or "*" in origin
            ):
                raise ValueError(f"Invalid CORS origin: {origin}")
        return ",".join(origins)

    @property
    def cors_origins(self) -> list[str]:
        return self.allowed_origins.split(",")

    @model_validator(mode="after")
    def validate_deployment(self) -> "Settings":
        self.dictionary_db_path = self.dictionary_db_path.resolve()
        if self.app_env != "local":
            if not self.firebase_project_id:
                raise ValueError("FIREBASE_PROJECT_ID is required outside local")
            if "allowed_origins" not in self.model_fields_set:
                raise ValueError("ALLOWED_ORIGINS is required outside local")
            if any(not origin.startswith("https://") for origin in self.cors_origins):
                raise ValueError("Staging and production origins must use HTTPS")
        return self
