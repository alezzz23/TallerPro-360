from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "TallerPro360 API"
    environment: str = "development"
    api_prefix: str = "/api/v1"
    database_url: str = "postgresql://tallerpro360:tallerpro360@localhost:5432/tallerpro360"
    secret_key: str = "change-me-in-production"
    access_token_expire_minutes: int = 1440

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
