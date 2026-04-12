import uuid
from datetime import datetime, timezone

from fastapi import Request
from sqlmodel import Session
from starlette.middleware.base import BaseHTTPMiddleware

from ..database import engine
from ..models.audit_log import AuditLog
from ..security import decode_access_token

AUDIT_METHODS = {"POST", "PUT", "DELETE", "PATCH"}
SKIP_PATHS = {
    "/health",
    "/ws",
    "/api/v1/db-check",
    "/api/v1/meta",
    "/docs",
    "/openapi.json",
    "/redoc",
}


class AuditMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)

        # Only audit mutating successful requests
        if request.method not in AUDIT_METHODS:
            return response
        if response.status_code >= 400:
            return response
        if any(request.url.path.startswith(p) for p in SKIP_PATHS):
            return response

        # Extract user from JWT
        user_id: uuid.UUID | None = None
        auth = request.headers.get("authorization", "")
        if auth.startswith("Bearer "):
            payload = decode_access_token(auth[7:])
            if payload:
                user_id_str = payload.get("sub")
                if user_id_str:
                    try:
                        user_id = uuid.UUID(user_id_str)
                    except ValueError:
                        pass

        # Extract order_id from path if present
        order_id: uuid.UUID | None = None
        path_parts = request.url.path.split("/")
        try:
            order_idx = path_parts.index("orders")
            if order_idx + 1 < len(path_parts):
                order_id = uuid.UUID(path_parts[order_idx + 1])
        except (ValueError, IndexError):
            pass

        accion = f"{request.method} {request.url.path}"
        device = request.headers.get("user-agent", "unknown")[:200]

        log = AuditLog(
            user_id=user_id,
            order_id=order_id,
            accion=accion,
            detalle=None,
            dispositivo=device,
            timestamp=datetime.now(timezone.utc),
        )

        try:
            with Session(engine) as session:
                session.add(log)
                session.commit()
        except Exception:
            pass  # Never let audit failure crash the request

        return response
