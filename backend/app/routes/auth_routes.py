from fastapi import APIRouter

from app.controllers.auth_controller import AuthController
from app.schemas.auth_schema import (
    RegisterRequest,
    LoginRequest,
    RefreshRequest,
    TokenResponse,
)
from app.core.dependencies import DbSession, CurrentUser

router = APIRouter(prefix="/api/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(db: DbSession, request: RegisterRequest):
    return await AuthController.register(db, request)


@router.post("/login", response_model=TokenResponse)
async def login(db: DbSession, request: LoginRequest):
    return await AuthController.login(db, request)


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(db: DbSession, request: RefreshRequest):
    return await AuthController.refresh(db, request)


@router.post("/logout")
async def logout(db: DbSession, current_user: CurrentUser):
    return await AuthController.logout(db, current_user.id)
