from .app import create_app


def main() -> None:
    import uvicorn

    uvicorn.run(
        "tallerpro360_api.app:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )


app = create_app()
