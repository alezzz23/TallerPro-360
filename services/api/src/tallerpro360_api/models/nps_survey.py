import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


class NPSSurvey(SQLModel, table=True):
    __tablename__ = "nps_survey"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    order_id: uuid.UUID = Field(foreign_key="service_order.id", unique=True)
    atencion: int
    instalaciones: int
    tiempos: int
    precios: int
    recomendacion: int
    comentarios: Optional[str] = None
    fecha: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
