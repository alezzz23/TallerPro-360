from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class VehicleCreate(BaseModel):
    customer_id: uuid.UUID
    marca: str
    modelo: str
    placa: str
    vin: Optional[str] = None
    kilometraje: Optional[int] = None
    color: Optional[str] = None


class VehicleUpdate(BaseModel):
    customer_id: Optional[uuid.UUID] = None
    marca: Optional[str] = None
    modelo: Optional[str] = None
    placa: Optional[str] = None
    vin: Optional[str] = None
    kilometraje: Optional[int] = None
    color: Optional[str] = None


class VehicleResponse(BaseModel):
    id: uuid.UUID
    customer_id: uuid.UUID
    marca: str
    modelo: str
    placa: str
    vin: Optional[str]
    kilometraje: Optional[int]
    color: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class VehicleListResponse(BaseModel):
    items: list[VehicleResponse]
    total: int
    limit: int
    offset: int
