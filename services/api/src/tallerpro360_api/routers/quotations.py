from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import get_current_active_user, require_roles
from ..models.diagnostic_finding import DiagnosticFinding
from ..models.quotation import Quotation, QuotationEstado
from ..models.quotation_item import QuotationItem
from ..models.service_order import OrderStatus, ServiceOrder
from ..models.user import User, UserRole
from ..schemas.quotations import (
    QuotationDiscountUpdate,
    QuotationItemResponse,
    QuotationRejectBody,
    QuotationRejectResponse,
    QuotationResponse,
)
from ..ws.events import broadcast_order_event

router = APIRouter(prefix="/quotations", tags=["quotations"])

SessionDep = Annotated[Session, Depends(get_session)]
CurrentUser = Annotated[User, Depends(get_current_active_user)]
AsesorOrAbove = Annotated[
    User,
    Depends(require_roles(UserRole.ASESOR, UserRole.JEFE_TALLER, UserRole.ADMIN)),
]


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


@router.get("/{quotation_id}", response_model=QuotationResponse)
def get_quotation(
    quotation_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> QuotationResponse:
    quotation = session.get(Quotation, quotation_id)
    if quotation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quotation not found")
    return _quotation_response(quotation, session)


@router.put("/{quotation_id}/discount", response_model=QuotationResponse)
def apply_discount(
    quotation_id: uuid.UUID,
    payload: QuotationDiscountUpdate,
    session: SessionDep,
    _current_user: AsesorOrAbove,
) -> QuotationResponse:
    quotation = session.get(Quotation, quotation_id)
    if quotation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quotation not found")
    # Recompute total with new discount
    subtotal = quotation.subtotal
    shop_supplies = quotation.shop_supplies
    descuento = payload.descuento
    # Derive original impuestos_pct from stored values
    if (subtotal + shop_supplies - quotation.descuento) != 0:
        impuestos_pct = quotation.impuestos / (subtotal + shop_supplies - quotation.descuento)
    else:
        impuestos_pct = 0.16
    impuestos = (subtotal + shop_supplies - descuento) * impuestos_pct
    total = subtotal + shop_supplies + impuestos - descuento
    quotation.descuento = descuento
    quotation.impuestos = impuestos
    quotation.total = total
    session.add(quotation)
    session.commit()
    session.refresh(quotation)
    return _quotation_response(quotation, session)


@router.post("/{quotation_id}/send", response_model=QuotationResponse)
def send_quotation(
    quotation_id: uuid.UUID,
    session: SessionDep,
    _current_user: AsesorOrAbove,
) -> QuotationResponse:
    quotation = session.get(Quotation, quotation_id)
    if quotation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quotation not found")
    quotation.fecha_envio = datetime.now(timezone.utc)
    session.add(quotation)
    session.commit()
    session.refresh(quotation)
    return _quotation_response(quotation, session)


@router.post("/{quotation_id}/approve", response_model=QuotationResponse)
def approve_quotation(
    quotation_id: uuid.UUID,
    session: SessionDep,
    _current_user: AsesorOrAbove,
    background_tasks: BackgroundTasks,
) -> QuotationResponse:
    quotation = session.get(Quotation, quotation_id)
    if quotation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quotation not found")
    if quotation.estado != QuotationEstado.PENDIENTE:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Quotation estado is {quotation.estado}, must be PENDIENTE to approve",
        )
    quotation.estado = QuotationEstado.APROBADA
    session.add(quotation)

    order = session.get(ServiceOrder, quotation.order_id)
    if order is not None and order.estado in (OrderStatus.DIAGNOSTICO, OrderStatus.APROBACION):
        order.estado = OrderStatus.REPARACION
        session.add(order)

    session.commit()
    session.refresh(quotation)
    background_tasks.add_task(
        broadcast_order_event,
        "quotation.approved",
        str(quotation.order_id),
        {"quotation_id": str(quotation.id)},
    )
    return _quotation_response(quotation, session)


@router.post("/{quotation_id}/reject", response_model=QuotationRejectResponse)
def reject_quotation(
    quotation_id: uuid.UUID,
    payload: QuotationRejectBody,
    session: SessionDep,
    _current_user: AsesorOrAbove,
) -> QuotationRejectResponse:
    quotation = session.get(Quotation, quotation_id)
    if quotation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quotation not found")
    if quotation.estado != QuotationEstado.PENDIENTE:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Quotation estado is {quotation.estado}, must be PENDIENTE to reject",
        )
    quotation.estado = QuotationEstado.RECHAZADA
    session.add(quotation)

    order = session.get(ServiceOrder, quotation.order_id)
    if order is not None:
        order.estado = OrderStatus.APROBACION
        session.add(order)

    # Check for critical security findings
    safety_log: str | None = None
    items = session.exec(
        select(QuotationItem).where(QuotationItem.quotation_id == quotation_id)
    ).all()
    finding_ids = [i.finding_id for i in items]
    if finding_ids:
        critical = session.exec(
            select(DiagnosticFinding).where(
                DiagnosticFinding.id.in_(finding_ids),
                DiagnosticFinding.es_critico_seguridad == True,  # noqa: E712
            )
        ).first()
        if critical is not None:
            ts = datetime.now(timezone.utc).isoformat()
            safety_log = f"Rechazo de hallazgo crítico de seguridad registrado con timestamp: {ts}"

    session.commit()
    session.refresh(quotation)
    base = _quotation_response(quotation, session)
    return QuotationRejectResponse(**base.model_dump(), safety_log=safety_log)
