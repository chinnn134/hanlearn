from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
import unicodedata
from collections import Counter
from pathlib import Path
from typing import Any, Iterable

SOURCE_ID = "opencidian-17873f1"
HANZI_RE = re.compile(r"^[\u3400-\u4dbf\u4e00-\u9fff\U00020000-\U0002fa1f]{1,8}$")
SPACE_RE = re.compile(r"\s+")
TONE_DIGIT_RE = re.compile(r"[1-5]")


def normalize_space(value: str) -> str:
    return SPACE_RE.sub(" ", unicodedata.normalize("NFC", value).strip())


def normalize_pinyin_search(value: str) -> str:
    value = (
        normalize_space(value)
        .lower()
        .replace("u:", "v")
        .replace("ü:", "v")
        .replace("ü", "v")
    )
    value = TONE_DIGIT_RE.sub("", value)
    value = "".join(
        char
        for char in unicodedata.normalize("NFD", value)
        if unicodedata.category(char) != "Mn"
    )
    return normalize_space(value)


def stable_vocab_id(source_entry_id: str) -> str:
    digest = hashlib.sha256(source_entry_id.encode("utf-8")).hexdigest()
    return f"ocd_{digest}"


def _deduplicate_strings(values: Iterable[Any]) -> list[str]:
    result: list[str] = []
    seen: set[str] = set()
    for raw in values:
        if not isinstance(raw, str):
            continue
        value = normalize_space(raw)
        if value and value not in seen:
            seen.add(value)
            result.append(value)
    return result


def normalize_entry(raw: dict[str, Any]) -> tuple[dict[str, Any] | None, str | None]:
    required = ("id", "simp", "trad", "pinyin", "pinyinNum")
    if any(not isinstance(raw.get(field), str) for field in required):
        return None, "missing_required_string"

    source_entry_id = normalize_space(raw["id"])
    hanzi = normalize_space(raw["simp"])
    traditional = normalize_space(raw["trad"])
    pinyin = normalize_space(raw["pinyin"])
    pinyin_numeric = normalize_space(raw["pinyinNum"]).lower()
    if not source_entry_id or not HANZI_RE.fullmatch(hanzi):
        return None, "invalid_simplified_hanzi"
    if not traditional or not pinyin or not pinyin_numeric:
        return None, "empty_required_value"
    if pinyin[0].isupper():
        return None, "proper_name_or_titlecase_pinyin"

    vi = raw.get("vi")
    if not isinstance(vi, dict):
        return None, "missing_vietnamese"
    senses = _deduplicate_strings(vi.get("senses", []))
    if not senses:
        return None, "empty_vietnamese_senses"
    if any(len(sense) > 500 for sense in senses):
        return None, "vietnamese_sense_too_long"

    hsk = raw.get("hsk") if isinstance(raw.get("hsk"), dict) else {}
    levels: dict[str, int] = {}
    if isinstance(hsk.get("hsk2"), int) and 1 <= hsk["hsk2"] <= 6:
        levels["hsk2"] = hsk["hsk2"]
    if isinstance(hsk.get("hsk3"), int) and 1 <= hsk["hsk3"] <= 7:
        levels["hsk3"] = hsk["hsk3"]
    if not levels:
        return None, "missing_verified_hsk_level"

    han_viet: list[dict[str, Any]] = []
    for item in raw.get("hanviet", []):
        if not isinstance(item, dict) or not isinstance(item.get("char"), str):
            continue
        readings = _deduplicate_strings(item.get("readings", []))
        if readings:
            han_viet.append(
                {
                    "char": normalize_space(item["char"]),
                    "readings": readings,
                    "src": item.get("src"),
                }
            )

    pinyin_search = normalize_pinyin_search(pinyin_numeric)
    if not pinyin_search:
        return None, "invalid_pinyin_search_key"

    return (
        {
            "vocabId": stable_vocab_id(source_entry_id),
            "sourceEntryId": source_entry_id,
            "hanzi": hanzi,
            "traditional": traditional,
            "pinyin": pinyin,
            "pinyinNumeric": pinyin_numeric,
            "pinyinSearch": pinyin_search,
            "pinyinSearchCompact": pinyin_search.replace(" ", ""),
            "meaningVi": "; ".join(senses),
            "meaningViSenses": senses,
            "hanViet": han_viet,
            "levels": levels,
            "examples": [],
            "sourceId": SOURCE_ID,
            "sourceRefs": {
                "entry": "cc-cedict",
                "meaningVi": vi.get("src", "cvdict"),
                "levels": hsk.get("src", "hsk"),
            },
        },
        None,
    )


