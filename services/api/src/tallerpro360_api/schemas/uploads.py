from enum import Enum

from pydantic import BaseModel


class MediaCategory(str, Enum):
    DIAGNOSIS = "diagnosis"
    RECEPTION = "reception"
    SIGNATURE = "signature"


class MediaUploadResponse(BaseModel):
    url: str
    relative_url: str
    category: MediaCategory
    filename: str
    content_type: str
    size_bytes: int