import base64

from backend.app.api.v1.ocr import provider
from backend.app.core.auth import AuthenticatedUser, require_user
from backend.app.core.config import Settings
from backend.app.main import create_app
from backend.app.services.ocr import (
    OcrDetection,
    OcrImage,
    OcrResult,
    OcrServiceTimeout,
    OcrServiceUnavailable,
)
from fastapi.testclient import TestClient

PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
)


class FakeOcrProvider:
    image: OcrImage | None = None

    async def recognize(self, image: OcrImage) -> OcrResult:
        self.image = image
        return OcrResult(
            text="学习",
            detections=(
                OcrDetection(
                    text="学习",
                    confidence=0.96,
                    box=((0, 0), (1, 0), (1, 1), (0, 1)),
                ),
            ),
            provider_version="fake-contract-v1",
        )


class FailingOcrProvider:
    def __init__(self, error: Exception) -> None:
        self.error = error

    async def recognize(self, image: OcrImage) -> OcrResult:
        del image
        raise self.error


def app_with_auth(**settings: object):
    app = create_app(
        Settings(_env_file=None, firebase_project_id="demo-hanlearn", **settings)
    )
    app.dependency_overrides[require_user] = lambda: AuthenticatedUser(uid="test-uid")
    return app


def test_ocr_requires_firebase_authentication() -> None:
    app = create_app(Settings(_env_file=None, firebase_project_id="demo-hanlearn"))
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/ocr/recognize",
            files={"image": ("hanzi.png", PNG, "image/png")},
        )
    assert response.status_code == 401


def test_ocr_returns_not_configured_without_a_real_provider() -> None:
    with TestClient(app_with_auth()) as client:
        response = client.post(
            "/api/v1/ocr/recognize",
            files={"image": ("hanzi.png", PNG, "image/png")},
        )
    assert response.status_code == 503
    assert response.json()["detail"]["code"] == "SERVICE_NOT_CONFIGURED"


def test_ocr_contract_with_mock_provider() -> None:
    app = app_with_auth()
    fake = FakeOcrProvider()
    app.dependency_overrides[provider] = lambda: fake
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/ocr/recognize",
            files={"image": ("hanzi.png", PNG, "image/png")},
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload["text"] == "学习"
    assert payload["detections"][0] == {
        "text": "学习",
        "confidence": 0.96,
        "box": [[0, 0], [1, 0], [1, 1], [0, 1]],
    }
    assert payload["provider_version"] == "fake-contract-v1"
    assert payload["processing_time_ms"] >= 0
    assert payload["request_id"]
    assert fake.image is not None
    assert (fake.image.width, fake.image.height) == (1, 1)
    assert fake.image.media_type == "image/png"


def test_ocr_rejects_oversize_unsupported_and_corrupt_images() -> None:
    with TestClient(app_with_auth(max_image_bytes=8)) as client:
        oversize = client.post(
            "/api/v1/ocr/recognize",
            files={"image": ("hanzi.png", PNG, "image/png")},
        )
    with TestClient(app_with_auth()) as client:
        unsupported = client.post(
            "/api/v1/ocr/recognize",
            files={"image": ("hanzi.webp", PNG, "image/webp")},
        )
        corrupt = client.post(
            "/api/v1/ocr/recognize",
            files={"image": ("hanzi.png", b"not-an-image", "image/png")},
        )

    assert oversize.status_code == 413
    assert oversize.json()["detail"]["code"] == "IMAGE_TOO_LARGE"
    assert unsupported.status_code == 415
    assert unsupported.json()["detail"]["code"] == "UNSUPPORTED_IMAGE"
    assert corrupt.status_code == 422
    assert corrupt.json()["detail"]["code"] == "INVALID_IMAGE"


def test_ocr_maps_provider_timeout_and_unavailable_errors() -> None:
    app = app_with_auth()
    app.dependency_overrides[provider] = lambda: FailingOcrProvider(
        OcrServiceTimeout("timeout")
    )
    with TestClient(app) as client:
        timeout = client.post(
            "/api/v1/ocr/recognize",
            files={"image": ("hanzi.png", PNG, "image/png")},
        )
    app.dependency_overrides[provider] = lambda: FailingOcrProvider(
        OcrServiceUnavailable("offline")
    )
    with TestClient(app) as client:
        unavailable = client.post(
            "/api/v1/ocr/recognize",
            files={"image": ("hanzi.png", PNG, "image/png")},
        )

    assert timeout.status_code == 504
    assert timeout.json()["detail"]["code"] == "SERVICE_TIMEOUT"
    assert unavailable.status_code == 503
    assert unavailable.json()["detail"]["code"] == "SERVICE_UNAVAILABLE"
