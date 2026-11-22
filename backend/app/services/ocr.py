from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class OcrImage:
    content: bytes
    media_type: str
    width: int
    height: int


@dataclass(frozen=True)
class OcrDetection:
    text: str
    confidence: float | None
    box: tuple[tuple[int, int], tuple[int, int], tuple[int, int], tuple[int, int]]


@dataclass(frozen=True)
class OcrResult:
    text: str
    detections: tuple[OcrDetection, ...]
    provider_version: str | None


class OcrProviderError(Exception):
    pass


class OcrServiceNotConfigured(OcrProviderError):
    pass


class OcrServiceUnavailable(OcrProviderError):
    pass


class OcrServiceTimeout(OcrProviderError):
    pass


class OcrProvider(Protocol):
    async def recognize(self, image: OcrImage) -> OcrResult: ...


class UnconfiguredOcrProvider:
    async def recognize(self, image: OcrImage) -> OcrResult:
        del image
        raise OcrServiceNotConfigured("OCR provider is not configured")
