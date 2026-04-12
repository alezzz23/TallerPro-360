import json
import logging
import sys
import time
import uuid
from datetime import datetime, timezone
from logging import LogRecord

from fastapi import Request, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest
from starlette.middleware.base import BaseHTTPMiddleware

from .config import settings

_STANDARD_LOG_RECORD_FIELDS = set(LogRecord("", 0, "", 0, "", (), None).__dict__.keys())
_LOGGING_CONFIGURED = False

REQUESTS_TOTAL = Counter(
    "tallerpro360_http_requests_total",
    "Total HTTP requests handled by the API.",
    labelnames=("method", "path", "status_code"),
)
REQUEST_DURATION_SECONDS = Histogram(
    "tallerpro360_http_request_duration_seconds",
    "HTTP request latency in seconds.",
    labelnames=("method", "path"),
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
)
REQUESTS_IN_PROGRESS = Gauge(
    "tallerpro360_http_requests_in_progress",
    "HTTP requests currently being processed.",
    labelnames=("method",),
)
REQUEST_EXCEPTIONS_TOTAL = Counter(
    "tallerpro360_http_request_exceptions_total",
    "HTTP request exceptions raised by the API.",
    labelnames=("method", "path", "exception_type"),
)

logger = logging.getLogger("tallerpro360_api.request")


class JsonFormatter(logging.Formatter):
    def format(self, record: LogRecord) -> str:
        payload: dict[str, object] = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        extras = {
            key: value
            for key, value in record.__dict__.items()
            if key not in _STANDARD_LOG_RECORD_FIELDS and not key.startswith("_")
        }
        if extras:
            payload.update(extras)

        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)

        return json.dumps(payload, default=str)


def configure_logging() -> None:
    global _LOGGING_CONFIGURED

    if _LOGGING_CONFIGURED:
        return

    handler = logging.StreamHandler(sys.stdout)
    if settings.log_json:
        handler.setFormatter(JsonFormatter())
    else:
        handler.setFormatter(
            logging.Formatter(
                "%(asctime)s %(levelname)s %(name)s %(message)s",
                datefmt="%Y-%m-%dT%H:%M:%S%z",
            )
        )

    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(handler)
    root_logger.setLevel(settings.log_level.upper())

    for logger_name in ("uvicorn", "uvicorn.error", "uvicorn.access"):
        uvicorn_logger = logging.getLogger(logger_name)
        uvicorn_logger.handlers.clear()
        uvicorn_logger.propagate = True

    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)

    _LOGGING_CONFIGURED = True


def metrics_response() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


def resolve_request_path(request: Request) -> str:
    route = request.scope.get("route")
    route_path = getattr(route, "path", None)
    if isinstance(route_path, str):
        return route_path
    return request.url.path


class ObservabilityMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get("x-request-id") or uuid.uuid4().hex
        request.state.request_id = request_id
        method = request.method
        start_time = time.perf_counter()

        REQUESTS_IN_PROGRESS.labels(method=method).inc()

        try:
            response = await call_next(request)
        except Exception as exc:
            duration_seconds = time.perf_counter() - start_time
            path = resolve_request_path(request)
            REQUEST_EXCEPTIONS_TOTAL.labels(
                method=method,
                path=path,
                exception_type=type(exc).__name__,
            ).inc()
            REQUESTS_TOTAL.labels(method=method, path=path, status_code="500").inc()
            REQUEST_DURATION_SECONDS.labels(method=method, path=path).observe(duration_seconds)

            logger.exception(
                "request_failed",
                extra={
                    "request_id": request_id,
                    "method": method,
                    "path": path,
                    "status_code": 500,
                    "latency_ms": round(duration_seconds * 1000, 2),
                    "client_ip": request.client.host if request.client else None,
                },
            )
            raise
        finally:
            REQUESTS_IN_PROGRESS.labels(method=method).dec()

        duration_seconds = time.perf_counter() - start_time
        path = resolve_request_path(request)
        REQUESTS_TOTAL.labels(
            method=method,
            path=path,
            status_code=str(response.status_code),
        ).inc()
        REQUEST_DURATION_SECONDS.labels(method=method, path=path).observe(duration_seconds)

        response.headers["X-Request-ID"] = request_id

        logger.info(
            "request_complete",
            extra={
                "request_id": request_id,
                "method": method,
                "path": path,
                "status_code": response.status_code,
                "latency_ms": round(duration_seconds * 1000, 2),
                "client_ip": request.client.host if request.client else None,
            },
        )

        return response