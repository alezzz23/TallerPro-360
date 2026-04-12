import uuid
from typing import Optional

from sqlmodel import Field, SQLModel


class QuotationItem(SQLModel, table=True):
    __tablename__ = "quotation_item"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    quotation_id: uuid.UUID = Field(foreign_key="quotation.id")
    finding_id: uuid.UUID = Field(foreign_key="diagnostic_finding.id")
    part_id: Optional[uuid.UUID] = Field(default=None, foreign_key="part.id")
    descripcion: str
    mano_obra: float = 0.0
    costo_repuesto: float = 0.0
    precio_final: float
