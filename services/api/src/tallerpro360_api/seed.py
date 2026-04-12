from __future__ import annotations

import argparse
import json
import uuid
from collections import defaultdict
from collections.abc import Sequence
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from enum import Enum
from typing import Any

from sqlmodel import Session, select

from .database import engine
from .models import (
    Appointment,
    AppointmentEstado,
    Customer,
    DiagnosticFinding,
    Invoice,
    MetodoPago,
    NPSSurvey,
    OrderStatus,
    Part,
    PartOrigen,
    QualityCheck,
    Quotation,
    QuotationEstado,
    QuotationItem,
    ReceptionChecklist,
    ServiceOrder,
    User,
    UserRole,
    Vehicle,
)
from .security import hash_password, verify_password

DEFAULT_DEMO_PASSWORD = "TallerPro360!2026"


@dataclass(frozen=True)
class SeedContext:
    anchor: datetime


def _seed_context() -> SeedContext:
    anchor = datetime.now(timezone.utc).replace(hour=9, minute=0, second=0, microsecond=0)
    return SeedContext(anchor=anchor)


def _uid(value: str) -> uuid.UUID:
    return uuid.UUID(value)


def _json(value: Sequence[str]) -> str:
    return json.dumps(list(value), ensure_ascii=True)


def _qc_items(value: Sequence[str]) -> str:
    return json.dumps({item: True for item in value}, ensure_ascii=True)


def _serialize(value: Any) -> Any:
    if isinstance(value, Enum):
        return value.value
    if isinstance(value, uuid.UUID):
        return str(value)
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.isoformat()
    return value


def _is_changed(current: Any, new: Any) -> bool:
    return _serialize(current) != _serialize(new)


def _set_fields(instance: Any, fields: dict[str, Any]) -> bool:
    changed = False
    for field_name, field_value in fields.items():
        if not _is_changed(getattr(instance, field_name), field_value):
            continue
        setattr(instance, field_name, field_value)
        changed = True
    return changed


def _record_stats(stats: dict[str, dict[str, int]], table: str, *, created: bool) -> None:
    bucket = "created" if created else "updated"
    stats[bucket][table] += 1


def _upsert_by_id(
    session: Session,
    model: type[Any],
    *,
    table_name: str,
    entity_id: uuid.UUID,
    fields: dict[str, Any],
    stats: dict[str, dict[str, int]],
) -> Any:
    instance = session.get(model, entity_id)
    if instance is None:
        instance = model(id=entity_id, **fields)
        session.add(instance)
        _record_stats(stats, table_name, created=True)
        return instance

    if _set_fields(instance, fields):
        _record_stats(stats, table_name, created=False)
    return instance


def _ensure_user(
    session: Session,
    *,
    entity_id: uuid.UUID,
    nombre: str,
    email: str,
    rol: UserRole,
    password: str,
    stats: dict[str, dict[str, int]],
) -> User:
    user = session.exec(select(User).where(User.email == email)).first()
    password_hash = hash_password(password)
    if user is None:
        user = User(
            id=entity_id,
            nombre=nombre,
            email=email,
            password_hash=password_hash,
            rol=rol,
            activo=True,
        )
        session.add(user)
        _record_stats(stats, "users", created=True)
        return user

    updated = _set_fields(
        user,
        {
            "nombre": nombre,
            "rol": rol,
            "activo": True,
        },
    )
    if not verify_password(password, user.password_hash):
        user.password_hash = password_hash
        updated = True
    if updated:
        _record_stats(stats, "users", created=False)
    return user


def _ensure_vehicle(
    session: Session,
    *,
    entity_id: uuid.UUID,
    placa: str,
    fields: dict[str, Any],
    stats: dict[str, dict[str, int]],
) -> Vehicle:
    vehicle = session.exec(select(Vehicle).where(Vehicle.placa == placa)).first()
    if vehicle is None:
        vehicle = Vehicle(id=entity_id, placa=placa, **fields)
        session.add(vehicle)
        _record_stats(stats, "vehicles", created=True)
        return vehicle

    if _set_fields(vehicle, {"placa": placa, **fields}):
        _record_stats(stats, "vehicles", created=False)
    return vehicle