def selection_key(entry: dict[str, Any]) -> tuple[Any, ...]:
    levels = entry["levels"]
    variant_penalty = 1 if entry["meaningVi"].lower().startswith("biến thể") else 0
    return (
        0 if levels.get("hsk3") == 1 and levels.get("hsk2") == 1 else 1,
        levels.get("hsk3", 99),
        levels.get("hsk2", 99),
        variant_penalty,
        len(entry["hanzi"]),
        entry["hanzi"],
        entry["pinyinNumeric"],
        entry["vocabId"],
    )


def load_and_select(
    path: Path, limit: int
) -> tuple[list[dict[str, Any]], Counter[str]]:
    accepted: list[dict[str, Any]] = []
    rejected: Counter[str] = Counter()
    seen_ids: dict[str, str] = {}
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, start=1):
            try:
                raw = json.loads(line)
            except json.JSONDecodeError:
                rejected["invalid_json"] += 1
                continue
            if not isinstance(raw, dict):
                rejected["non_object"] += 1
                continue
            entry, reason = normalize_entry(raw)
            if entry is None:
                rejected[reason or "unknown"] += 1
                continue
            previous = seen_ids.get(entry["vocabId"])
            if previous is not None and previous != entry["sourceEntryId"]:
                raise ValueError(f"vocabId collision at line {line_number}")
            seen_ids[entry["vocabId"]] = entry["sourceEntryId"]
            accepted.append(entry)

    accepted.sort(key=selection_key)
    unique: list[dict[str, Any]] = []
    seen_headwords: set[tuple[str, str]] = set()
    for entry in accepted:
        headword_key = (entry["hanzi"], entry["pinyinNumeric"])
        if headword_key in seen_headwords:
            rejected["duplicate_hanzi_pinyin"] += 1
            continue
        seen_headwords.add(headword_key)
        unique.append(entry)
    if len(unique) < limit:
        raise ValueError(
            f"Only {len(unique)} unique entries, expected at least {limit}"
        )
    rejected["not_selected_by_limit"] += len(unique) - limit
    return unique[:limit], rejected


