from pathlib import Path

from backend.app.core.auth import AuthenticatedUser, require_user
from backend.app.core.config import Settings
from backend.app.main import create_app
from fastapi.testclient import TestClient

DATABASE = (
    Path(__file__).resolve().parents[1]
    / "data"
    / "dictionary"
    / "hanlearn_dictionary.sqlite3"
)


def authenticated_client() -> TestClient:
    app = create_app(
        Settings(
            _env_file=None,
            firebase_project_id="demo-hanlearn",
            dictionary_db_path=DATABASE,
        )
    )
    app.dependency_overrides[require_user] = lambda: AuthenticatedUser(uid="test-uid")
    return TestClient(app)


def test_search_requires_firebase_token() -> None:
    app = create_app(
        Settings(
            _env_file=None,
            firebase_project_id="demo-hanlearn",
            dictionary_db_path=DATABASE,
        )
    )
    with TestClient(app) as client:
        response = client.get("/api/v1/dictionary/search", params={"q": "学习"})
    assert response.status_code == 401
    assert response.json()["detail"]["code"] == "UNAUTHORIZED"


def test_search_hanzi_and_pinyin_with_stable_pagination() -> None:
    with authenticated_client() as client:
        hanzi = client.get("/api/v1/dictionary/search", params={"q": "学习"})
        first = client.get(
            "/api/v1/dictionary/search",
            params={"q": "shi", "limit": 2},
        )
        second = client.get(
            "/api/v1/dictionary/search",
            params={"q": "shi", "limit": 2, "cursor": first.json()["nextCursor"]},
        )

    assert hanzi.status_code == 200
    assert hanzi.json()["items"][0]["hanzi"] == "学习"
    assert first.status_code == 200
    assert second.status_code == 200
    first_ids = {item["vocabId"] for item in first.json()["items"]}
    second_ids = {item["vocabId"] for item in second.json()["items"]}
    assert first_ids
    assert first_ids.isdisjoint(second_ids)


def test_search_handles_empty_results_validation_and_bad_cursor() -> None:
    with authenticated_client() as client:
        empty = client.get("/api/v1/dictionary/search", params={"q": "不存在词条xyz"})
        blank = client.get("/api/v1/dictionary/search", params={"q": "   "})
        bad_limit = client.get(
            "/api/v1/dictionary/search", params={"q": "xue", "limit": 51}
        )
        bad_cursor = client.get(
            "/api/v1/dictionary/search", params={"q": "xue", "cursor": "bad"}
        )

    assert empty.status_code == 200
    assert empty.json()["items"] == []
    assert blank.status_code == 422
    assert bad_limit.status_code == 422
    assert bad_cursor.status_code == 400
    assert bad_cursor.json()["detail"]["code"] == "INVALID_CURSOR"


def test_dictionary_detail_has_traceable_source_and_not_found() -> None:
    with authenticated_client() as client:
        search = client.get("/api/v1/dictionary/search", params={"q": "学习"})
        vocab_id = search.json()["items"][0]["vocabId"]
        detail = client.get(f"/api/v1/dictionary/{vocab_id}")
        missing = client.get("/api/v1/dictionary/ocd_missing")

    assert detail.status_code == 200
    payload = detail.json()
    assert payload["vocabId"] == vocab_id
    assert payload["hanzi"] == "学习"
    assert payload["meaningViSenses"]
    assert payload["examples"] == []
    assert payload["sourceId"] == "opencidian-17873f1"
    assert payload["license"] == "CC-BY-SA-4.0"
    assert "OpenCidian" in payload["attribution"]
    assert missing.status_code == 404
    assert missing.json()["detail"]["code"] == "NOT_FOUND"
