from __future__ import annotations

import hashlib
import json
import sqlite3
from pathlib import Path

from backend.scripts.build_dictionary import (
    build,
    normalize_entry,
    normalize_pinyin_search,
    stable_vocab_id,
)

PINNED_COMMIT = "17873f10941c11ae4e410c91efdcb51c04b23c01"


def sample_entry(entry_id: str, hanzi: str, pinyin: str, pinyin_num: str) -> dict:
    return {
        "id": entry_id,
        "simp": hanzi,
        "trad": hanzi,
        "pinyin": pinyin,
        "pinyinNum": pinyin_num,
        "hanviet": [],
        "vi": {"senses": [" học tập ", "học tập"], "src": "cvdict"},
        "en": {"senses": ["to study"], "src": "cc-cedict"},
        "hsk": {"hsk2": 1, "hsk3": 1, "src": "hsk"},
    }


def test_titlecase_pinyin_is_rejected_as_probable_name() -> None:
    entry, reason = normalize_entry(sample_entry("冷|冷|Leng3", "冷", "Lěng", "Leng3"))
    assert entry is None
    assert reason == "proper_name_or_titlecase_pinyin"


def test_pinyin_and_entry_normalization_are_stable() -> None:
    assert normalize_pinyin_search("Xué xí") == "xue xi"
    assert normalize_pinyin_search("lü:4") == "lv"
    entry, reason = normalize_entry(
        sample_entry("学习|學習|xue2 xi2", "学习", "xué xí", "xue2 xi2")
    )
    assert reason is None
    assert entry is not None
    assert entry["meaningViSenses"] == ["học tập"]
    assert entry["vocabId"] == stable_vocab_id("学习|學習|xue2 xi2")


def test_builder_is_idempotent_and_writes_expected_rows(tmp_path: Path) -> None:
    source = tmp_path / "entries.jsonl"
    source.write_text(
        "\n".join(
            json.dumps(item, ensure_ascii=False)
            for item in [
                sample_entry("学习|學習|xue2 xi2", "学习", "xué xí", "xue2 xi2"),
                sample_entry("爱|愛|ai4", "爱", "ài", "ai4"),
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    meta = tmp_path / "meta.json"
    meta.write_text(
        json.dumps(
            {
                "commit": PINNED_COMMIT,
                "version": "test",
                "license": {"id": "CC-BY-SA-4.0", "attribution": "test"},
            }
        ),
        encoding="utf-8",
    )
    first = tmp_path / "first.sqlite"
    second = tmp_path / "second.sqlite"
    first_report = build(source, meta, first, tmp_path / "first.json", 2)
    second_report = build(source, meta, second, tmp_path / "second.json", 2)

    assert first_report["artifact"]["sha256"] == second_report["artifact"]["sha256"]
    assert (
        hashlib.sha256(first.read_bytes()).digest()
        == hashlib.sha256(second.read_bytes()).digest()
    )
    with sqlite3.connect(first) as connection:
        rows = connection.execute(
            "SELECT hanzi, examples_json, source_id FROM vocabulary ORDER BY hanzi"
        ).fetchall()
    assert rows == [
        ("学习", "[]", "opencidian-17873f1"),
        ("爱", "[]", "opencidian-17873f1"),
    ]