def write_database(
    path: Path, entries: list[dict[str, Any]], meta: dict[str, Any]
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()
    connection = sqlite3.connect(path)
    try:
        connection.executescript(
            """
            PRAGMA journal_mode = DELETE;
            PRAGMA synchronous = FULL;
            PRAGMA page_size = 4096;
            CREATE TABLE vocabulary (
                vocab_id TEXT PRIMARY KEY,
                source_entry_id TEXT NOT NULL UNIQUE,
                hanzi TEXT NOT NULL,
                traditional TEXT NOT NULL,
                pinyin TEXT NOT NULL,
                pinyin_numeric TEXT NOT NULL,
                pinyin_search TEXT NOT NULL,
                pinyin_search_compact TEXT NOT NULL,
                meaning_vi TEXT NOT NULL,
                meaning_vi_senses_json TEXT NOT NULL,
                han_viet_json TEXT NOT NULL,
                levels_json TEXT NOT NULL,
                examples_json TEXT NOT NULL,
                source_id TEXT NOT NULL,
                source_refs_json TEXT NOT NULL
            );
            CREATE INDEX vocabulary_hanzi_idx ON vocabulary(hanzi);
            CREATE INDEX vocabulary_pinyin_idx ON vocabulary(pinyin_search);
            CREATE INDEX vocabulary_pinyin_compact_idx
                ON vocabulary(pinyin_search_compact);
            CREATE TABLE corpus_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL);
            """
        )
        rows = [
            (
                item["vocabId"],
                item["sourceEntryId"],
                item["hanzi"],
                item["traditional"],
                item["pinyin"],
                item["pinyinNumeric"],
                item["pinyinSearch"],
                item["pinyinSearchCompact"],
                item["meaningVi"],
                json.dumps(
                    item["meaningViSenses"], ensure_ascii=False, separators=(",", ":")
                ),
                json.dumps(item["hanViet"], ensure_ascii=False, separators=(",", ":")),
                json.dumps(
                    item["levels"],
                    ensure_ascii=False,
                    sort_keys=True,
                    separators=(",", ":"),
                ),
                "[]",
                item["sourceId"],
                json.dumps(
                    item["sourceRefs"],
                    ensure_ascii=False,
                    sort_keys=True,
                    separators=(",", ":"),
                ),
            )
            for item in entries
        ]
        connection.executemany(
            "INSERT INTO vocabulary VALUES "
            "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            rows,
        )
        metadata = {
            "source_id": SOURCE_ID,
            "source_commit": str(meta.get("commit", "")),
            "source_version": str(meta.get("version", "")),
            "data_license": str(meta.get("license", {}).get("id", "")),
            "attribution": str(meta.get("license", {}).get("attribution", "")),
            "entry_count": str(len(entries)),
        }
        connection.executemany(
            "INSERT INTO corpus_metadata(key, value) VALUES (?, ?)",
            sorted(metadata.items()),
        )
        connection.commit()
        connection.execute("VACUUM")
    finally:
        connection.close()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build(
    source: Path, meta_path: Path, output: Path, report_path: Path, limit: int
) -> dict[str, Any]:
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    if meta.get("commit") != "17873f10941c11ae4e410c91efdcb51c04b23c01":
        raise ValueError("OpenCidian commit does not match the pinned manifest")
    if meta.get("license", {}).get("id") != "CC-BY-SA-4.0":
        raise ValueError("Unexpected OpenCidian data license")
    entries, rejected = load_and_select(source, limit)
    write_database(output, entries, meta)
    report = {
        "schemaVersion": 1,
        "sourceId": SOURCE_ID,
        "sourceCommit": meta["commit"],
        "sourceVersion": meta.get("version"),
        "selection": (
            "verified HSK entries with non-empty Vietnamese senses; "
            "deterministic priority by HSK level"
        ),
        "accepted": len(entries),
        "rejected": dict(sorted(rejected.items())),
        "levels": {
            key: dict(sorted(value.items()))
            for key, value in sorted(
                {
                    "hsk2": Counter(
                        str(item["levels"].get("hsk2", "none")) for item in entries
                    ),
                    "hsk3": Counter(
                        str(item["levels"].get("hsk3", "none")) for item in entries
                    ),
                }.items()
            )
        },
        "artifact": {
            "path": output.as_posix(),
            "sha256": sha256_file(output),
            "bytes": output.stat().st_size,
        },
        "quality": {
            "examplesPolicy": "empty_without_verified_source",
            "canonicalFieldsGeneratedByAi": False,
            "independentHumanLinguisticReview": False,
            "note": (
                "Source and structural validation completed; independent linguistic "
                "review remains recommended before public release."
            ),
        },
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build the pinned HanLearn dictionary SQLite corpus"
    )
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--meta", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--limit", type=int, default=500)
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    result = build(args.source, args.meta, args.output, args.report, args.limit)
    print(json.dumps(result, ensure_ascii=False, indent=2))