def _build_seed_bundle(context: SeedContext) -> dict[str, Any]:
    anchor = context.anchor

    users = [
        {
            "id": _uid("10000000-0000-0000-0000-000000000001"),
            "nombre": "Administrador Demo",
            "email": "admin@demo.tallerpro360.com",
            "rol": UserRole.ADMIN,
        },
        {
            "id": _uid("10000000-0000-0000-0000-000000000002"),
            "nombre": "Andrea Asesora",
            "email": "asesor@demo.tallerpro360.com",
            "rol": UserRole.ASESOR,
        },
        {
            "id": _uid("10000000-0000-0000-0000-000000000003"),
            "nombre": "Tomas Tecnico",
            "email": "tecnico@demo.tallerpro360.com",
            "rol": UserRole.TECNICO,
        },
        {
            "id": _uid("10000000-0000-0000-0000-000000000004"),
            "nombre": "Julia Jefe Taller",
            "email": "jefe@demo.tallerpro360.com",
            "rol": UserRole.JEFE_TALLER,
        },
    ]

    customers = [
        {
            "id": _uid("20000000-0000-0000-0000-000000000001"),
            "nombre": "Maria Gomez",
            "telefono": "+573001110001",
            "email": "maria.gomez@cliente-demo.com",
            "direccion": "Cra 12 #45-67, Bogota",
            "whatsapp": "+573001110001",
        },
        {
            "id": _uid("20000000-0000-0000-0000-000000000002"),
            "nombre": "Carlos Rojas",
            "telefono": "+573001110002",
            "email": "carlos.rojas@cliente-demo.com",
            "direccion": "Calle 80 #15-30, Medellin",
            "whatsapp": "+573001110002",
        },
        {
            "id": _uid("20000000-0000-0000-0000-000000000003"),
            "nombre": "Luisa Torres",
            "telefono": "+573001110003",
            "email": "luisa.torres@cliente-demo.com",
            "direccion": "Av 6N #24-40, Cali",
            "whatsapp": "+573001110003",
        },
    ]

    vehicles = [
        {
            "id": _uid("30000000-0000-0000-0000-000000000001"),
            "customer_id": customers[0]["id"],
            "marca": "Mazda",
            "modelo": "3 Touring",
            "placa": "TPA360",
            "vin": "JM1BPACM5M1300001",
            "kilometraje": 78450,
            "color": "Rojo",
        },
        {
            "id": _uid("30000000-0000-0000-0000-000000000002"),
            "customer_id": customers[1]["id"],
            "marca": "Renault",
            "modelo": "Logan Intens",
            "placa": "TPB360",
            "vin": "9FBKS1M31L0000002",
            "kilometraje": 112300,
            "color": "Gris",
        },
        {
            "id": _uid("30000000-0000-0000-0000-000000000003"),
            "customer_id": customers[2]["id"],
            "marca": "Toyota",
            "modelo": "Hilux SR",
            "placa": "TPC360",
            "vin": "8AJBA3CD9N0000003",
            "kilometraje": 45210,
            "color": "Blanco",
        },
    ]

    appointments = [
        {
            "id": _uid("40000000-0000-0000-0000-000000000001"),
            "customer_id": customers[0]["id"],
            "vehicle_id": vehicles[0]["id"],
            "fecha": anchor + timedelta(days=1),
            "bloque_horario": "09:00-10:00",
            "motivo": "Ruido en suspension delantera",
            "estado": AppointmentEstado.CONFIRMADA,
        },
        {
            "id": _uid("40000000-0000-0000-0000-000000000002"),
            "customer_id": customers[2]["id"],
            "vehicle_id": vehicles[2]["id"],
            "fecha": anchor - timedelta(days=2),
            "bloque_horario": "15:00-16:00",
            "motivo": "Mantenimiento 50.000 km",
            "estado": AppointmentEstado.COMPLETADA,
        },
    ]

    orders = [
        {
            "id": _uid("50000000-0000-0000-0000-000000000001"),
            "vehicle_id": vehicles[0]["id"],
            "advisor_id": users[1]["id"],
            "estado": OrderStatus.DIAGNOSTICO,
            "fecha_ingreso": anchor - timedelta(hours=3),
            "kilometraje_ingreso": 78450,
            "motivo_ingreso": "Golpeteo al frenar y vibracion en tren delantero",
        },
        {
            "id": _uid("50000000-0000-0000-0000-000000000002"),
            "vehicle_id": vehicles[1]["id"],
            "advisor_id": users[1]["id"],
            "estado": OrderStatus.QC,
            "fecha_ingreso": anchor - timedelta(days=1, hours=2),
            "kilometraje_ingreso": 112300,
            "motivo_ingreso": "Cambio de kit de frenos y alineacion",
        },
        {
            "id": _uid("50000000-0000-0000-0000-000000000003"),
            "vehicle_id": vehicles[2]["id"],
            "advisor_id": users[1]["id"],
            "estado": OrderStatus.CERRADA,
            "fecha_ingreso": anchor - timedelta(days=4),
            "fecha_salida": anchor - timedelta(days=2, hours=-2),
            "kilometraje_ingreso": 45210,
            "kilometraje_salida": 45255,
            "motivo_ingreso": "Mantenimiento preventivo y revision general",
        },
    ]

    reception_checklists = [
        {
            "id": _uid("60000000-0000-0000-0000-000000000001"),
            "order_id": orders[0]["id"],
            "nivel_aceite": "Medio",
            "nivel_refrigerante": "Normal",
            "nivel_frenos": "Bajo",
            "llanta_repuesto": True,
            "kit_carretera": True,
            "botiquin": True,
            "extintor": True,
            "documentos_recibidos": _json(["SOAT", "Tarjeta de propiedad"]),
            "firma_cliente_url": "https://files.tallerpro360.demo/signatures/maria.png",
        },
        {
            "id": _uid("60000000-0000-0000-0000-000000000002"),
            "order_id": orders[1]["id"],
            "nivel_aceite": "Normal",
            "nivel_refrigerante": "Normal",
            "nivel_frenos": "Normal",
            "llanta_repuesto": True,
            "kit_carretera": True,
            "botiquin": False,
            "extintor": True,
            "documentos_recibidos": _json(["SOAT"]),
            "firma_cliente_url": "https://files.tallerpro360.demo/signatures/carlos.png",
        },
        {
            "id": _uid("60000000-0000-0000-0000-000000000003"),
            "order_id": orders[2]["id"],
            "nivel_aceite": "Normal",
            "nivel_refrigerante": "Normal",
            "nivel_frenos": "Normal",
            "llanta_repuesto": True,
            "kit_carretera": True,
            "botiquin": True,
            "extintor": True,
            "documentos_recibidos": _json(["SOAT", "Tarjeta de propiedad", "Manual"]),
            "firma_cliente_url": "https://files.tallerpro360.demo/signatures/luisa.png",
        },
    ]

    findings = [
        {
            "id": _uid("70000000-0000-0000-0000-000000000001"),
            "order_id": orders[0]["id"],
            "technician_id": users[2]["id"],
            "motivo_ingreso": orders[0]["motivo_ingreso"],
            "descripcion": "Pastillas delanteras al limite y discos con desgaste irregular.",
            "tiempo_estimado": 2.5,
            "fotos": _json([
                "https://files.tallerpro360.demo/findings/freno-1.jpg",
                "https://files.tallerpro360.demo/findings/freno-2.jpg",
            ]),
            "es_hallazgo_adicional": False,
            "es_critico_seguridad": True,
        },
        {
            "id": _uid("70000000-0000-0000-0000-000000000002"),
            "order_id": orders[1]["id"],
            "technician_id": users[2]["id"],
            "motivo_ingreso": orders[1]["motivo_ingreso"],
            "descripcion": "Kit de frenos instalado; pendiente validacion final de ruta y ruidos.",
            "tiempo_estimado": 1.0,
            "fotos": _json(["https://files.tallerpro360.demo/findings/kit-frenos.jpg"]),
            "es_hallazgo_adicional": False,
            "es_critico_seguridad": False,
        },
        {
            "id": _uid("70000000-0000-0000-0000-000000000003"),
            "order_id": orders[2]["id"],
            "technician_id": users[2]["id"],
            "motivo_ingreso": orders[2]["motivo_ingreso"],
            "descripcion": "Cambio de aceite, filtros y limpieza general completados sin novedades.",
            "tiempo_estimado": 3.0,
            "fotos": _json(["https://files.tallerpro360.demo/findings/mantenimiento.jpg"]),
            "es_hallazgo_adicional": False,
            "es_critico_seguridad": False,
        },
    ]

    parts = [
        {
            "id": _uid("80000000-0000-0000-0000-000000000001"),
            "finding_id": findings[0]["id"],
            "nombre": "Juego de pastillas delanteras",
            "origen": PartOrigen.STOCK,
            "costo": 180000.0,
            "margen": 0.35,
            "precio_venta": 243000.0,
            "proveedor": "Frenos Express",
        },
        {
            "id": _uid("80000000-0000-0000-0000-000000000002"),
            "finding_id": findings[1]["id"],
            "nombre": "Kit de frenos traseros",
            "origen": PartOrigen.PEDIDO,
            "costo": 210000.0,
            "margen": 0.3,
            "precio_venta": 273000.0,
            "proveedor": "Autopartes del Norte",
        },
        {
            "id": _uid("80000000-0000-0000-0000-000000000003"),
            "finding_id": findings[2]["id"],
            "nombre": "Kit de mantenimiento 50K",
            "origen": PartOrigen.STOCK,
            "costo": 260000.0,
            "margen": 0.25,
            "precio_venta": 325000.0,
            "proveedor": "Centro Lubricantes",
        },
    ]

    quotations = [
        {
            "id": _uid("90000000-0000-0000-0000-000000000001"),
            "order_id": orders[0]["id"],
            "subtotal": 423000.0,
            "impuestos": 80370.0,
            "shop_supplies": 25000.0,
            "descuento": 0.0,
            "total": 528370.0,
            "estado": QuotationEstado.PENDIENTE,
            "fecha_envio": anchor,
        },
        {
            "id": _uid("90000000-0000-0000-0000-000000000002"),
            "order_id": orders[1]["id"],
            "subtotal": 523000.0,
            "impuestos": 99370.0,
            "shop_supplies": 18000.0,
            "descuento": 15000.0,
            "total": 625370.0,
            "estado": QuotationEstado.APROBADA,
            "fecha_envio": anchor - timedelta(days=1),
        },
        {
            "id": _uid("90000000-0000-0000-0000-000000000003"),
            "order_id": orders[2]["id"],
            "subtotal": 605000.0,
            "impuestos": 114950.0,
            "shop_supplies": 15000.0,
            "descuento": 20000.0,
            "total": 714950.0,
            "estado": QuotationEstado.APROBADA,
            "fecha_envio": anchor - timedelta(days=3),
        },
    ]

    quotation_items = [
        {
            "id": _uid("91000000-0000-0000-0000-000000000001"),
            "quotation_id": quotations[0]["id"],
            "finding_id": findings[0]["id"],
            "part_id": parts[0]["id"],
            "descripcion": "Cambio de pastillas delanteras y rectificado liviano",
            "mano_obra": 180000.0,
            "costo_repuesto": 243000.0,
            "precio_final": 423000.0,
        },
        {
            "id": _uid("91000000-0000-0000-0000-000000000002"),
            "quotation_id": quotations[1]["id"],
            "finding_id": findings[1]["id"],
            "part_id": parts[1]["id"],
            "descripcion": "Instalacion kit de frenos y alineacion",
            "mano_obra": 250000.0,
            "costo_repuesto": 273000.0,
            "precio_final": 523000.0,
        },
        {
            "id": _uid("91000000-0000-0000-0000-000000000003"),
            "quotation_id": quotations[2]["id"],
            "finding_id": findings[2]["id"],
            "part_id": parts[2]["id"],
            "descripcion": "Mantenimiento preventivo completo",
            "mano_obra": 280000.0,
            "costo_repuesto": 325000.0,
            "precio_final": 605000.0,
        },
    ]

    quality_checks = [
        {
            "id": _uid("92000000-0000-0000-0000-000000000001"),
            "order_id": orders[1]["id"],
            "inspector_id": users[3]["id"],
            "items_verificados": _qc_items(
                ["ruido en frenado", "alineacion", "prueba de ruta"]
            ),
            "kilometraje_salida": 112315,
            "nivel_aceite_salida": "Normal",
            "nivel_refrigerante_salida": "Normal",
            "nivel_frenos_salida": "Normal",
            "aprobado": False,
            "fecha": anchor - timedelta(hours=4),
        },
        {
            "id": _uid("92000000-0000-0000-0000-000000000002"),
            "order_id": orders[2]["id"],
            "inspector_id": users[3]["id"],
            "items_verificados": _qc_items(
                ["niveles", "luces", "prueba de ruta", "limpieza"]
            ),
            "kilometraje_salida": 45255,
            "nivel_aceite_salida": "Normal",
            "nivel_refrigerante_salida": "Normal",
            "nivel_frenos_salida": "Normal",
            "aprobado": True,
            "fecha": anchor - timedelta(days=2),
        },
    ]

    invoices = [
        {
            "id": _uid("93000000-0000-0000-0000-000000000001"),
            "order_id": orders[2]["id"],
            "monto_total": quotations[2]["total"],
            "metodo_pago": MetodoPago.TARJETA,
            "es_credito": False,
            "saldo_pendiente": 0.0,
            "fecha": anchor - timedelta(days=2),
        }
    ]

    nps_surveys = [
        {
            "id": _uid("94000000-0000-0000-0000-000000000001"),
            "order_id": orders[2]["id"],
            "atencion": 10,
            "instalaciones": 9,
            "tiempos": 9,
            "precios": 8,
            "recomendacion": 10,
            "comentarios": "Entrega clara, proceso rapido y excelente comunicacion.",
            "fecha": anchor - timedelta(days=1),
        }
    ]

    return {
        "users": users,
        "customers": customers,
        "vehicles": vehicles,
        "appointments": appointments,
        "orders": orders,
        "reception_checklists": reception_checklists,
        "findings": findings,
        "parts": parts,
        "quotations": quotations,
        "quotation_items": quotation_items,
        "quality_checks": quality_checks,
        "invoices": invoices,
        "nps_surveys": nps_surveys,
    }


