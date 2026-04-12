import uuid
from datetime import datetime, timezone
from enum import Enum
from typing import Optional

from sqlmodel import Field, SQLModel


class OrderStatus(str, Enum):
    RECEPCION = "RECEPCION"
    DIAGNOSTICO = "DIAGNOSTICO"
    APROBACION = "APROBACION"
    REPARACION = "REPARACION"
    QC = "QC"
    ENTREGA = "ENTREGA"
    CERRADA = "CERRADA"


class ServiceOrder(SQLModel, table=True):
    __tablename__ = "service_order"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    vehicle_id: uuid.UUID = Field(foreign_key="vehicle.id")
    advisor_id: uuid.UUID = Field(foreign_key="user.id")
    estado: OrderStatus
    fecha_ingreso: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    fecha_salida: Optional[datetime] = None
    kilometraje_ingreso: Optional[int] = None
    kilometraje_salida: Optional[int] = None
    motivo_ingreso: Optional[str] = None
