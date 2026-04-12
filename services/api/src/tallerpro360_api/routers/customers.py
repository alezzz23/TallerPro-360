from __future__ import annotations

import uuid
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import get_current_active_user, require_roles
from ..models.customer import Customer
from ..models.user import User, UserRole
from ..search import build_prefix_search_pattern
from ..schemas.customers import (
    CustomerCreate,
    CustomerListResponse,
    CustomerResponse,
    CustomerUpdate,
)

router = APIRouter(prefix="/customers", tags=["customers"])

SessionDep = Annotated[Session, Depends(get_session)]
CurrentUser = Annotated[User, Depends(get_current_active_user)]


def _customer_search_filters(
    q: Optional[str],
    nombre: Optional[str],
    telefono: Optional[str],
    email: Optional[str],
    whatsapp: Optional[str],
):
    filters = []

    if q_pattern := build_prefix_search_pattern(q):
        filters.append(
            or_(
                Customer.nombre.ilike(q_pattern, escape="\\"),
                Customer.telefono.ilike(q_pattern, escape="\\"),
                Customer.email.ilike(q_pattern, escape="\\"),
                Customer.whatsapp.ilike(q_pattern, escape="\\"),
            )
        )
    if nombre_pattern := build_prefix_search_pattern(nombre):
        filters.append(Customer.nombre.ilike(nombre_pattern, escape="\\"))
    if telefono_pattern := build_prefix_search_pattern(telefono):
        filters.append(Customer.telefono.ilike(telefono_pattern, escape="\\"))
    if email_pattern := build_prefix_search_pattern(email):
        filters.append(Customer.email.ilike(email_pattern, escape="\\"))
    if whatsapp_pattern := build_prefix_search_pattern(whatsapp):
        filters.append(Customer.whatsapp.ilike(whatsapp_pattern, escape="\\"))

    return filters


@router.post("/", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
def create_customer(
    body: CustomerCreate,
    session: SessionDep,
    _: Annotated[User, Depends(require_roles(UserRole.ASESOR, UserRole.JEFE_TALLER, UserRole.ADMIN))],
):
    customer = Customer(**body.model_dump())
    session.add(customer)
    session.commit()
    session.refresh(customer)
    return customer


@router.get("/", response_model=CustomerListResponse)
def list_customers(
    session: SessionDep,
    _: CurrentUser,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    q: Optional[str] = Query(None),
    nombre: Optional[str] = Query(None),
    telefono: Optional[str] = Query(None),
    email: Optional[str] = Query(None),
    whatsapp: Optional[str] = Query(None),
):
    query = select(Customer)
    count_query = select(func.count()).select_from(Customer)

    filters = _customer_search_filters(
        q=q,
        nombre=nombre,
        telefono=telefono,
        email=email,
        whatsapp=whatsapp,
    )
    if filters:
        query = query.where(*filters)
        count_query = count_query.where(*filters)

    total = session.exec(count_query).one()
    items = session.exec(query.offset(offset).limit(limit)).all()
    return CustomerListResponse(items=list(items), total=total, limit=limit, offset=offset)


@router.get("/{customer_id}", response_model=CustomerResponse)
def get_customer(customer_id: uuid.UUID, session: SessionDep, _: CurrentUser):
    customer = session.get(Customer, customer_id)
    if customer is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    return customer


@router.put("/{customer_id}", response_model=CustomerResponse)
def update_customer(
    customer_id: uuid.UUID,
    body: CustomerUpdate,
    session: SessionDep,
    _: Annotated[User, Depends(require_roles(UserRole.ASESOR, UserRole.JEFE_TALLER, UserRole.ADMIN))],
):
    customer = session.get(Customer, customer_id)
    if customer is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(customer, field, value)
    session.add(customer)
    session.commit()
    session.refresh(customer)
    return customer


@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_customer(
    customer_id: uuid.UUID,
    session: SessionDep,
    _: Annotated[User, Depends(require_roles(UserRole.JEFE_TALLER, UserRole.ADMIN))],
):
    customer = session.get(Customer, customer_id)
    if customer is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    session.delete(customer)
    session.commit()