def seed_database(session: Session, *, demo_password: str = DEFAULT_DEMO_PASSWORD) -> dict[str, Any]:
    context = _seed_context()
    bundle = _build_seed_bundle(context)
    stats: dict[str, dict[str, int]] = {
        "created": defaultdict(int),
        "updated": defaultdict(int),
    }

    for user_data in bundle["users"]:
        _ensure_user(
            session,
            entity_id=user_data["id"],
            nombre=user_data["nombre"],
            email=user_data["email"],
            rol=user_data["rol"],
            password=demo_password,
            stats=stats,
        )

    for customer_data in bundle["customers"]:
        _upsert_by_id(
            session,
            Customer,
            table_name="customers",
            entity_id=customer_data["id"],
            fields={k: v for k, v in customer_data.items() if k != "id"},
            stats=stats,
        )

    for vehicle_data in bundle["vehicles"]:
        _ensure_vehicle(
            session,
            entity_id=vehicle_data["id"],
            placa=vehicle_data["placa"],
            fields={k: v for k, v in vehicle_data.items() if k not in {"id", "placa"}},
            stats=stats,
        )

    table_mappings: list[tuple[type[Any], str, str]] = [
        (Appointment, "appointments", "appointments"),
        (ServiceOrder, "orders", "orders"),
        (ReceptionChecklist, "reception_checklists", "reception_checklists"),
        (DiagnosticFinding, "findings", "findings"),
        (Part, "parts", "parts"),
        (Quotation, "quotations", "quotations"),
        (QuotationItem, "quotation_items", "quotation_items"),
        (QualityCheck, "quality_checks", "quality_checks"),
        (Invoice, "invoices", "invoices"),
        (NPSSurvey, "nps_surveys", "nps_surveys"),
    ]

    for model, bundle_key, table_name in table_mappings:
        for row in bundle[bundle_key]:
            _upsert_by_id(
                session,
                model,
                table_name=table_name,
                entity_id=row["id"],
                fields={k: v for k, v in row.items() if k != "id"},
                stats=stats,
            )

    session.commit()

    credentials = [
        {
            "email": user_data["email"],
            "role": user_data["rol"].value,
            "password": demo_password,
        }
        for user_data in bundle["users"]
    ]
    order_refs = [
        {
            "id": str(order_data["id"]),
            "status": order_data["estado"].value,
            "motivo": order_data["motivo_ingreso"],
        }
        for order_data in bundle["orders"]
    ]

    return {
        "created": dict(stats["created"]),
        "updated": dict(stats["updated"]),
        "credentials": credentials,
        "references": {
            "orders": order_refs,
            "customers": [
                {"id": str(customer_data["id"]), "email": customer_data["email"]}
                for customer_data in bundle["customers"]
            ],
            "vehicles": [
                {"id": str(vehicle_data["id"]), "placa": vehicle_data["placa"]}
                for vehicle_data in bundle["vehicles"]
            ],
        },
    }


def _format_summary(summary: dict[str, Any]) -> str:
    lines = ["Seeder ejecutado correctamente.", "", "Credenciales demo:"]
    for credential in summary["credentials"]:
        lines.append(
            f"- {credential['role']}: {credential['email']} / {credential['password']}"
        )

    lines.append("")
    lines.append("Ordenes demo:")
    for order in summary["references"]["orders"]:
        lines.append(f"- {order['status']}: {order['id']} -> {order['motivo']}")

    lines.append("")
    lines.append(f"Creado: {json.dumps(summary['created'], ensure_ascii=True, sort_keys=True)}")
    lines.append(f"Actualizado: {json.dumps(summary['updated'], ensure_ascii=True, sort_keys=True)}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed demo data for TallerPro360 API")
    parser.add_argument(
        "--password",
        default=DEFAULT_DEMO_PASSWORD,
        help="Password to assign to all seeded demo users.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print the seeding summary as JSON.",
    )
    args = parser.parse_args()

    with Session(engine) as session:
        summary = seed_database(session, demo_password=args.password)

    if args.json:
        print(json.dumps(summary, ensure_ascii=True, indent=2, sort_keys=True))
        return

    print(_format_summary(summary))


if __name__ == "__main__":
    main()