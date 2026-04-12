import uuid
from enum import Enum

from sqlmodel import Field, SQLModel


class AnguloFoto(str, Enum):
    FRONTAL = "FRONTAL"
    TRASERO = "TRASERO"
    IZQUIERDO = "IZQUIERDO"
    DERECHO = "DERECHO"


class PerimeterPhoto(SQLModel, table=True):
    __tablename__ = "perimeter_photo"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    order_id: uuid.UUID = Field(foreign_key="service_order.id")
    angulo: AnguloFoto
    foto_url: str
