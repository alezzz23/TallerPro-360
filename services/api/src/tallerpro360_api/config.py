from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


_BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    app_name: str = "TallerPro360 API"
    app_version: str = "0.1.0"
    environment: str = "development"
    api_prefix: str = "/api/v1"
    database_url: str = "postgresql://tallerpro360:tallerpro360@localhost:5432/tallerpro360"
    secret_key: str = "change-me-in-production"
    access_token_expire_minutes: int = 1440
    media_dir: Path = _BASE_DIR / "media"
    media_url_path: str = "/media"
    max_upload_size_bytes: int = 10 * 1024 * 1024
    log_level: str = "INFO"
    log_json: bool = True
    auto_create_tables: bool | None = None
    enable_pg_listener: bool = True

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
