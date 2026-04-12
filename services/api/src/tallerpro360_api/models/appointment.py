import uuid
from datetime import datetime, timezone
from enum import Enum
from typing import Optional

from sqlmodel import Field, SQLModel


class AppointmentEstado(str, Enum):
    PENDIENTE = "PENDIENTE"
    CONFIRMADA = "CONFIRMADA"
    CANCELADA = "CANCELADA"
    COMPLETADA = "COMPLETADA"


class Appointment(SQLModel, table=True):
    __tablename__ = "appointment"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    customer_id: uuid.UUID = Field(foreign_key="customer.id")
    vehicle_id: Optional[uuid.UUID] = Field(default=None, foreign_key="vehicle.id")
    fecha: datetime
    bloque_horario: str
    motivo: Optional[str] = None
    estado: AppointmentEstado = AppointmentEstado.PENDIENTE
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
