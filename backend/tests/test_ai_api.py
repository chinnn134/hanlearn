from pathlib import Path

from backend.app.api.v1.ai import provider
from backend.app.core.auth import AuthenticatedUser, require_user
from backend.app.core.config import Settings
from backend.app.main import create_app
from backend.app.services.ai import (
    AiExample,
    AiExplainInput,
    AiExplainResult,
    AiServiceTimeout,
    AiServiceUnavailable,
)
from backend.app.services.dictionary import DictionaryRepository
from fastapi.testclient import TestClient

DATABASE = (
    Path(__file__).resolve().parents[1]
    / "data"
    / "dictionary"
    / "hanlearn_dictionary.sqlite3"
)
VOCAB_ID = DictionaryRepository(DATABASE).search("学习", limit=1).items[0].vocab_id


class FakeAiProvider:
    configured = True
    request: AiExplainInput | None = None

    async def explain(self, item: AiExplainInput) -> AiExplainResult:
        self.request = item
        return AiExplainResult(
            explanation_vi="Giải thích dựa trên nghĩa từ điển đã xác minh.",
            examples=(
                AiExample(
                    zh="我学习中文。",
                    pinyin="Wǒ xuéxí Zhōngwén.",
                    vi="Tôi học tiếng Trung.",
                ),
            ),
            radical_note_vi=None,
        )


class FailingAiProvider:
    configured = True

    def __init__(self, error: Exception) -> None:
        self.error = error

    async def explain(self, item: AiExplainInput) -> AiExplainResult:
        del item
        raise self.error


def app_with_auth(**settings: object):
    app = create_app(
        Settings(
            _env_file=None,
            firebase_project_id="demo-hanlearn",
            dictionary_db_path=DATABASE,
            **settings,
        )
    )
    app.dependency_overrides[require_user] = lambda: AuthenticatedUser(uid="test-uid")
    return app


def test_ai_requires_firebase_authentication() -> None:
    app = create_app(
        Settings(
            _env_file=None,
            firebase_project_id="demo-hanlearn",
            dictionary_db_path=DATABASE,
        )
    )
    with TestClient(app) as client:
        response = client.post("/api/v1/ai/explain", json={"vocabId": VOCAB_ID})
    assert response.status_code == 401


def test_ai_returns_not_configured_without_a_real_provider() -> None:
    with TestClient(app_with_auth()) as client:
        response = client.post("/api/v1/ai/explain", json={"vocabId": VOCAB_ID})
    assert response.status_code == 503
    assert response.json()["detail"]["code"] == "SERVICE_NOT_CONFIGURED"


def test_ai_contract_uses_verified_dictionary_data_with_mock_provider() -> None:
    app = app_with_auth()
    fake = FakeAiProvider()
    app.dependency_overrides[provider] = lambda: fake
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/ai/explain",
            json={"vocabId": VOCAB_ID, "contextZh": "  我学习中文。  "},
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload["vocabId"] == VOCAB_ID
    assert payload["generatedByAi"] is True
    assert payload["explanationVi"]
    assert payload["examples"] == [
        {
            "zh": "我学习中文。",
            "pinyin": "Wǒ xuéxí Zhōngwén.",
            "vi": "Tôi học tiếng Trung.",
        }
    ]
    assert payload["radicalNoteVi"] is None
    assert payload["request_id"]
    assert fake.request is not None
    assert fake.request.uid == "test-uid"
    assert fake.request.hanzi == "学习"
    assert fake.request.meaning_vi
    assert fake.request.context_zh == "我学习中文。"


def test_ai_validates_vocab_context_and_rate_limit() -> None:
    app = app_with_auth(ai_requests_per_minute=1)
    app.dependency_overrides[provider] = FakeAiProvider
    with TestClient(app) as client:
        missing = client.post("/api/v1/ai/explain", json={"vocabId": "missing-vocab"})
        long_context = client.post(
            "/api/v1/ai/explain",
            json={"vocabId": VOCAB_ID, "contextZh": "中" * 501},
        )
        first = client.post("/api/v1/ai/explain", json={"vocabId": VOCAB_ID})
        limited = client.post("/api/v1/ai/explain", json={"vocabId": VOCAB_ID})

    assert missing.status_code == 404
    assert missing.json()["detail"]["code"] == "NOT_FOUND"
    assert long_context.status_code == 422
    assert first.status_code == 200
    assert limited.status_code == 429
    assert limited.json()["detail"]["code"] == "RATE_LIMITED"


def test_ai_maps_provider_timeout_and_unavailable_errors() -> None:
    app = app_with_auth()
    app.dependency_overrides[provider] = lambda: FailingAiProvider(
        AiServiceTimeout("timeout")
    )
    with TestClient(app) as client:
        timeout = client.post("/api/v1/ai/explain", json={"vocabId": VOCAB_ID})

    app = app_with_auth()
    app.dependency_overrides[provider] = lambda: FailingAiProvider(
        AiServiceUnavailable("offline")
    )
    with TestClient(app) as client:
        unavailable = client.post("/api/v1/ai/explain", json={"vocabId": VOCAB_ID})

    assert timeout.status_code == 504
    assert timeout.json()["detail"]["code"] == "SERVICE_TIMEOUT"
    assert unavailable.status_code == 503
    assert unavailable.json()["detail"]["code"] == "SERVICE_UNAVAILABLE"
