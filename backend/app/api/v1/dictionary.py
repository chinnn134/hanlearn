from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel, ConfigDict, Field

from backend.app.core.auth import AuthenticatedUser, require_user
from backend.app.services.dictionary import DictionaryRepository, InvalidCursorError

router = APIRouter(prefix="/dictionary", tags=["dictionary"])


class DictionaryItemResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    vocab_id: str = Field(alias="vocabId")
    hanzi: str
    pinyin: str
    meaning_vi: str = Field(alias="meaningVi")
    levels: dict[str, int]
    source_id: str = Field(alias="sourceId")


class DictionarySearchResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    items: list[DictionaryItemResponse]
    next_cursor: str | None = Field(alias="nextCursor")
    request_id: str


def repository(request: Request) -> DictionaryRepository:
    return DictionaryRepository(request.app.state.settings.dictionary_db_path)


@router.get("/search", response_model=DictionarySearchResponse)
def search_dictionary(
    q: Annotated[str, Query(min_length=1, max_length=64)],
    limit: Annotated[int, Query(ge=1, le=50)] = 20,
    cursor: str | None = None,
    _user: AuthenticatedUser = Depends(require_user),
    dictionary: DictionaryRepository = Depends(repository),
) -> DictionarySearchResponse:
    if not q.strip():
        raise HTTPException(
            422, detail={"code": "VALIDATION_ERROR", "message": "q không được rỗng."}
        )
    try:
        page = dictionary.search(q, limit=limit, cursor=cursor)
    except InvalidCursorError as error:
        raise HTTPException(
            400, detail={"code": "INVALID_CURSOR", "message": str(error)}
        ) from error
    return DictionarySearchResponse(
        items=[DictionaryItemResponse(**item.__dict__) for item in page.items],
        nextCursor=page.next_cursor,
        request_id=uuid.uuid4().hex,
    )
