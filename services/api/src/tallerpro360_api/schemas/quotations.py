from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel

from ..models.quotation import QuotationEstado


class QuotationItemCreate(BaseModel):
    finding_id: uuid.UUID
    part_id: uuid.UUID | None = None
    descripcion: str
    mano_obra: float = 0.0
    costo_repuesto: float = 0.0


class QuotationCreate(BaseModel):
    items: list[QuotationItemCreate]
    impuestos_pct: float = 0.16
    shop_supplies_pct: float = 0.015
    descuento: float = 0.0


class QuotationDiscountUpdate(BaseModel):
    descuento: float
    razon: str | None = None


class QuotationRejectBody(BaseModel):
    razon: str | None = None


class QuotationItemResponse(BaseModel):
    id: uuid.UUID
    quotation_id: uuid.UUID
    finding_id: uuid.UUID
    part_id: uuid.UUID | None
    descripcion: str
    mano_obra: float
    costo_repuesto: float
    precio_final: float

    model_config = {"from_attributes": True}


class QuotationResponse(BaseModel):
    id: uuid.UUID
    order_id: uuid.UUID
    subtotal: float
    impuestos: float
    shop_supplies: float
    descuento: float
    total: float
    estado: QuotationEstado
    fecha_envio: datetime | None
    items: list[QuotationItemResponse] = []

    model_config = {"from_attributes": True}


class QuotationRejectResponse(QuotationResponse):
    safety_log: str | None = None
