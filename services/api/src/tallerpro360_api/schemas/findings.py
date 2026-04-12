from __future__ import annotations

import uuid

from pydantic import BaseModel

from ..models.part import PartOrigen

_SAFETY_WARNING = (
    "Este hallazgo afecta la seguridad del vehículo. El cliente debe ser notificado."
)


class FindingCreate(BaseModel):
    technician_id: uuid.UUID
    motivo_ingreso: str
    descripcion: str | None = None
    tiempo_estimado: float | None = None
    es_hallazgo_adicional: bool = False
    es_critico_seguridad: bool = False


class FindingUpdate(BaseModel):
    descripcion: str | None = None
    tiempo_estimado: float | None = None
    es_critico_seguridad: bool | None = None


class FindingPhotoAdd(BaseModel):
    foto_url: str


class PartCreate(BaseModel):
    nombre: str
    origen: PartOrigen
    costo: float
    margen: float
    proveedor: str | None = None


class PartResponse(BaseModel):
    id: uuid.UUID
    finding_id: uuid.UUID
    nombre: str
    origen: PartOrigen
    costo: float
    margen: float
    precio_venta: float
    proveedor: str | None

    model_config = {"from_attributes": True}


class FindingResponse(BaseModel):
    id: uuid.UUID
    order_id: uuid.UUID
    technician_id: uuid.UUID
    motivo_ingreso: str
    descripcion: str | None
    tiempo_estimado: float | None
    fotos: list[str]
    es_hallazgo_adicional: bool
    es_critico_seguridad: bool
    parts: list[PartResponse] = []
    safety_warning: str | None = None

    model_config = {"from_attributes": True}
