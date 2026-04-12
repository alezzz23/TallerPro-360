from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import get_current_active_user, require_roles
from ..models.appointment import Appointment, AppointmentEstado
from ..models.damage_record import DamageRecord
from ..models.diagnostic_finding import DiagnosticFinding
from ..models.invoice import Invoice
from ..models.nps_survey import NPSSurvey
from ..models.part import Part
from ..models.perimeter_photo import AnguloFoto, PerimeterPhoto
from ..models.quality_check import QualityCheck
from ..models.quotation import Quotation, QuotationEstado
from ..models.quotation_item import QuotationItem
from ..models.reception_checklist import ReceptionChecklist
from ..models.service_order import OrderStatus, ServiceOrder
from ..models.user import User, UserRole
from ..models.vehicle import Vehicle
from ..schemas.findings import FindingCreate, FindingResponse, _SAFETY_WARNING
from ..schemas.findings import PartResponse
from ..schemas.orders import (
    ClientSignatureUpdate,
    DamageRecordCreate,
    DamageRecordResponse,
    InvoiceCreate,
    InvoiceResponse,
    NPSSurveyCreate,
    NPSSurveyResponse,
    PerimeterPhotoCreate,
    PerimeterPhotoResponse,
    QCCreate,
    QCResponse,
    ReceptionChecklistCreate,
    ReceptionChecklistResponse,
    ServiceOrderCreate,
    ServiceOrderListResponse,
    ServiceOrderResponse,
)
from ..schemas.quotations import (
    QuotationCreate,
    QuotationItemResponse,
    QuotationResponse,
)
from ..ws.events import broadcast_order_event

router = APIRouter(prefix="/orders", tags=["orders"])

SessionDep = Annotated[Session, Depends(get_session)]
CurrentUser = Annotated[User, Depends(get_current_active_user)]
AsesorOrAbove = Annotated[
    User,
    Depends(require_roles(UserRole.ASESOR, UserRole.JEFE_TALLER, UserRole.ADMIN)),
]
AsesorTecnicoOrAbove = Annotated[
    User,
    Depends(require_roles(UserRole.ASESOR, UserRole.TECNICO, UserRole.JEFE_TALLER, UserRole.ADMIN)),
]
TecnicoOrAbove = Annotated[
    User,
    Depends(require_roles(UserRole.TECNICO, UserRole.JEFE_TALLER, UserRole.ADMIN)),
]
JefeOrAbove = Annotated[
    User,
    Depends(require_roles(UserRole.JEFE_TALLER, UserRole.ADMIN)),
]

_ALL_ANGULOS = set(AnguloFoto)


def _finding_response(finding: DiagnosticFinding, session: Session) -> FindingResponse:
    fotos: list[str] = json.loads(finding.fotos) if finding.fotos else []
    parts = session.exec(select(Part).where(Part.finding_id == finding.id)).all()
    return FindingResponse(
        id=finding.id,
        order_id=finding.order_id,
        technician_id=finding.technician_id,
        motivo_ingreso=finding.motivo_ingreso,
        descripcion=finding.descripcion,
        tiempo_estimado=finding.tiempo_estimado,
        fotos=fotos,
        es_hallazgo_adicional=finding.es_hallazgo_adicional,
        es_critico_seguridad=finding.es_critico_seguridad,
        parts=[PartResponse.model_validate(p) for p in parts],
        safety_warning=_SAFETY_WARNING if finding.es_critico_seguridad else None,
    )


def _quotation_response(quotation: Quotation, session: Session) -> QuotationResponse:
    items = session.exec(
        select(QuotationItem).where(QuotationItem.quotation_id == quotation.id)
    ).all()
    return QuotationResponse(
        id=quotation.id,
        order_id=quotation.order_id,
        subtotal=quotation.subtotal,
        impuestos=quotation.impuestos,
        shop_supplies=quotation.shop_supplies,
        descuento=quotation.descuento,
        total=quotation.total,
        estado=quotation.estado,
        fecha_envio=quotation.fecha_envio,
        items=[QuotationItemResponse.model_validate(i) for i in items],
    )


