from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from ..models.invoice import MetodoPago
from ..models.perimeter_photo import AnguloFoto
from ..models.service_order import OrderStatus


# --- Service Order ---

class ServiceOrderCreate(BaseModel):
    vehicle_id: uuid.UUID
    advisor_id: uuid.UUID
    kilometraje_ingreso: int | None = None
    motivo_ingreso: str | None = None
    appointment_id: uuid.UUID | None = None


class ServiceOrderResponse(BaseModel):
    id: uuid.UUID
    vehicle_id: uuid.UUID
    advisor_id: uuid.UUID
    estado: OrderStatus
    fecha_ingreso: datetime
    fecha_salida: datetime | None
    kilometraje_ingreso: int | None
    kilometraje_salida: int | None
    motivo_ingreso: str | None
    reception_complete: bool

    model_config = {"from_attributes": True}


class ServiceOrderListResponse(BaseModel):
    items: list[ServiceOrderResponse]
    total: int
    limit: int
    offset: int


# --- Reception Checklist ---

class ReceptionChecklistCreate(BaseModel):
    nivel_aceite: str | None = None
    nivel_refrigerante: str | None = None
    nivel_frenos: str | None = None
    llanta_repuesto: bool = False
    kit_carretera: bool = False
    botiquin: bool = False
    extintor: bool = False
    documentos_recibidos: str | None = None
    firma_cliente_url: str | None = None


class ReceptionChecklistResponse(BaseModel):
    id: uuid.UUID
    order_id: uuid.UUID
    nivel_aceite: str | None
    nivel_refrigerante: str | None
    nivel_frenos: str | None
    llanta_repuesto: bool
    kit_carretera: bool
    botiquin: bool
    extintor: bool
    documentos_recibidos: str | None
    firma_cliente_url: str | None

    model_config = {"from_attributes": True}


# --- Damage Record ---

class DamageRecordCreate(BaseModel):
    ubicacion: str
    descripcion: str | None = None
    foto_url: str | None = None
    reconocido_por_cliente: bool = False


class DamageRecordResponse(BaseModel):
    id: uuid.UUID
    order_id: uuid.UUID
    ubicacion: str
    descripcion: str | None
    foto_url: str | None
    reconocido_por_cliente: bool

    model_config = {"from_attributes": True}


# --- Perimeter Photo ---

class PerimeterPhotoCreate(BaseModel):
    angulo: AnguloFoto
    foto_url: str


class PerimeterPhotoResponse(BaseModel):
    id: uuid.UUID
    order_id: uuid.UUID
    angulo: AnguloFoto
    foto_url: str

    model_config = {"from_attributes": True}


# --- Client Signature ---

class ClientSignatureUpdate(BaseModel):
    firma_cliente_url: str


# --- Quality Check (Fase 2.6) ---

class QCCreate(BaseModel):
    inspector_id: uuid.UUID
    items_verificados: dict
    kilometraje_salida: int | None = None
    nivel_aceite_salida: str | None = None
    nivel_refrigerante_salida: str | None = None
    nivel_frenos_salida: str | None = None
    aprobado: bool = False


class QCResponse(BaseModel):
    id: uuid.UUID
    order_id: uuid.UUID
    inspector_id: uuid.UUID
    items_verificados: dict
    kilometraje_salida: int | None
    nivel_aceite_salida: str | None
    nivel_refrigerante_salida: str | None
    nivel_frenos_salida: str | None
    aprobado: bool
    fecha: datetime
    km_delta: int | None = None

    model_config = {"from_attributes": True}


# --- Invoice (Fase 2.7) ---

class InvoiceCreate(BaseModel):
    metodo_pago: MetodoPago
    es_credito: bool = False
    saldo_pendiente: float = 0.0


class InvoiceResponse(BaseModel):
    id: uuid.UUID
    order_id: uuid.UUID
    monto_total: float
    metodo_pago: MetodoPago
    es_credito: bool
    saldo_pendiente: float
    fecha: datetime

    model_config = {"from_attributes": True}


# --- NPS Survey (Fase 2.7) ---

class NPSSurveyCreate(BaseModel):
    atencion: int = Field(ge=1, le=10)
    instalaciones: int = Field(ge=1, le=10)
    tiempos: int = Field(ge=1, le=10)
    precios: int = Field(ge=1, le=10)
    recomendacion: int = Field(ge=1, le=10)
    comentarios: str | None = None


class NPSSurveyResponse(BaseModel):
    id: uuid.UUID
    order_id: uuid.UUID
    atencion: int
    instalaciones: int
    tiempos: int
    precios: int
    recomendacion: int
    comentarios: str | None
    fecha: datetime

    model_config = {"from_attributes": True}
