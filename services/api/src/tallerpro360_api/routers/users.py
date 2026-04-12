from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import get_current_active_user, require_roles
from ..models.user import User, UserRole
from ..schemas.users import UserListResponse, UserResponse, UserUpdate

router = APIRouter(prefix="/users", tags=["users"])

SessionDep = Annotated[Session, Depends(get_session)]
AdminOnly = Annotated[User, Depends(require_roles(UserRole.ADMIN))]


@router.get("/", response_model=UserListResponse)
def list_users(
    session: SessionDep,
    _: AdminOnly,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    total = session.exec(select(func.count()).select_from(User)).one()
    items = session.exec(select(User).offset(offset).limit(limit)).all()
    return UserListResponse(items=list(items), total=total, limit=limit, offset=offset)


@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: uuid.UUID,
    session: SessionDep,
    current_user: Annotated[User, Depends(get_current_active_user)],
):
    # ADMIN can view any user; non-admin can only view themselves
    if current_user.rol != UserRole.ADMIN and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
    user = session.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.put("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: uuid.UUID,
    body: UserUpdate,
    session: SessionDep,
    _: AdminOnly,
):
    user = session.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(user, field, value)
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_user(
    user_id: uuid.UUID,
    session: SessionDep,
    _: AdminOnly,
):
    user = session.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user.activo = False
    session.add(user)
    session.commit()