def _qc_response(qc: QualityCheck, order: ServiceOrder) -> QCResponse:
    items_dict: dict = json.loads(qc.items_verificados) if qc.items_verificados else {}
    km_delta: int | None = None
    if qc.kilometraje_salida is not None and order.kilometraje_ingreso is not None:
        km_delta = qc.kilometraje_salida - order.kilometraje_ingreso
    return QCResponse(
        id=qc.id,
        order_id=qc.order_id,
        inspector_id=qc.inspector_id,
        items_verificados=items_dict,
        kilometraje_salida=qc.kilometraje_salida,
        nivel_aceite_salida=qc.nivel_aceite_salida,
        nivel_refrigerante_salida=qc.nivel_refrigerante_salida,
        nivel_frenos_salida=qc.nivel_frenos_salida,
        aprobado=qc.aprobado,
        fecha=qc.fecha,
        km_delta=km_delta,
    )


def _reception_complete(order_id: uuid.UUID, session: Session) -> bool:
    checklist = session.exec(
        select(ReceptionChecklist).where(ReceptionChecklist.order_id == order_id)
    ).first()
    if checklist is None:
        return False
    if not checklist.firma_cliente_url:
        return False
    photos = session.exec(
        select(PerimeterPhoto).where(PerimeterPhoto.order_id == order_id)
    ).all()
    covered = {p.angulo for p in photos}
    return covered >= _ALL_ANGULOS


def _order_response(order: ServiceOrder, session: Session) -> ServiceOrderResponse:
    return ServiceOrderResponse(
        id=order.id,
        vehicle_id=order.vehicle_id,
        advisor_id=order.advisor_id,
        estado=order.estado,
        fecha_ingreso=order.fecha_ingreso,
        fecha_salida=order.fecha_salida,
        kilometraje_ingreso=order.kilometraje_ingreso,
        kilometraje_salida=order.kilometraje_salida,
        motivo_ingreso=order.motivo_ingreso,
        reception_complete=_reception_complete(order.id, session),
    )


# --- Service Orders ---

