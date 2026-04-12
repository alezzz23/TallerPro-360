from .app import app as app, create_app as create_app

__all__ = ["app", "create_app", "main"]


def main() -> None:
    import uvicorn

    uvicorn.run(
        "tallerpro360_api.app:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        access_log=False,
    )
