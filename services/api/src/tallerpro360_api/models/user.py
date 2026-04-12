import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlmodel import Field, SQLModel


class UserRole(str, Enum):
    TECNICO = "TECNICO"
    ASESOR = "ASESOR"
    JEFE_TALLER = "JEFE_TALLER"
    ADMIN = "ADMIN"


class User(SQLModel, table=True):
    __tablename__ = "user"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    nombre: str
    email: str = Field(unique=True, index=True)
    password_hash: str
    rol: UserRole
    activo: bool = True
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
