import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


class QualityCheck(SQLModel, table=True):
    __tablename__ = "quality_check"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    order_id: uuid.UUID = Field(foreign_key="service_order.id", unique=True)
    inspector_id: uuid.UUID = Field(foreign_key="user.id")
    items_verificados: Optional[str] = None
    kilometraje_salida: Optional[int] = None
    nivel_aceite_salida: Optional[str] = None
    nivel_refrigerante_salida: Optional[str] = None
    nivel_frenos_salida: Optional[str] = None
    aprobado: bool = False
    fecha: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
