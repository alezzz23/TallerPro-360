from fastapi.testclient import TestClient

from tallerpro360_api.app import create_app
from tallerpro360_api.config import settings


def make_client() -> TestClient:
    return TestClient(create_app(enable_startup=False))


def test_health_endpoint_returns_expected_payload() -> None:
    with make_client() as client:
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "environment": "development"}
    assert response.headers["x-request-id"]


def test_meta_endpoint_returns_application_metadata() -> None:
    with make_client() as client:
        response = client.get("/api/v1/meta")

    assert response.status_code == 200
    assert response.json() == {
        "app": settings.app_name,
        "version": settings.app_version,
        "api_prefix": settings.api_prefix,
    }


def test_metrics_endpoint_exposes_prometheus_payload() -> None:
    with make_client() as client:
        client.get("/health")
        client.get("/api/v1/meta")
        response = client.get("/metrics")

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/plain")
    assert "tallerpro360_http_requests_total" in response.text
    assert 'path="/health"' in response.text
    assert 'path="/api/v1/meta"' in response.text