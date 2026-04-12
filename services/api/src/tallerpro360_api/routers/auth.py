from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import get_current_active_user
from ..models.user import User
from ..schemas.auth import LoginRequest, RegisterRequest, TokenResponse, UserResponse
from ..security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(
    body: RegisterRequest,
    session: Annotated[Session, Depends(get_session)],
) -> User:
    existing = session.exec(select(User).where(User.email == body.email)).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    user = User(
        nombre=body.nombre,
        email=body.email,
        password_hash=hash_password(body.password),
        rol=body.rol,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
def login(
    body: LoginRequest,
    session: Annotated[Session, Depends(get_session)],
) -> TokenResponse:
    user = session.exec(select(User).where(User.email == body.email)).first()
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.activo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user",
        )
    token = create_access_token(
        {"sub": str(user.id), "email": user.email, "rol": user.rol}
    )
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserResponse)
def me(
    current_user: Annotated[User, Depends(get_current_active_user)],
) -> User:
    return current_user
