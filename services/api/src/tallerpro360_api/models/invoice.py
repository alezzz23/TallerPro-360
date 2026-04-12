import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlmodel import Field, SQLModel


class MetodoPago(str, Enum):
    EFECTIVO = "EFECTIVO"
    TARJETA = "TARJETA"
    TRANSFERENCIA = "TRANSFERENCIA"
    CREDITO = "CREDITO"


class Invoice(SQLModel, table=True):
    __tablename__ = "invoice"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    order_id: uuid.UUID = Field(foreign_key="service_order.id", unique=True)
    monto_total: float
    metodo_pago: MetodoPago
    es_credito: bool = False
    saldo_pendiente: float = 0.0
    fecha: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
