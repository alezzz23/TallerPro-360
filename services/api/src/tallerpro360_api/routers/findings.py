from __future__ import annotations

import json
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from ..database import get_session
from ..dependencies import get_current_active_user, require_roles
from ..models.diagnostic_finding import DiagnosticFinding
from ..models.part import Part
from ..models.user import User, UserRole
from ..schemas.findings import (
    FindingPhotoAdd,
    FindingResponse,
    FindingUpdate,
    PartCreate,
    PartResponse,
    _SAFETY_WARNING,
)

router = APIRouter(prefix="/findings", tags=["findings"])

SessionDep = Annotated[Session, Depends(get_session)]
CurrentUser = Annotated[User, Depends(get_current_active_user)]
TecnicoOrAbove = Annotated[
    User,
    Depends(require_roles(UserRole.TECNICO, UserRole.JEFE_TALLER, UserRole.ADMIN)),
]
AsesorTecnicoOrAbove = Annotated[
    User,
    Depends(
        require_roles(
            UserRole.ASESOR, UserRole.TECNICO, UserRole.JEFE_TALLER, UserRole.ADMIN
        )
    ),
]


def _finding_response(finding: DiagnosticFinding, session: Session) -> FindingResponse:
    fotos: list[str] = json.loads(finding.fotos) if finding.fotos else []
    parts = session.exec(
        select(Part).where(Part.finding_id == finding.id)
    ).all()
    return FindingResponse(
        id=finding.id,
        order_id=finding.order_id,
        technician_id=finding.technician_id,
        motivo_ingreso=finding.motivo_ingreso,
        descripcion=finding.descripcion,
        tiempo_estimado=finding.tiempo_estimado,
        fotos=fotos,
        es_hallazgo_adicional=finding.es_hallazgo_adicional,
        es_critico_seguridad=finding.es_critico_seguridad,
        parts=[PartResponse.model_validate(p) for p in parts],
        safety_warning=_SAFETY_WARNING if finding.es_critico_seguridad else None,
    )


@router.get("/{finding_id}", response_model=FindingResponse)
def get_finding(
    finding_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> FindingResponse:
    finding = session.get(DiagnosticFinding, finding_id)
    if finding is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Finding not found")
    return _finding_response(finding, session)


@router.put("/{finding_id}", response_model=FindingResponse)
def update_finding(
    finding_id: uuid.UUID,
    payload: FindingUpdate,
    session: SessionDep,
    _current_user: TecnicoOrAbove,
) -> FindingResponse:
    finding = session.get(DiagnosticFinding, finding_id)
    if finding is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Finding not found")
    data = payload.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(finding, k, v)
    session.add(finding)
    session.commit()
    session.refresh(finding)
    return _finding_response(finding, session)


@router.post("/{finding_id}/photos", response_model=FindingResponse)
def add_photo(
    finding_id: uuid.UUID,
    payload: FindingPhotoAdd,
    session: SessionDep,
    _current_user: TecnicoOrAbove,
) -> FindingResponse:
    finding = session.get(DiagnosticFinding, finding_id)
    if finding is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Finding not found")
    fotos: list[str] = json.loads(finding.fotos) if finding.fotos else []
    if len(fotos) >= 10:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Maximum of 10 photos allowed per finding",
        )
    fotos.append(payload.foto_url)
    finding.fotos = json.dumps(fotos)
    session.add(finding)
    session.commit()
    session.refresh(finding)
    return _finding_response(finding, session)


@router.post("/{finding_id}/parts", response_model=PartResponse, status_code=status.HTTP_201_CREATED)
def add_part(
    finding_id: uuid.UUID,
    payload: PartCreate,
    session: SessionDep,
    _current_user: AsesorTecnicoOrAbove,
) -> PartResponse:
    finding = session.get(DiagnosticFinding, finding_id)
    if finding is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Finding not found")
    if payload.margen >= 1.0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="margen must be < 1.0",
        )
    precio_venta = payload.costo / (1 - payload.margen)
    part = Part(
        finding_id=finding_id,
        nombre=payload.nombre,
        origen=payload.origen,
        costo=payload.costo,
        margen=payload.margen,
        precio_venta=precio_venta,
        proveedor=payload.proveedor,
    )
    session.add(part)
    session.commit()
    session.refresh(part)
    return PartResponse.model_validate(part)


@router.get("/{finding_id}/parts", response_model=list[PartResponse])
def list_parts(
    finding_id: uuid.UUID,
    session: SessionDep,
    _current_user: CurrentUser,
) -> list[PartResponse]:
    finding = session.get(DiagnosticFinding, finding_id)
    if finding is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Finding not found")
    parts = session.exec(select(Part).where(Part.finding_id == finding_id)).all()
    return [PartResponse.model_validate(p) for p in parts]
