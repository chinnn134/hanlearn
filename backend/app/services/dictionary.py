from __future__ import annotations

import base64
import json
import sqlite3
import unicodedata
from dataclasses import dataclass
from pathlib import Path

from backend.scripts.build_dictionary import normalize_pinyin_search


@dataclass(frozen=True)
class DictionaryItem:
    vocab_id: str
    hanzi: str
    pinyin: str
    meaning_vi: str
    levels: dict[str, int]
    source_id: str


@dataclass(frozen=True)
class SearchPage:
    items: list[DictionaryItem]
    next_cursor: str | None


class InvalidCursorError(ValueError):
    pass


def _encode_cursor(query: str, offset: int) -> str:
    raw = json.dumps(
        {"q": query, "offset": offset},
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _decode_cursor(cursor: str, query: str) -> int:
    try:
        padding = "=" * (-len(cursor) % 4)
        payload = json.loads(base64.urlsafe_b64decode(cursor + padding))
        offset = payload["offset"]
        if (
            payload["q"] != query
            or not isinstance(offset, int)
            or not 0 <= offset <= 10_000
        ):
            raise InvalidCursorError
        return offset
    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        raise InvalidCursorError("Cursor không hợp lệ cho truy vấn này.") from error


class DictionaryRepository:
    def __init__(self, database_path: Path) -> None:
        self._database_path = database_path

    def search(
        self,
        query: str,
        *,
        limit: int,
        cursor: str | None = None,
    ) -> SearchPage:
        normalized_hanzi = unicodedata.normalize("NFC", query.strip())
        normalized_pinyin = normalize_pinyin_search(query)
        compact = normalized_pinyin.replace(" ", "")
        cursor_query = f"{normalized_hanzi}\u0000{normalized_pinyin}"
        offset = _decode_cursor(cursor, cursor_query) if cursor else 0
        with sqlite3.connect(
            f"file:{self._database_path.as_posix()}?mode=ro", uri=True
        ) as db:
            db.row_factory = sqlite3.Row
            rows = db.execute(
                """
                SELECT vocab_id, hanzi, pinyin, meaning_vi, levels_json, source_id,
                    CASE
                        WHEN hanzi = :hanzi THEN 0
                        WHEN substr(hanzi, 1, length(:hanzi)) = :hanzi THEN 1
                        WHEN pinyin_search = :pinyin
                            OR pinyin_search_compact = :compact THEN 2
                        ELSE 3
                    END AS rank
                FROM vocabulary
                WHERE hanzi = :hanzi
                    OR substr(hanzi, 1, length(:hanzi)) = :hanzi
                    OR pinyin_search = :pinyin
                    OR substr(pinyin_search, 1, length(:pinyin)) = :pinyin
                    OR pinyin_search_compact = :compact
                    OR substr(pinyin_search_compact, 1, length(:compact)) = :compact
                ORDER BY rank, hanzi, pinyin_numeric, vocab_id
                LIMIT :fetch_limit OFFSET :offset
                """,
                {
                    "hanzi": normalized_hanzi,
                    "pinyin": normalized_pinyin,
                    "compact": compact,
                    "fetch_limit": limit + 1,
                    "offset": offset,
                },
            ).fetchall()
        has_more = len(rows) > limit
        items = [
            DictionaryItem(
                vocab_id=row["vocab_id"],
                hanzi=row["hanzi"],
                pinyin=row["pinyin"],
                meaning_vi=row["meaning_vi"],
                levels=json.loads(row["levels_json"]),
                source_id=row["source_id"],
            )
            for row in rows[:limit]
        ]
        next_cursor = _encode_cursor(cursor_query, offset + limit) if has_more else None
        return SearchPage(items=items, next_cursor=next_cursor)
