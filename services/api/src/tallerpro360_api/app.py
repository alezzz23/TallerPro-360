import asyncio
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlmodel import Session, text

from .config import settings
from .database import create_db_and_tables, get_session

# Import models so SQLModel.metadata is populated before create_all
from .models import HealthLog, User  # noqa: F401
from .middleware.audit import AuditMiddleware
from .observability import ObservabilityMiddleware, configure_logging, metrics_response
from .routers import (
    analytics_router,
    appointments_router,
    audit_router,
    auth_router,
    customers_router,
    findings_router,
    orders_router,
    quotations_router,
    uploads_router,
    users_router,
    vehicles_router,
)
from .ws.pg_listener import pg_notify_listener
from .ws.router import router as ws_router

configure_logging()


@asynccontextmanager
async def lifespan(app: FastAPI):
    should_auto_create_tables = (
        settings.auto_create_tables
        if settings.auto_create_tables is not None
        else settings.environment == "development"
    )

    if should_auto_create_tables:
        create_db_and_tables()

    listener_task = None
    if settings.enable_pg_listener:
        listener_task = asyncio.create_task(pg_notify_listener(settings.database_url))

    yield
    if listener_task is None:
        return

    listener_task.cancel()
    try:
        await listener_task
    except asyncio.CancelledError:
        pass


def create_app(*, enable_startup: bool = True) -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        lifespan=lifespan if enable_startup else None,
    )
    settings.media_dir.mkdir(parents=True, exist_ok=True)
    app.mount(
        settings.media_url_path,
        StaticFiles(directory=str(settings.media_dir)),
        name="media",
    )

    # WebSocket router — no prefix so final URL is /ws
    app.include_router(ws_router)

    app.include_router(auth_router, prefix=settings.api_prefix)
    app.include_router(appointments_router, prefix=settings.api_prefix)
    app.include_router(customers_router, prefix=settings.api_prefix)
    app.include_router(findings_router, prefix=settings.api_prefix)
    app.include_router(orders_router, prefix=settings.api_prefix)
    app.include_router(quotations_router, prefix=settings.api_prefix)
    app.include_router(uploads_router, prefix=settings.api_prefix)
    app.include_router(vehicles_router, prefix=settings.api_prefix)
    app.include_router(users_router, prefix=settings.api_prefix)
    app.include_router(audit_router, prefix=settings.api_prefix)
    app.include_router(analytics_router, prefix=settings.api_prefix)

    @app.get("/health", tags=["system"])
    def healthcheck() -> dict[str, str]:
        return {"status": "ok", "environment": settings.environment}

    @app.get("/metrics", include_in_schema=False, tags=["system"])
    def metrics():
        return metrics_response()

    @app.get(f"{settings.api_prefix}/meta", tags=["system"])
    def meta() -> dict[str, str]:
        return {
            "app": settings.app_name,
            "version": settings.app_version,
            "api_prefix": settings.api_prefix,
        }

    @app.get(f"{settings.api_prefix}/db-check", tags=["system"])
    def db_check(session: Annotated[Session, Depends(get_session)]) -> dict[str, str]:
        session.exec(text("SELECT 1"))
        return {"status": "ok", "db": "connected"}

    # AuditMiddleware must be added after routes are registered
    app.add_middleware(AuditMiddleware)
    app.add_middleware(ObservabilityMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    return app


app = create_app()
