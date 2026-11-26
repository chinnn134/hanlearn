from __future__ import annotations

from dataclasses import dataclass

import requests
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2 import id_token

bearer = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class AuthenticatedUser:
    uid: str


def verify_firebase_id_token(
    token: str, project_id: str, clock_skew_seconds: int = 0
) -> dict[str, object]:
    """Verify signature and Firebase issuer/audience without requiring ADC."""
    return id_token.verify_firebase_token(
        token,
        GoogleAuthRequest(),
        audience=project_id,
        clock_skew_in_seconds=clock_skew_seconds,
    )


def verify_firebase_emulator_id_token(
    token: str, project_id: str, emulator_host: str
) -> dict[str, object]:
    """Ask the loopback Auth Emulator to validate its unsigned local token."""
    response = requests.post(
        f"http://{emulator_host}/identitytoolkit.googleapis.com/v1/accounts:lookup",
        params={"key": "demo-hanlearn"},
        json={"idToken": token},
        timeout=2,
    )
    response.raise_for_status()
    users = response.json().get("users")
    if not isinstance(users, list) or not users:
        raise ValueError("Auth Emulator did not return a user")
    uid = users[0].get("localId")
    if not isinstance(uid, str) or not uid:
        raise ValueError("Auth Emulator user has no localId")
    return {"uid": uid, "aud": project_id}


def _unauthorized(message: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail={"code": "UNAUTHORIZED", "message": message},
        headers={"WWW-Authenticate": "Bearer"},
    )


def require_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
) -> AuthenticatedUser:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise _unauthorized("Thiếu Firebase ID token.")
    project_id = request.app.state.settings.firebase_project_id
    if not project_id:
        raise _unauthorized("Backend chưa cấu hình Firebase project.")
    try:
        emulator_host = request.app.state.settings.firebase_auth_emulator_host
        if emulator_host:
            decoded = verify_firebase_emulator_id_token(
                credentials.credentials, project_id, emulator_host
            )
        else:
            decoded = verify_firebase_id_token(
                credentials.credentials,
                project_id,
                request.app.state.settings.firebase_token_clock_skew_seconds,
            )
    except Exception as error:
        raise _unauthorized(
            "Firebase ID token không hợp lệ hoặc đã hết hạn."
        ) from error
    uid = decoded.get("uid") or decoded.get("sub")
    if not isinstance(uid, str) or not uid:
        raise _unauthorized("Firebase ID token không có UID hợp lệ.")
    return AuthenticatedUser(uid=uid)
