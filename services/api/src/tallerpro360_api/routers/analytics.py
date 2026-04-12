from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import cast
from sqlalchemy import Date as SADate
from sqlalchemy import extract, func, text
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import require_roles
from ..models.appointment import Appointment
from ..models.diagnostic_finding import DiagnosticFinding
from ..models.invoice import Invoice
from ..models.nps_survey import NPSSurvey
from ..models.part import Part
from ..models.service_order import OrderStatus, ServiceOrder
from ..models.user import User, UserRole

router = APIRouter(prefix="/analytics", tags=["analytics"])

SessionDep = Annotated[Session, Depends(get_session)]
AdminOnly = Annotated[
    User, Depends(require_roles(UserRole.JEFE_TALLER, UserRole.ADMIN))
]


@router.get("/dashboard")
def dashboard(session: SessionDep, _u: AdminOnly) -> dict:
    # Count orders by estado
    order_counts = session.exec(
        select(ServiceOrder.estado, func.count().label("count")).group_by(ServiceOrder.estado)
    ).all()

    # Today's appointments count
    today_appts = session.exec(
        select(func.count()).where(cast(Appointment.fecha, SADate) == date.today())
    ).one()

    # Total open orders (not CERRADA)
    open_orders = session.exec(
        select(func.count()).where(ServiceOrder.estado != OrderStatus.CERRADA)
    ).one()

    # Avg NPS recomendacion (last 30 days)
    cutoff = datetime.now(timezone.utc) - timedelta(days=30)
    avg_nps = session.exec(
        select(func.avg(NPSSurvey.recomendacion)).where(NPSSurvey.fecha >= cutoff)
    ).one()

    return {
        "orders_by_estado": {estado: count for estado, count in order_counts},
        "open_orders": open_orders,
        "todays_appointments": today_appts,
        "avg_nps_30d": round(float(avg_nps or 0), 2),
    }


@router.get("/profitability")
def profitability(
    limit: int = Query(20, ge=1, le=200),
    offset: int = Query(0, ge=0),
    session: SessionDep = None,
    _u: AdminOnly = None,
) -> dict:
    results = session.exec(
        select(
            ServiceOrder.id,
            Invoice.monto_total,
            func.coalesce(func.sum(Part.costo), 0).label("costo_total"),
            (Invoice.monto_total - func.coalesce(func.sum(Part.costo), 0)).label("ganancia"),
        )
        .join(Invoice, Invoice.order_id == ServiceOrder.id)
        .outerjoin(DiagnosticFinding, DiagnosticFinding.order_id == ServiceOrder.id)
        .outerjoin(Part, Part.finding_id == DiagnosticFinding.id)
        .where(ServiceOrder.estado == OrderStatus.CERRADA)
        .group_by(ServiceOrder.id, Invoice.monto_total)
        .order_by(text("ganancia DESC"))
        .offset(offset)
        .limit(limit)
    ).all()

    return {
        "items": [
            {
                "order_id": str(r[0]),
                "ingreso": round(float(r[1]), 2),
                "costo_total": round(float(r[2]), 2),
                "ganancia_neta": round(float(r[3]), 2),
                "margen_pct": round(float(r[3]) / float(r[1]) * 100, 1) if r[1] else 0,
            }
            for r in results
        ]
    }


@router.get("/technician-productivity")
def technician_productivity(session: SessionDep, _u: AdminOnly) -> dict:
    results = session.exec(
        select(
            User.id,
            User.nombre,
            func.count(DiagnosticFinding.id).label("finding_count"),
            func.coalesce(func.sum(DiagnosticFinding.tiempo_estimado), 0).label("horas_producidas"),
        )
        .outerjoin(DiagnosticFinding, DiagnosticFinding.technician_id == User.id)
        .where(User.rol == UserRole.TECNICO)
        .group_by(User.id, User.nombre)
    ).all()

    return {
        "items": [
            {
                "technician_id": str(r[0]),
                "nombre": r[1],
                "findings_count": r[2],
                "horas_producidas": round(float(r[3]), 1),
            }
            for r in results
        ]
    }


@router.get("/pareto")
def pareto(session: SessionDep, _u: AdminOnly) -> dict:
    results = session.exec(
        select(
            DiagnosticFinding.motivo_ingreso,
            func.count().label("frecuencia"),
        )
        .group_by(DiagnosticFinding.motivo_ingreso)
        .order_by(text("frecuencia DESC"))
        .limit(5)
    ).all()

    total = sum(r[1] for r in results)
    return {
        "top_5": [
            {
                "motivo": r[0],
                "frecuencia": r[1],
                "pct": round(r[1] / total * 100, 1) if total else 0,
            }
            for r in results
        ]
    }


@router.get("/avg-ticket")
def avg_ticket(session: SessionDep, _u: AdminOnly) -> dict:
    results = session.exec(
        select(
            extract("year", Invoice.fecha).label("year"),
            extract("month", Invoice.fecha).label("month"),
            func.avg(Invoice.monto_total).label("avg_ticket"),
            func.count().label("count"),
        )
        .group_by("year", "month")
        .order_by(text("year DESC, month DESC"))
        .limit(12)
    ).all()

    return {
        "monthly": [
            {
                "year": int(r[0]),
                "month": int(r[1]),
                "avg_ticket": round(float(r[2]), 2),
                "order_count": r[3],
            }
            for r in results
        ]
    }