@router.post("/", response_model=ServiceOrderResponse, status_code=status.HTTP_201_CREATED)
def create_order(
    payload: ServiceOrderCreate,
    session: SessionDep,
    _current_user: AsesorOrAbove,
) -> ServiceOrderResponse:
    vehicle = session.get(Vehicle, payload.vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vehicle not found")

    advisor = session.get(User, payload.advisor_id)
    if advisor is None or not advisor.activo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Advisor not found or inactive")

    if payload.appointment_id is not None:
        appt = session.get(Appointment, payload.appointment_id)
        if appt is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Appointment not found")
        appt.estado = AppointmentEstado.COMPLETADA
        session.add(appt)

    order = ServiceOrder(
        vehicle_id=payload.vehicle_id,
        advisor_id=payload.advisor_id,
        estado=OrderStatus.RECEPCION,
        kilometraje_ingreso=payload.kilometraje_ingreso,
        motivo_ingreso=payload.motivo_ingreso,
    )
    session.add(order)
    session.commit()
    session.refresh(order)
    return _order_response(order, session)


@router.get("/", response_model=ServiceOrderListResponse)
def list_orders(
    session: SessionDep,
    _current_user: CurrentUser,
    estado: OrderStatus | None = Query(default=None),
    vehicle_id: uuid.UUID | None = Query(default=None),
    advisor_id: uuid.UUID | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> ServiceOrderListResponse:
    query = select(ServiceOrder)
    if estado is not None:
        query = query.where(ServiceOrder.estado == estado)
    if vehicle_id is not None:
        query = query.where(ServiceOrder.vehicle_id == vehicle_id)
    if advisor_id is not None:
        query = query.where(ServiceOrder.advisor_id == advisor_id)

    total = len(session.exec(query).all())
    orders = session.exec(query.offset(offset).limit(limit)).all()
    return ServiceOrderListResponse(
        items=[_order_response(o, session) for o in orders],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{order_id}", response_model=ServiceOrderResponse)
def get_order(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> ServiceOrderResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    return _order_response(order, session)


# --- Reception Checklist ---

@router.post("/{order_id}/reception-checklist", response_model=ReceptionChecklistResponse)
def upsert_checklist(
    order_id: uuid.UUID,
    payload: ReceptionChecklistCreate,
    session: SessionDep,
    _current_user: AsesorOrAbove,
) -> ReceptionChecklistResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.estado != OrderStatus.RECEPCION:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is in estado {order.estado}, not RECEPCION",
        )

    checklist = session.exec(
        select(ReceptionChecklist).where(ReceptionChecklist.order_id == order_id)
    ).first()

    if checklist is None:
        checklist = ReceptionChecklist(order_id=order_id, **payload.model_dump())
    else:
        for k, v in payload.model_dump().items():
            setattr(checklist, k, v)

    session.add(checklist)
    session.commit()
    session.refresh(checklist)
    return ReceptionChecklistResponse.model_validate(checklist)


@router.get("/{order_id}/reception-checklist", response_model=ReceptionChecklistResponse)
def get_checklist(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> ReceptionChecklistResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    checklist = session.exec(
        select(ReceptionChecklist).where(ReceptionChecklist.order_id == order_id)
    ).first()
    if checklist is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Checklist not found")
    return ReceptionChecklistResponse.model_validate(checklist)


# --- Damage Records ---

@router.post("/{order_id}/damages", response_model=DamageRecordResponse, status_code=status.HTTP_201_CREATED)
def add_damage(
    order_id: uuid.UUID,
    payload: DamageRecordCreate,
    session: SessionDep,
    _current_user: AsesorTecnicoOrAbove,
) -> DamageRecordResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    damage = DamageRecord(order_id=order_id, **payload.model_dump())
    session.add(damage)
    session.commit()
    session.refresh(damage)
    return DamageRecordResponse.model_validate(damage)


@router.get("/{order_id}/damages", response_model=list[DamageRecordResponse])
def list_damages(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> list[DamageRecordResponse]:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    records = session.exec(
        select(DamageRecord).where(DamageRecord.order_id == order_id)
    ).all()
    return [DamageRecordResponse.model_validate(r) for r in records]


# --- Perimeter Photos ---

@router.post("/{order_id}/perimeter-photos", response_model=PerimeterPhotoResponse)
def upsert_perimeter_photo(
    order_id: uuid.UUID,
    payload: PerimeterPhotoCreate,
    session: SessionDep,
    _current_user: AsesorTecnicoOrAbove,
) -> PerimeterPhotoResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    existing = session.exec(
        select(PerimeterPhoto).where(
            PerimeterPhoto.order_id == order_id,
            PerimeterPhoto.angulo == payload.angulo,
        )
    ).first()

    if existing is None:
        photo = PerimeterPhoto(order_id=order_id, angulo=payload.angulo, foto_url=payload.foto_url)
    else:
        existing.foto_url = payload.foto_url
        photo = existing

    session.add(photo)
    session.commit()
    session.refresh(photo)
    return PerimeterPhotoResponse.model_validate(photo)


@router.get("/{order_id}/perimeter-photos", response_model=list[PerimeterPhotoResponse])
def list_perimeter_photos(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> list[PerimeterPhotoResponse]:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    photos = session.exec(
        select(PerimeterPhoto).where(PerimeterPhoto.order_id == order_id)
    ).all()
    return [PerimeterPhotoResponse.model_validate(p) for p in photos]


# --- Client Signature ---

@router.post("/{order_id}/client-signature", response_model=ReceptionChecklistResponse)
def set_client_signature(
    order_id: uuid.UUID,
    payload: ClientSignatureUpdate,
    session: SessionDep,
    _current_user: AsesorOrAbove,
) -> ReceptionChecklistResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")

    checklist = session.exec(
        select(ReceptionChecklist).where(ReceptionChecklist.order_id == order_id)
    ).first()
    if checklist is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Create reception checklist first",
        )

    checklist.firma_cliente_url = payload.firma_cliente_url
    session.add(checklist)
    session.commit()
    session.refresh(checklist)
    return ReceptionChecklistResponse.model_validate(checklist)


# --- Advance Order Estado ---

@router.put("/{order_id}/advance", response_model=ServiceOrderResponse)
def advance_order(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: AsesorOrAbove,
    background_tasks: BackgroundTasks,
) -> ServiceOrderResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.estado != OrderStatus.RECEPCION:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order estado is {order.estado}, can only advance from RECEPCION",
        )

    missing: list[str] = []

    checklist = session.exec(
        select(ReceptionChecklist).where(ReceptionChecklist.order_id == order_id)
    ).first()
    if checklist is None:
        missing.append("reception checklist")

    photos = session.exec(
        select(PerimeterPhoto).where(PerimeterPhoto.order_id == order_id)
    ).all()
    covered = {p.angulo for p in photos}
    missing_angulos = sorted([a.value for a in _ALL_ANGULOS if a not in covered])
    if missing_angulos:
        missing.append(f"perimeter photos for {missing_angulos}")

    if checklist is None or not checklist.firma_cliente_url:
        missing.append("client signature")

    if missing:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Missing: {', '.join(missing)}",
        )

    order.estado = OrderStatus.DIAGNOSTICO
    session.add(order)
    session.commit()
    session.refresh(order)
    background_tasks.add_task(
        broadcast_order_event,
        "order.estado_changed",
        str(order.id),
        {"new_estado": order.estado, "advisor_id": str(order.advisor_id)},
    )
    return _order_response(order, session)


# --- Findings (Fase 2.3 nested routes) ---

@router.get("/{order_id}/findings", response_model=list[FindingResponse])
def list_order_findings(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> list[FindingResponse]:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    findings = session.exec(
        select(DiagnosticFinding).where(DiagnosticFinding.order_id == order_id)
    ).all()
    return [_finding_response(f, session) for f in findings]


@router.post("/{order_id}/findings", response_model=FindingResponse, status_code=status.HTTP_201_CREATED)
def create_finding(
    order_id: uuid.UUID,
    payload: FindingCreate,
    session: SessionDep,
    _current_user: TecnicoOrAbove,
) -> FindingResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.estado != OrderStatus.DIAGNOSTICO:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is in estado {order.estado}, must be DIAGNOSTICO to add findings",
        )
    finding = DiagnosticFinding(
        order_id=order_id,
        technician_id=payload.technician_id,
        motivo_ingreso=payload.motivo_ingreso,
        descripcion=payload.descripcion,
        tiempo_estimado=payload.tiempo_estimado,
        fotos="[]",
        es_hallazgo_adicional=payload.es_hallazgo_adicional,
        es_critico_seguridad=payload.es_critico_seguridad,
    )
    session.add(finding)
    session.commit()
    session.refresh(finding)
    return _finding_response(finding, session)


# --- Quotation (Fase 2.4 nested routes) ---

@router.get("/{order_id}/quotation", response_model=QuotationResponse)
def get_order_quotation(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> QuotationResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    quotation = session.exec(
        select(Quotation).where(Quotation.order_id == order_id)
    ).first()
    if quotation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quotation not found")
    return _quotation_response(quotation, session)


@router.post("/{order_id}/quotation", response_model=QuotationResponse, status_code=status.HTTP_201_CREATED)
def create_order_quotation(
    order_id: uuid.UUID,
    payload: QuotationCreate,
    session: SessionDep,
    _current_user: AsesorOrAbove,
) -> QuotationResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.estado not in (OrderStatus.DIAGNOSTICO, OrderStatus.APROBACION):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is in estado {order.estado}, must be DIAGNOSTICO or APROBACION",
        )

    subtotal = sum(i.mano_obra + i.costo_repuesto for i in payload.items)
    shop_supplies = subtotal * payload.shop_supplies_pct
    descuento = payload.descuento
    impuestos = (subtotal + shop_supplies - descuento) * payload.impuestos_pct
    total = subtotal + shop_supplies + impuestos - descuento

    quotation = Quotation(
        order_id=order_id,
        subtotal=subtotal,
        impuestos=impuestos,
        shop_supplies=shop_supplies,
        descuento=descuento,
        total=total,
    )
    session.add(quotation)
    session.flush()  # get quotation.id

    for item_data in payload.items:
        precio_final = item_data.mano_obra + item_data.costo_repuesto
        item = QuotationItem(
            quotation_id=quotation.id,
            finding_id=item_data.finding_id,
            part_id=item_data.part_id,
            descripcion=item_data.descripcion,
            mano_obra=item_data.mano_obra,
            costo_repuesto=item_data.costo_repuesto,
            precio_final=precio_final,
        )
        session.add(item)

    session.commit()
    session.refresh(quotation)
    return _quotation_response(quotation, session)


# --- Quality Check (Fase 2.6) ---

@router.post("/{order_id}/qc", response_model=QCResponse, status_code=status.HTTP_201_CREATED)
def create_or_update_qc(
    order_id: uuid.UUID,
    payload: QCCreate,
    session: SessionDep,
    _current_user: TecnicoOrAbove,
) -> QCResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.estado != OrderStatus.REPARACION:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is in estado {order.estado}, must be REPARACION for QC",
        )

    existing_qc = session.exec(
        select(QualityCheck).where(QualityCheck.order_id == order_id)
    ).first()

    items_json = json.dumps(payload.items_verificados)

    if existing_qc is None:
        qc = QualityCheck(
            order_id=order_id,
            inspector_id=payload.inspector_id,
            items_verificados=items_json,
            kilometraje_salida=payload.kilometraje_salida,
            nivel_aceite_salida=payload.nivel_aceite_salida,
            nivel_refrigerante_salida=payload.nivel_refrigerante_salida,
            nivel_frenos_salida=payload.nivel_frenos_salida,
            aprobado=payload.aprobado,
        )
    else:
        qc = existing_qc
        qc.inspector_id = payload.inspector_id
        qc.items_verificados = items_json
        qc.kilometraje_salida = payload.kilometraje_salida
        qc.nivel_aceite_salida = payload.nivel_aceite_salida
        qc.nivel_refrigerante_salida = payload.nivel_refrigerante_salida
        qc.nivel_frenos_salida = payload.nivel_frenos_salida
        qc.aprobado = payload.aprobado

    session.add(qc)

    if payload.kilometraje_salida is not None:
        order.kilometraje_salida = payload.kilometraje_salida
        session.add(order)

    if payload.aprobado:
        order.estado = OrderStatus.QC
        session.add(order)

    session.commit()
    session.refresh(qc)
    session.refresh(order)
    return _qc_response(qc, order)


@router.get("/{order_id}/qc", response_model=QCResponse)
def get_qc(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> QCResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    qc = session.exec(
        select(QualityCheck).where(QualityCheck.order_id == order_id)
    ).first()
    if qc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="QC record not found")
    return _qc_response(qc, order)


@router.put("/{order_id}/qc/approve", response_model=QCResponse)
def approve_qc(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: JefeOrAbove,
    background_tasks: BackgroundTasks,
) -> QCResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    qc = session.exec(
        select(QualityCheck).where(QualityCheck.order_id == order_id)
    ).first()
    if qc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="QC record not found")
    qc.aprobado = True
    session.add(qc)
    order.estado = OrderStatus.ENTREGA
    session.add(order)
    session.commit()
    session.refresh(qc)
    session.refresh(order)
    background_tasks.add_task(
        broadcast_order_event,
        "order.estado_changed",
        str(order.id),
        {"new_estado": order.estado, "advisor_id": str(order.advisor_id)},
    )
    return _qc_response(qc, order)


# --- Invoice (Fase 2.7) ---

@router.post("/{order_id}/invoice", response_model=InvoiceResponse, status_code=status.HTTP_201_CREATED)
def create_invoice(
    order_id: uuid.UUID,
    payload: InvoiceCreate,
    session: SessionDep,
    _current_user: AsesorOrAbove,
) -> InvoiceResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.estado != OrderStatus.ENTREGA:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is in estado {order.estado}, must be ENTREGA to invoice",
        )
    existing = session.exec(
        select(Invoice).where(Invoice.order_id == order_id)
    ).first()
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Invoice already generated",
        )
    approved_quotation = session.exec(
        select(Quotation).where(
            Quotation.order_id == order_id,
            Quotation.estado == QuotationEstado.APROBADA,
        )
    ).first()
    if approved_quotation is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No approved quotation found for this order",
        )
    invoice = Invoice(
        order_id=order_id,
        monto_total=approved_quotation.total,
        metodo_pago=payload.metodo_pago,
        es_credito=payload.es_credito,
        saldo_pendiente=payload.saldo_pendiente if payload.es_credito else 0.0,
    )
    session.add(invoice)
    session.commit()
    session.refresh(invoice)
    return InvoiceResponse.model_validate(invoice)


