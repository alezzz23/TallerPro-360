from .analytics import router as analytics_router
from .appointments import router as appointments_router
from .audit import router as audit_router
from .auth import router as auth_router
from .customers import router as customers_router
from .findings import router as findings_router
from .orders import router as orders_router
from .quotations import router as quotations_router
from .users import router as users_router
from .vehicles import router as vehicles_router

__all__ = [
    "analytics_router",
    "appointments_router",
    "audit_router",
    "auth_router",
    "customers_router",
    "findings_router",
    "orders_router",
    "quotations_router",
    "vehicles_router",
    "users_router",
]
