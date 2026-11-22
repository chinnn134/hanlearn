from __future__ import annotations

import io
import time
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile
from PIL import Image, UnidentifiedImageError
from pydantic import BaseModel, Field, field_validator

from backend.app.core.auth import AuthenticatedUser, require_user
from backend.app.services.ocr import (
    OcrImage,
    OcrProvider,
    OcrResult,
    OcrServiceNotConfigured,
    OcrServiceTimeout,
    OcrServiceUnavailable,
)

router = APIRouter(prefix="/ocr", tags=["ocr"])
SUPPORTED_MEDIA_TYPES = {"image/jpeg": "JPEG", "image/png": "PNG"}


class OcrDetectionResponse(BaseModel):
    text: str
    confidence: float | None = Field(ge=0, le=1)
    box: list[list[int]]

    @field_validator("box")
    @classmethod
    def validate_box(cls, value: list[list[int]]) -> list[list[int]]:
        if len(value) != 4 or any(len(point) != 2 for point in value):
            raise ValueError("box must contain four [x, y] points")
        if any(coordinate < 0 for point in value for coordinate in point):
            raise ValueError("box coordinates must be non-negative")
        return value


class OcrResponse(BaseModel):
    text: str
    detections: list[OcrDetectionResponse]
    processing_time_ms: int = Field(ge=0)
    provider_version: str | None
    request_id: str


def provider(request: Request) -> OcrProvider:
    return request.app.state.ocr_provider


def _error(status_code: int, code: str, message: str) -> HTTPException:
    return HTTPException(status_code, detail={"code": code, "message": message})


def _validate_image(
    content: bytes, content_type: str | None, max_pixels: int
) -> OcrImage:
    expected_format = SUPPORTED_MEDIA_TYPES.get(content_type or "")
    if expected_format is None:
        raise _error(415, "UNSUPPORTED_IMAGE", "Chỉ hỗ trợ ảnh JPEG hoặc PNG.")
    try:
        with Image.open(io.BytesIO(content)) as image:
            width, height = image.size
            actual_format = image.format
            if width * height > max_pixels:
                raise _error(413, "IMAGE_TOO_LARGE", "Ảnh vượt quá giới hạn pixel.")
            image.verify()
    except HTTPException:
        raise
    except (UnidentifiedImageError, OSError, ValueError) as error:
        raise _error(422, "INVALID_IMAGE", "Ảnh không hợp lệ hoặc bị hỏng.") from error
    if actual_format != expected_format:
        raise _error(415, "UNSUPPORTED_IMAGE", "MIME không khớp nội dung ảnh.")
    return OcrImage(
        content=content,
        media_type=content_type or "",
        width=width,
        height=height,
    )


def _response(result: OcrResult, started: float) -> OcrResponse:
    return OcrResponse(
        text=result.text,
        detections=[
            OcrDetectionResponse(
                text=item.text,
                confidence=item.confidence,
                box=[list(point) for point in item.box],
            )
            for item in result.detections
        ],
        processing_time_ms=max(0, round((time.perf_counter() - started) * 1000)),
        provider_version=result.provider_version,
        request_id=uuid.uuid4().hex,
    )


@router.post("/recognize", response_model=OcrResponse)
async def recognize_image(
    request: Request,
    image: Annotated[UploadFile, File(description="JPEG or PNG, at most 8 MiB")],
    _user: AuthenticatedUser = Depends(require_user),
    ocr: OcrProvider = Depends(provider),
) -> OcrResponse:
    settings = request.app.state.settings
    content = await image.read(settings.max_image_bytes + 1)
    await image.close()
    if len(content) > settings.max_image_bytes:
        raise _error(413, "IMAGE_TOO_LARGE", "Ảnh vượt quá giới hạn dung lượng.")
    if not content:
        raise _error(422, "INVALID_IMAGE", "Ảnh không được rỗng.")
    validated = _validate_image(content, image.content_type, settings.max_image_pixels)
    started = time.perf_counter()
    try:
        result = await ocr.recognize(validated)
    except OcrServiceNotConfigured as error:
        raise _error(
            503, "SERVICE_NOT_CONFIGURED", "OCR chưa được cấu hình."
        ) from error
    except OcrServiceTimeout as error:
        raise _error(504, "SERVICE_TIMEOUT", "OCR quá thời gian xử lý.") from error
    except OcrServiceUnavailable as error:
        raise _error(
            503, "SERVICE_UNAVAILABLE", "OCR tạm thời không khả dụng."
        ) from error
    return _response(result, started)