@router.get("/{order_id}/invoice", response_model=InvoiceResponse)
def get_invoice(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> InvoiceResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    invoice = session.exec(
        select(Invoice).where(Invoice.order_id == order_id)
    ).first()
    if invoice is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invoice not found")
    return InvoiceResponse.model_validate(invoice)


# --- NPS Survey (Fase 2.7) ---

@router.post("/{order_id}/nps", response_model=NPSSurveyResponse, status_code=status.HTTP_201_CREATED)
def create_nps(
    order_id: uuid.UUID,
    payload: NPSSurveyCreate,
    session: SessionDep,
    _current_user: CurrentUser,
) -> NPSSurveyResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    existing = session.exec(
        select(NPSSurvey).where(NPSSurvey.order_id == order_id)
    ).first()
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="NPS survey already exists for this order",
        )
    nps = NPSSurvey(
        order_id=order_id,
        atencion=payload.atencion,
        instalaciones=payload.instalaciones,
        tiempos=payload.tiempos,
        precios=payload.precios,
        recomendacion=payload.recomendacion,
        comentarios=payload.comentarios,
    )
    session.add(nps)
    session.commit()
    session.refresh(nps)
    return NPSSurveyResponse.model_validate(nps)


@router.get("/{order_id}/nps", response_model=NPSSurveyResponse)
def get_nps(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> NPSSurveyResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    nps = session.exec(
        select(NPSSurvey).where(NPSSurvey.order_id == order_id)
    ).first()
    if nps is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="NPS survey not found")
    return NPSSurveyResponse.model_validate(nps)


# --- Close Order (Fase 2.7) ---

@router.put("/{order_id}/close", response_model=ServiceOrderResponse)
def close_order(
    order_id: uuid.UUID,
    session: SessionDep,
    _current_user: AsesorOrAbove,
    background_tasks: BackgroundTasks,
) -> ServiceOrderResponse:
    order = session.get(ServiceOrder, order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.estado != OrderStatus.ENTREGA:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Order is in estado {order.estado}, must be ENTREGA to close",
        )
    invoice = session.exec(
        select(Invoice).where(Invoice.order_id == order_id)
    ).first()
    if invoice is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Invoice must exist before closing order",
        )
    nps = session.exec(
        select(NPSSurvey).where(NPSSurvey.order_id == order_id)
    ).first()
    if nps is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="NPS survey required before closing order",
        )
    order.estado = OrderStatus.CERRADA
    order.fecha_salida = datetime.now(timezone.utc)
    session.add(order)
    session.commit()
    session.refresh(order)
    background_tasks.add_task(
        broadcast_order_event,
        "order.closed",
        str(order.id),
        {"advisor_id": str(order.advisor_id)},
    )
    return _order_response(order, session)

