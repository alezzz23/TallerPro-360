import asyncio
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI
from sqlmodel import Session, text

from .config import settings
from .database import create_db_and_tables, get_session

# Import models so SQLModel.metadata is populated before create_all
from .models import HealthLog, User  # noqa: F401
from .middleware.audit import AuditMiddleware
from .routers import (
    analytics_router,
    appointments_router,
    audit_router,
    auth_router,
    customers_router,
    findings_router,
    orders_router,
    quotations_router,
    users_router,
    vehicles_router,
)
from .ws.pg_listener import pg_notify_listener
from .ws.router import router as ws_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    listener_task = asyncio.create_task(pg_notify_listener(settings.database_url))
    yield
    listener_task.cancel()
    try:
        await listener_task
    except asyncio.CancelledError:
        pass


def create_app() -> FastAPI:
    app = FastAPI(title=settings.app_name, lifespan=lifespan)

    # WebSocket router — no prefix so final URL is /ws
    app.include_router(ws_router)

    app.include_router(auth_router, prefix=settings.api_prefix)
    app.include_router(appointments_router, prefix=settings.api_prefix)
    app.include_router(customers_router, prefix=settings.api_prefix)
    app.include_router(findings_router, prefix=settings.api_prefix)
    app.include_router(orders_router, prefix=settings.api_prefix)
    app.include_router(quotations_router, prefix=settings.api_prefix)
    app.include_router(vehicles_router, prefix=settings.api_prefix)
    app.include_router(users_router, prefix=settings.api_prefix)
    app.include_router(audit_router, prefix=settings.api_prefix)
    app.include_router(analytics_router, prefix=settings.api_prefix)

    @app.get("/health", tags=["system"])
    def healthcheck() -> dict[str, str]:
        return {"status": "ok", "environment": settings.environment}

    @app.get(f"{settings.api_prefix}/meta", tags=["system"])
    def meta() -> dict[str, str]:
        return {
            "app": settings.app_name,
            "version": "0.1.0",
            "api_prefix": settings.api_prefix,
        }

    @app.get(f"{settings.api_prefix}/db-check", tags=["system"])
    def db_check(session: Annotated[Session, Depends(get_session)]) -> dict[str, str]:
        session.exec(text("SELECT 1"))
        return {"status": "ok", "db": "connected"}

    # AuditMiddleware must be added after routes are registered
    app.add_middleware(AuditMiddleware)

    return app


app = create_app()
