import json
import uuid
from datetime import datetime, timezone

from tallerpro360_api.models import OrderStatus, QualityCheck, ServiceOrder
from tallerpro360_api.routers.orders import _qc_response


def test_qc_response_normalizes_legacy_list_payload() -> None:
    order_id = uuid.uuid4()
    qc = QualityCheck(
        id=uuid.uuid4(),
        order_id=order_id,
        inspector_id=uuid.uuid4(),
        items_verificados=json.dumps(["ruido en frenado", "alineacion"]),
        kilometraje_salida=112315,
        aprobado=False,
        fecha=datetime.now(timezone.utc),
    )
    order = ServiceOrder(
        id=order_id,
        vehicle_id=uuid.uuid4(),
        advisor_id=uuid.uuid4(),
        estado=OrderStatus.QC,
        fecha_ingreso=datetime.now(timezone.utc),
        kilometraje_ingreso=112300,
    )

    response = _qc_response(qc, order)

    assert response.items_verificados == {
        "ruido en frenado": True,
        "alineacion": True,
    }
    assert response.km_delta == 15