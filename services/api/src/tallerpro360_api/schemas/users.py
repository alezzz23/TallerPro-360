from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from ..models.user import UserRole


class UserResponse(BaseModel):
    id: uuid.UUID
    nombre: str
    email: str
    rol: UserRole
    activo: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    nombre: Optional[str] = None
    activo: Optional[bool] = None
    rol: Optional[UserRole] = None


class UserListResponse(BaseModel):
    items: list[UserResponse]
    total: int
    limit: int
    offset: int
