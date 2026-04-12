import uuid
from datetime import datetime
from enum import Enum
from typing import Optional

from sqlmodel import Field, SQLModel


class QuotationEstado(str, Enum):
    PENDIENTE = "PENDIENTE"
    APROBADA = "APROBADA"
    RECHAZADA = "RECHAZADA"


class Quotation(SQLModel, table=True):
    __tablename__ = "quotation"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    order_id: uuid.UUID = Field(foreign_key="service_order.id")
    subtotal: float
    impuestos: float
    shop_supplies: float = 0.0
    descuento: float = 0.0
    total: float
    estado: QuotationEstado = QuotationEstado.PENDIENTE
    fecha_envio: Optional[datetime] = None
