from __future__ import annotations

import uuid
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import Date as SADate, cast, func
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import get_current_active_user, require_roles
from ..models.appointment import Appointment, AppointmentEstado
from ..models.customer import Customer
from ..models.user import User, UserRole
from ..models.vehicle import Vehicle
from ..schemas.appointments import (
    AppointmentCreate,
    AppointmentListResponse,
    AppointmentResponse,
    AppointmentUpdate,
)

router = APIRouter(prefix="/appointments", tags=["appointments"])

SessionDep = Annotated[Session, Depends(get_session)]
CurrentUser = Annotated[User, Depends(get_current_active_user)]
AsesorOrAbove = Annotated[
    User,
    Depends(require_roles(UserRole.ASESOR, UserRole.JEFE_TALLER, UserRole.ADMIN)),
]
JefeOrAbove = Annotated[
    User,
    Depends(require_roles(UserRole.JEFE_TALLER, UserRole.ADMIN)),
]

_ACTIVE_ESTADOS = (AppointmentEstado.PENDIENTE, AppointmentEstado.CONFIRMADA)


def _check_conflict(
    session: Session,
    fecha: datetime,
    bloque_horario: str,
    exclude_id: uuid.UUID | None = None,
) -> None:
    query = select(Appointment).where(
        cast(Appointment.fecha, SADate) == fecha.date(),
        Appointment.bloque_horario == bloque_horario,
        Appointment.estado.in_(_ACTIVE_ESTADOS),
    )
    if exclude_id is not None:
        query = query.where(Appointment.id != exclude_id)
    conflict = session.exec(query).first()
    if conflict:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Time slot already booked",
        )


@router.post("/", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
def create_appointment(body: AppointmentCreate, session: SessionDep, _: AsesorOrAbove):
    if session.get(Customer, body.customer_id) is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    if body.vehicle_id is not None and session.get(Vehicle, body.vehicle_id) is None:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    _check_conflict(session, body.fecha, body.bloque_horario)

    appointment = Appointment(**body.model_dump())
    session.add(appointment)
    session.commit()
    session.refresh(appointment)
    return appointment


@router.get("/", response_model=AppointmentListResponse)
def list_appointments(
    session: SessionDep,
    _: CurrentUser,
    date: str | None = Query(None, description="Filter by day YYYY-MM-DD"),
    customer_id: uuid.UUID | None = None,
    estado: AppointmentEstado | None = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    base = select(Appointment)

    if date is not None:
        date_obj = datetime.strptime(date, "%Y-%m-%d").date()
        base = base.where(cast(Appointment.fecha, SADate) == date_obj)
    if customer_id is not None:
        base = base.where(Appointment.customer_id == customer_id)
    if estado is not None:
        base = base.where(Appointment.estado == estado)

    total = session.exec(
        select(func.count()).select_from(base.subquery())
    ).one()

    items = session.exec(base.offset(offset).limit(limit)).all()
    return AppointmentListResponse(items=list(items), total=total, limit=limit, offset=offset)


@router.get("/{appointment_id}", response_model=AppointmentResponse)
def get_appointment(appointment_id: uuid.UUID, session: SessionDep, _: CurrentUser):
    appt = session.get(Appointment, appointment_id)
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return appt


@router.put("/{appointment_id}", response_model=AppointmentResponse)
def update_appointment(
    appointment_id: uuid.UUID,
    body: AppointmentUpdate,
    session: SessionDep,
    _: AsesorOrAbove,
):
    appt = session.get(Appointment, appointment_id)
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found")

    new_fecha = body.fecha if body.fecha is not None else appt.fecha
    new_bloque = body.bloque_horario if body.bloque_horario is not None else appt.bloque_horario

    if body.fecha is not None or body.bloque_horario is not None:
        _check_conflict(session, new_fecha, new_bloque, exclude_id=appointment_id)

    for field, value in body.model_dump(exclude_none=True).items():
        setattr(appt, field, value)

    session.add(appt)
    session.commit()
    session.refresh(appt)
    return appt


@router.put("/{appointment_id}/cancel", response_model=AppointmentResponse)
def cancel_appointment(appointment_id: uuid.UUID, session: SessionDep, _: AsesorOrAbove):
    appt = session.get(Appointment, appointment_id)
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if appt.estado == AppointmentEstado.CANCELADA:
        raise HTTPException(status_code=409, detail="Appointment already cancelled")
    if appt.estado == AppointmentEstado.COMPLETADA:
        raise HTTPException(status_code=409, detail="Cannot cancel a completed appointment")

    appt.estado = AppointmentEstado.CANCELADA
    session.add(appt)
    session.commit()
    session.refresh(appt)
    return appt


@router.put("/{appointment_id}/confirm", response_model=AppointmentResponse)
def confirm_appointment(appointment_id: uuid.UUID, session: SessionDep, _: JefeOrAbove):
    appt = session.get(Appointment, appointment_id)
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if appt.estado != AppointmentEstado.PENDIENTE:
        raise HTTPException(
            status_code=409,
            detail="Only PENDIENTE appointments can be confirmed",
        )

    appt.estado = AppointmentEstado.CONFIRMADA
    session.add(appt)
    session.commit()
    session.refresh(appt)
    return appt
