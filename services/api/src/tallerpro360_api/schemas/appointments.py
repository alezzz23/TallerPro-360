from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel

from ..models.appointment import AppointmentEstado


class AppointmentCreate(BaseModel):
    customer_id: uuid.UUID
    vehicle_id: uuid.UUID | None = None
    fecha: datetime
    bloque_horario: str
    motivo: str | None = None


class AppointmentUpdate(BaseModel):
    fecha: datetime | None = None
    bloque_horario: str | None = None
    motivo: str | None = None
    estado: AppointmentEstado | None = None


class AppointmentResponse(BaseModel):
    id: uuid.UUID
    customer_id: uuid.UUID
    vehicle_id: uuid.UUID | None
    fecha: datetime
    bloque_horario: str
    motivo: str | None
    estado: AppointmentEstado
    created_at: datetime

    model_config = {"from_attributes": True}


class AppointmentListResponse(BaseModel):
    items: list[AppointmentResponse]
    total: int
    limit: int
    offset: int
