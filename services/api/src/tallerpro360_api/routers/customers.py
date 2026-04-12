from __future__ import annotations

import uuid
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import get_current_active_user, require_roles
from ..models.customer import Customer
from ..models.user import User, UserRole
from ..schemas.customers import (
    CustomerCreate,
    CustomerListResponse,
    CustomerResponse,
    CustomerUpdate,
)

router = APIRouter(prefix="/customers", tags=["customers"])

SessionDep = Annotated[Session, Depends(get_session)]
CurrentUser = Annotated[User, Depends(get_current_active_user)]


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
):
    total = session.exec(select(func.count()).select_from(Customer)).one()
    items = session.exec(select(Customer).offset(offset).limit(limit)).all()
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
