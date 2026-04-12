import uuid
from typing import Optional

from sqlmodel import Field, SQLModel


class DiagnosticFinding(SQLModel, table=True):
    __tablename__ = "diagnostic_finding"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    order_id: uuid.UUID = Field(foreign_key="service_order.id")
    technician_id: uuid.UUID = Field(foreign_key="user.id")
    motivo_ingreso: str
    descripcion: Optional[str] = None
    tiempo_estimado: Optional[float] = None
    fotos: Optional[str] = None
    es_hallazgo_adicional: bool = False
    es_critico_seguridad: bool = False
