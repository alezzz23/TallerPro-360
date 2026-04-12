import json
import uuid

from sqlmodel import SQLModel, Session, create_engine, select

from tallerpro360_api.models import (
    Appointment,
    Customer,
    DiagnosticFinding,
    Invoice,
    NPSSurvey,
    Part,
    QualityCheck,
    Quotation,
    QuotationItem,
    ReceptionChecklist,
    ServiceOrder,
    User,
    Vehicle,
)
from tallerpro360_api.security import verify_password
from tallerpro360_api.seed import DEFAULT_DEMO_PASSWORD, seed_database


def test_seed_database_is_idempotent(tmp_path):
    database_path = tmp_path / "seed.sqlite"
    engine = create_engine(f"sqlite:///{database_path}")
    SQLModel.metadata.create_all(engine)

    with Session(engine) as session:
        first_run = seed_database(session, demo_password=DEFAULT_DEMO_PASSWORD)

    assert first_run["created"]["users"] == 4
    assert first_run["created"]["customers"] == 3
    assert first_run["created"]["vehicles"] == 3
    assert first_run["created"]["orders"] == 3

    with Session(engine) as session:
        admin_user = session.exec(
            select(User).where(User.email == "admin@demo.tallerpro360.com")
        ).first()
        assert admin_user is not None
        assert verify_password(DEFAULT_DEMO_PASSWORD, admin_user.password_hash)

        assert len(session.exec(select(User)).all()) == 4
        assert len(session.exec(select(Customer)).all()) == 3
        assert len(session.exec(select(Vehicle)).all()) == 3
        assert len(session.exec(select(Appointment)).all()) == 2
        assert len(session.exec(select(ServiceOrder)).all()) == 3
        assert len(session.exec(select(ReceptionChecklist)).all()) == 3
        assert len(session.exec(select(DiagnosticFinding)).all()) == 3
        assert len(session.exec(select(Part)).all()) == 3
        assert len(session.exec(select(Quotation)).all()) == 3
        assert len(session.exec(select(QuotationItem)).all()) == 3
        assert len(session.exec(select(QualityCheck)).all()) == 2
        assert len(session.exec(select(Invoice)).all()) == 1
        assert len(session.exec(select(NPSSurvey)).all()) == 1

        qc_record = session.exec(
            select(QualityCheck).where(
                QualityCheck.order_id == uuid.UUID("50000000-0000-0000-0000-000000000002")
            )
        ).first()
        assert qc_record is not None
        assert json.loads(qc_record.items_verificados or "{}") == {
            "ruido en frenado": True,
            "alineacion": True,
            "prueba de ruta": True,
        }

    with Session(engine) as session:
        second_run = seed_database(session, demo_password=DEFAULT_DEMO_PASSWORD)

    assert second_run["created"] == {}
    assert second_run["updated"] == {}

    with Session(engine) as session:
        assert len(session.exec(select(User)).all()) == 4
        assert len(session.exec(select(ServiceOrder)).all()) == 3
        assert len(session.exec(select(Invoice)).all()) == 1
        assert len(session.exec(select(NPSSurvey)).all()) == 1