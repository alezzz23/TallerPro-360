from __future__ import annotations

import uuid
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import exc, func
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import get_current_active_user, require_roles
from ..models.customer import Customer
from ..models.user import User, UserRole
from ..models.vehicle import Vehicle
from ..schemas.vehicles import (
    VehicleCreate,
    VehicleListResponse,
    VehicleResponse,
    VehicleUpdate,
)

router = APIRouter(prefix="/vehicles", tags=["vehicles"])

SessionDep = Annotated[Session, Depends(get_session)]
CurrentUser = Annotated[User, Depends(get_current_active_user)]


@router.post("/", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
def create_vehicle(
    body: VehicleCreate,
    session: SessionDep,
    _: Annotated[User, Depends(require_roles(UserRole.ASESOR, UserRole.JEFE_TALLER, UserRole.ADMIN))],
):
    customer = session.get(Customer, body.customer_id)
    if customer is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    vehicle = Vehicle(**body.model_dump())
    session.add(vehicle)
    try:
        session.commit()
    except exc.IntegrityError:
        session.rollback()
        raise HTTPException(status_code=409, detail="Vehicle with this placa or vin already exists")
    session.refresh(vehicle)
    return vehicle


@router.get("/", response_model=VehicleListResponse)
def list_vehicles(
    session: SessionDep,
    _: CurrentUser,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    customer_id: Optional[uuid.UUID] = Query(None),
):
    query = select(Vehicle)
    count_query = select(func.count()).select_from(Vehicle)
    if customer_id is not None:
        query = query.where(Vehicle.customer_id == customer_id)
        count_query = count_query.where(Vehicle.customer_id == customer_id)
    total = session.exec(count_query).one()
    items = session.exec(query.offset(offset).limit(limit)).all()
    return VehicleListResponse(items=list(items), total=total, limit=limit, offset=offset)


@router.get("/{vehicle_id}", response_model=VehicleResponse)
def get_vehicle(vehicle_id: uuid.UUID, session: SessionDep, _: CurrentUser):
    vehicle = session.get(Vehicle, vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return vehicle


@router.put("/{vehicle_id}", response_model=VehicleResponse)
def update_vehicle(
    vehicle_id: uuid.UUID,
    body: VehicleUpdate,
    session: SessionDep,
    _: Annotated[User, Depends(require_roles(UserRole.ASESOR, UserRole.JEFE_TALLER, UserRole.ADMIN))],
):
    vehicle = session.get(Vehicle, vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    data = body.model_dump(exclude_unset=True)
    if "customer_id" in data and data["customer_id"] is not None:
        if session.get(Customer, data["customer_id"]) is None:
            raise HTTPException(status_code=404, detail="Customer not found")
    for field, value in data.items():
        setattr(vehicle, field, value)
    session.add(vehicle)
    try:
        session.commit()
    except exc.IntegrityError:
        session.rollback()
        raise HTTPException(status_code=409, detail="Vehicle with this placa or vin already exists")
    session.refresh(vehicle)
    return vehicle


@router.delete("/{vehicle_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_vehicle(
    vehicle_id: uuid.UUID,
    session: SessionDep,
    _: Annotated[User, Depends(require_roles(UserRole.JEFE_TALLER, UserRole.ADMIN))],
):
    vehicle = session.get(Vehicle, vehicle_id)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    session.delete(vehicle)
    session.commit()
