import pytest
from backend.app.core.config import Settings
from backend.app.main import create_app
from fastapi.testclient import TestClient
from pydantic import ValidationError


def test_health_is_public_and_has_contract_response() -> None:
    with TestClient(create_app(Settings(_env_file=None))) as client:
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_cors_allows_only_configured_web_origin() -> None:
    settings = Settings(_env_file=None, allowed_origins="http://localhost:3000")
    with TestClient(create_app(settings)) as client:
        allowed = client.options(
            "/health",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "GET",
            },
        )
        denied = client.options(
            "/health",
            headers={
                "Origin": "https://untrusted.example",
                "Access-Control-Request-Method": "GET",
            },
        )

    assert allowed.status_code == 200
    assert allowed.headers["access-control-allow-origin"] == "http://localhost:3000"
    assert denied.status_code == 400
    assert "access-control-allow-origin" not in denied.headers


@pytest.mark.parametrize(
    "overrides",
    [
        {"allowed_origins": "*"},
        {"app_env": "staging"},
        {"app_env": "staging", "allowed_origins": "http://staging.example"},
    ],
)
def test_unsafe_cors_configuration_is_rejected(overrides: dict[str, str]) -> None:
    with pytest.raises(ValidationError):
        Settings(_env_file=None, **overrides)


def test_staging_accepts_explicit_https_origin() -> None:
    settings = Settings(
        _env_file=None,
        app_env="staging",
        allowed_origins="https://staging.example",
    )
    assert settings.cors_origins == ["https://staging.example"]
