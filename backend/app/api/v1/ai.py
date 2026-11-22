from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, ConfigDict, Field, field_validator

from backend.app.core.auth import AuthenticatedUser, require_user
from backend.app.services.ai import (
    AiExplainInput,
    AiExplainProvider,
    AiExplainResult,
    AiQuotaExceeded,
    AiRateLimited,
    AiRateLimiter,
    AiServiceNotConfigured,
    AiServiceTimeout,
    AiServiceUnavailable,
)
from backend.app.services.dictionary import DictionaryRepository

router = APIRouter(prefix="/ai", tags=["ai"])


class AiExplainRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    vocab_id: str = Field(alias="vocabId", min_length=1, max_length=128)
    context_zh: str | None = Field(default=None, alias="contextZh", max_length=500)

    @field_validator("vocab_id")
    @classmethod
    def trim_vocab_id(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("vocabId must not be blank")
        return value.strip()

    @field_validator("context_zh")
    @classmethod
    def trim_context(cls, value: str | None) -> str | None:
        if value is None:
            return None
        trimmed = value.strip()
        return trimmed or None


class AiExampleResponse(BaseModel):
    zh: str = Field(min_length=1, max_length=300)
    pinyin: str = Field(min_length=1, max_length=500)
    vi: str = Field(min_length=1, max_length=500)


class AiExplainResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    vocab_id: str = Field(alias="vocabId")
    explanation_vi: str = Field(alias="explanationVi", min_length=1, max_length=1000)
    examples: list[AiExampleResponse] = Field(max_length=3)
    radical_note_vi: str | None = Field(
        default=None, alias="radicalNoteVi", max_length=500
    )
    generated_by_ai: bool = Field(alias="generatedByAi")
    request_id: str


def provider(request: Request) -> AiExplainProvider:
    return request.app.state.ai_provider


def rate_limiter(request: Request) -> AiRateLimiter:
    return request.app.state.ai_rate_limiter


def dictionary(request: Request) -> DictionaryRepository:
    return DictionaryRepository(request.app.state.settings.dictionary_db_path)


def _error(status_code: int, code: str, message: str) -> HTTPException:
    return HTTPException(status_code, detail={"code": code, "message": message})


def _response(vocab_id: str, result: AiExplainResult) -> AiExplainResponse:
    return AiExplainResponse(
        vocabId=vocab_id,
        explanationVi=result.explanation_vi,
        examples=[AiExampleResponse(**example.__dict__) for example in result.examples],
        radicalNoteVi=result.radical_note_vi,
        generatedByAi=True,
        request_id=uuid.uuid4().hex,
    )


@router.post("/explain", response_model=AiExplainResponse)
async def explain_vocabulary(
    payload: AiExplainRequest,
    user: Annotated[AuthenticatedUser, Depends(require_user)],
    ai: Annotated[AiExplainProvider, Depends(provider)],
    limiter: Annotated[AiRateLimiter, Depends(rate_limiter)],
    corpus: Annotated[DictionaryRepository, Depends(dictionary)],
) -> AiExplainResponse:
    item = corpus.get(payload.vocab_id)
    if item is None:
        raise _error(404, "NOT_FOUND", "Không tìm thấy mục từ đã xác minh.")
    if not ai.configured:
        raise _error(503, "SERVICE_NOT_CONFIGURED", "AI chưa được cấu hình.")
    try:
        limiter.consume(user.uid)
    except AiRateLimited as error:
        raise _error(429, "RATE_LIMITED", "Đã vượt giới hạn AI mỗi phút.") from error
    except AiQuotaExceeded as error:
        raise _error(429, "QUOTA_EXCEEDED", "Đã hết quota AI trong ngày.") from error
    request = AiExplainInput(
        uid=user.uid,
        vocab_id=item.vocab_id,
        hanzi=item.hanzi,
        pinyin=item.pinyin,
        meaning_vi=item.meaning_vi,
        context_zh=payload.context_zh,
    )
    try:
        result = await ai.explain(request)
    except AiServiceNotConfigured as error:
        raise _error(503, "SERVICE_NOT_CONFIGURED", "AI chưa được cấu hình.") from error
    except AiServiceTimeout as error:
        raise _error(504, "SERVICE_TIMEOUT", "AI quá thời gian xử lý.") from error
    except AiServiceUnavailable as error:
        raise _error(
            503, "SERVICE_UNAVAILABLE", "AI tạm thời không khả dụng."
        ) from error
    return _response(item.vocab_id, result)
