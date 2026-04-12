"""
Async PostgreSQL LISTEN/NOTIFY listener.
Connects to Postgres, listens on 'tallerpro_events',
and broadcasts received payloads to all WebSocket clients.
"""
import asyncio
import json
import logging

import psycopg  # psycopg3 async

from . import manager

logger = logging.getLogger(__name__)

LISTEN_CHANNEL = "tallerpro_events"


async def pg_notify_listener(database_url: str) -> None:
    """Background task: subscribes to pg_notify and broadcasts to WS clients."""
    # Convert postgresql+psycopg:// to plain postgresql:// for psycopg3 async DSN
    dsn = database_url.replace("postgresql+psycopg://", "postgresql://").replace("+binary", "")

    while True:  # reconnect loop
        try:
            async with await psycopg.AsyncConnection.connect(dsn, autocommit=True) as conn:
                await conn.execute(f"LISTEN {LISTEN_CHANNEL}")
                logger.info("pg_notify listener started on channel '%s'", LISTEN_CHANNEL)
                async for notify in conn.notifies():
                    try:
                        payload = json.loads(notify.payload)
                        table = payload.get("table", "unknown")
                        action = payload.get("action", "change").lower()
                        event_type = f"{table}.{action}"
                        await manager.broadcast(
                            {
                                "type": event_type,
                                "source": "pg_notify",
                                **payload,
                            }
                        )
                    except Exception as exc:
                        logger.warning("Error processing pg_notify payload: %s", exc)
        except Exception as exc:
            logger.error("pg_notify listener error: %s. Reconnecting in 5s...", exc)
            await asyncio.sleep(5)
