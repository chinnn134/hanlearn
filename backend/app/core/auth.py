from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import firebase_admin
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth

bearer = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class AuthenticatedUser:
    uid: str


def _firebase_app(project_id: str) -> firebase_admin.App:
    name = f"hanlearn-{project_id}"
    try:
        return firebase_admin.get_app(name)
    except ValueError:
        return firebase_admin.initialize_app(
            options={"projectId": project_id},
            name=name,
        )


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
        decoded: dict[str, Any] = auth.verify_id_token(
            credentials.credentials,
            app=_firebase_app(project_id),
            check_revoked=False,
        )
    except Exception as error:
        raise _unauthorized(
            "Firebase ID token không hợp lệ hoặc đã hết hạn."
        ) from error
    uid = decoded.get("uid") or decoded.get("sub")
    if not isinstance(uid, str) or not uid:
        raise _unauthorized("Firebase ID token không có UID hợp lệ.")
    return AuthenticatedUser(uid=uid)
