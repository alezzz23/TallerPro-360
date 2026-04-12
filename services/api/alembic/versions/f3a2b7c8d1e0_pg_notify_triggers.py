"""pg_notify_triggers

Revision ID: f3a2b7c8d1e0
Revises: d89380b75034
Create Date: 2026-04-10 22:45:00.000000

Adds a pg_notify trigger function and triggers on service_order,
appointment, and quotation tables so that state changes are broadcast
via the 'tallerpro_events' LISTEN/NOTIFY channel.
"""
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "f3a2b7c8d1e0"
down_revision: Union[str, Sequence[str], None] = "d89380b75034"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_TABLES = ["service_order", "appointment", "quotation"]

_CREATE_FUNCTION = """
CREATE OR REPLACE FUNCTION notify_tallerpro_events()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    payload TEXT;
BEGIN
    payload := json_build_object(
        'table',  TG_TABLE_NAME,
        'action', TG_OP,
        'id',     COALESCE(NEW.id, OLD.id)
    )::text;
    PERFORM pg_notify('tallerpro_events', payload);
    RETURN NEW;
END;
$$;
"""

_DROP_FUNCTION = "DROP FUNCTION IF EXISTS notify_tallerpro_events() CASCADE;"


def _trigger_name(table: str) -> str:
    return f"trg_{table}_notify"


def upgrade() -> None:
    op.execute(_CREATE_FUNCTION)
    for table in _TABLES:
        tname = _trigger_name(table)
        op.execute(f"""
            CREATE TRIGGER {tname}
            AFTER INSERT OR UPDATE ON {table}
            FOR EACH ROW EXECUTE FUNCTION notify_tallerpro_events();
        """)


def downgrade() -> None:
    for table in _TABLES:
        tname = _trigger_name(table)
        op.execute(f"DROP TRIGGER IF EXISTS {tname} ON {table};")
    op.execute(_DROP_FUNCTION)
