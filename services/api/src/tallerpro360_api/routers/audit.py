from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import require_roles
from ..models.audit_log import AuditLog
from ..models.user import User, UserRole

router = APIRouter(prefix="/audit", tags=["audit"])


@router.get("/")
def list_audit(
    order_id: uuid.UUID | None = Query(None),
    user_id: uuid.UUID | None = Query(None),
    limit: int = Query(50, le=200),
    offset: int = Query(0),
    session: Annotated[Session, Depends(get_session)] = None,
    _current_user: Annotated[
        User, Depends(require_roles(UserRole.JEFE_TALLER, UserRole.ADMIN))
    ] = None,
) -> dict:
    query = select(AuditLog).order_by(AuditLog.timestamp.desc())
    if order_id:
        query = query.where(AuditLog.order_id == order_id)
    if user_id:
        query = query.where(AuditLog.user_id == user_id)

    total = session.exec(
        select(func.count()).select_from(query.subquery())
    ).one()
    items = session.exec(query.offset(offset).limit(limit)).all()
    return {
        "items": [i.model_dump() for i in items],
        "total": total,
        "limit": limit,
        "offset": offset,
    }
