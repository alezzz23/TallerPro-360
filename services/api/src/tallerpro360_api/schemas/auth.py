import uuid

from pydantic import BaseModel, EmailStr

from ..models.user import UserRole


class RegisterRequest(BaseModel):
    nombre: str
    email: EmailStr
    password: str
    rol: UserRole = UserRole.ASESOR


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: uuid.UUID
    nombre: str
    email: str
    rol: UserRole
    activo: bool
