import uuid
from enum import Enum
from typing import Optional

from sqlmodel import Field, SQLModel


class PartOrigen(str, Enum):
    STOCK = "STOCK"
    PEDIDO = "PEDIDO"


class Part(SQLModel, table=True):
    __tablename__ = "part"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    finding_id: uuid.UUID = Field(foreign_key="diagnostic_finding.id")
    nombre: str
    origen: PartOrigen
    costo: float
    margen: float
    precio_venta: float
    proveedor: Optional[str] = None
