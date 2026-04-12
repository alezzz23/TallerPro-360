from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class CustomerCreate(BaseModel):
    nombre: str
    telefono: Optional[str] = None
    email: Optional[str] = None
    direccion: Optional[str] = None
    whatsapp: Optional[str] = None


class CustomerUpdate(BaseModel):
    nombre: Optional[str] = None
    telefono: Optional[str] = None
    email: Optional[str] = None
    direccion: Optional[str] = None
    whatsapp: Optional[str] = None


class CustomerResponse(BaseModel):
    id: uuid.UUID
    nombre: str
    telefono: Optional[str]
    email: Optional[str]
    direccion: Optional[str]
    whatsapp: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class CustomerListResponse(BaseModel):
    items: list[CustomerResponse]
    total: int
    limit: int
    offset: int
