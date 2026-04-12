from __future__ import annotations

import uuid
from pathlib import Path
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile, status

from ..config import settings
from ..dependencies import get_current_active_user
from ..models.user import User
from ..schemas.uploads import MediaCategory, MediaUploadResponse

router = APIRouter(prefix="/uploads", tags=["uploads"])

CurrentUser = Annotated[User, Depends(get_current_active_user)]

_CHUNK_SIZE = 1024 * 1024
_ALLOWED_EXTENSIONS = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
    ".heic": "image/heic",
    ".heif": "image/heif",
}
_CONTENT_TYPE_TO_EXTENSION = {
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/heic": ".heic",
    "image/heif": ".heif",
}


def _resolve_upload_metadata(file: UploadFile) -> tuple[str, str]:
    suffix = Path(file.filename or "").suffix.lower()
    content_type = (file.content_type or "").lower()

    if content_type in _CONTENT_TYPE_TO_EXTENSION:
        return _CONTENT_TYPE_TO_EXTENSION[content_type], _ALLOWED_EXTENSIONS[
            _CONTENT_TYPE_TO_EXTENSION[content_type]
        ]

    if suffix in _ALLOWED_EXTENSIONS:
        normalized_suffix = ".jpg" if suffix == ".jpeg" else suffix
        return normalized_suffix, _ALLOWED_EXTENSIONS[suffix]

    raise HTTPException(
        status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
        detail="Only JPG, PNG, WEBP, HEIC, and HEIF image uploads are supported",
    )


async def _persist_upload(file: UploadFile, category: MediaCategory) -> tuple[Path, str, int]:
    extension, content_type = _resolve_upload_metadata(file)
    target_dir = settings.media_dir / category.value
    target_dir.mkdir(parents=True, exist_ok=True)

    stored_filename = f"{uuid.uuid4().hex}{extension}"
    target_path = target_dir / stored_filename
    total_size = 0

    try:
        with target_path.open("wb") as buffer:
            while chunk := await file.read(_CHUNK_SIZE):
                total_size += len(chunk)
                if total_size > settings.max_upload_size_bytes:
                    raise HTTPException(
                        status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                        detail=(
                            "File too large. "
                            f"Maximum size is {settings.max_upload_size_bytes} bytes"
                        ),
                    )
                buffer.write(chunk)
    except HTTPException:
        target_path.unlink(missing_ok=True)
        raise
    except OSError as exc:
        target_path.unlink(missing_ok=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not persist uploaded media",
        ) from exc
    finally:
        await file.close()

    return target_path, content_type, total_size


@router.post("/", response_model=MediaUploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_media(
    request: Request,
    file: Annotated[UploadFile, File(...)],
    _current_user: CurrentUser,
    category: Annotated[MediaCategory, Form()] = MediaCategory.RECEPTION,
) -> MediaUploadResponse:
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file must include a filename",
        )

    stored_path, content_type, size_bytes = await _persist_upload(file, category)
    relative_path = stored_path.relative_to(settings.media_dir).as_posix()
    relative_url = f"{settings.media_url_path}/{relative_path}"
    url = str(request.url_for("media", path=relative_path))

    return MediaUploadResponse(
        url=url,
        relative_url=relative_url,
        category=category,
        filename=stored_path.name,
        content_type=content_type,
        size_bytes=size_bytes,
    )