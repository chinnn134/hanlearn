from fastapi import APIRouter

# Feature routes are added with their issues. No public placeholder endpoint is
# exposed because the API contract requires Firebase auth for every v1 route.
api_router = APIRouter(prefix="/api/v1")
