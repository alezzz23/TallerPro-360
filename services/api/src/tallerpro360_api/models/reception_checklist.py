import uuid
from typing import Optional

from sqlmodel import Field, SQLModel


class ReceptionChecklist(SQLModel, table=True):
    __tablename__ = "reception_checklist"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    order_id: uuid.UUID = Field(foreign_key="service_order.id", unique=True)
    nivel_aceite: Optional[str] = None
    nivel_refrigerante: Optional[str] = None
    nivel_frenos: Optional[str] = None
    llanta_repuesto: bool = False
    kit_carretera: bool = False
    botiquin: bool = False
    extintor: bool = False
    documentos_recibidos: Optional[str] = None
    firma_cliente_url: Optional[str] = None
