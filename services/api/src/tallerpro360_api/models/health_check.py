from datetime import datetime, timezone

from sqlmodel import Field, SQLModel


class HealthLog(SQLModel, table=True):
    __tablename__ = "health_log"

    id: int | None = Field(default=None, primary_key=True)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
    )
