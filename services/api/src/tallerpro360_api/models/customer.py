import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


class Customer(SQLModel, table=True):
    __tablename__ = "customer"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    nombre: str
    telefono: Optional[str] = None
    email: Optional[str] = None
    direccion: Optional[str] = None
    whatsapp: Optional[str] = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
