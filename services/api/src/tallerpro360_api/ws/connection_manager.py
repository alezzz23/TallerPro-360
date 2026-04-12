from collections import defaultdict

from fastapi import WebSocket


class ConnectionManager:
    """Manages WebSocket connections grouped by user_id."""

    def __init__(self) -> None:
        self._connections: dict[str, list[WebSocket]] = defaultdict(list)

    async def connect(self, websocket: WebSocket, user_id: str) -> None:
        await websocket.accept()
        self._connections[user_id].append(websocket)

    def disconnect(self, websocket: WebSocket, user_id: str) -> None:
        conns = self._connections.get(user_id, [])
        if websocket in conns:
            conns.remove(websocket)

    async def broadcast(self, message: dict) -> None:
        """Send message to ALL connected clients."""
        dead: list[tuple[str, WebSocket]] = []
        for user_id, sockets in self._connections.items():
            for ws in list(sockets):
                try:
                    await ws.send_json(message)
                except Exception:
                    dead.append((user_id, ws))
        for user_id, ws in dead:
            self.disconnect(ws, user_id)

    async def send_to_user(self, user_id: str, message: dict) -> None:
        """Send message to a specific user."""
        for ws in list(self._connections.get(user_id, [])):
            try:
                await ws.send_json(message)
            except Exception:
                self.disconnect(ws, user_id)


manager = ConnectionManager()
