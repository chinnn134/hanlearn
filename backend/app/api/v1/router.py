from fastapi import APIRouter

from backend.app.api.v1.ai import router as ai_router
from backend.app.api.v1.dictionary import router as dictionary_router
from backend.app.api.v1.ocr import router as ocr_router

# Feature routes are added with their issues. No public placeholder endpoint is
# exposed because the API contract requires Firebase auth for every v1 route.
api_router = APIRouter(prefix="/api/v1")
api_router.include_router(ai_router)
api_router.include_router(dictionary_router)
api_router.include_router(ocr_router)
