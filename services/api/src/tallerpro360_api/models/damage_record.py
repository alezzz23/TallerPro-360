import uuid
from typing import Optional

from sqlmodel import Field, SQLModel


class DamageRecord(SQLModel, table=True):
    __tablename__ = "damage_record"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    order_id: uuid.UUID = Field(foreign_key="service_order.id")
    ubicacion: str
    descripcion: Optional[str] = None
    foto_url: Optional[str] = None
    reconocido_por_cliente: bool = False
