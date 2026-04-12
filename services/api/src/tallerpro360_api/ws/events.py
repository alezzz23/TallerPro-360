from . import manager


async def broadcast_order_event(event_type: str, order_id: str, data: dict) -> None:
    """Broadcast an order state change to all connected clients."""
    await manager.broadcast(
        {
            "type": event_type,
            "order_id": order_id,
            **data,
        }
    )


async def notify_user(user_id: str, event_type: str, data: dict) -> None:
    """Send targeted event to a specific user."""
    await manager.send_to_user(
        user_id,
        {
            "type": event_type,
            **data,
        },
    )
