from sqlalchemy.ext.asyncio import AsyncSession

from app.services.auth_service import AuthService
from app.schemas.auth_schema import (
    RegisterRequest,
    LoginRequest,
    RefreshRequest,
    TokenResponse,
)
from app.core.logger import get_logger

logger = get_logger("auth_controller")


class AuthController:

    @staticmethod
    async def register(db: AsyncSession, request: RegisterRequest) -> TokenResponse:
        service = AuthService(db)
        return await service.register(request)

    @staticmethod
    async def login(db: AsyncSession, request: LoginRequest) -> TokenResponse:
        service = AuthService(db)
        return await service.login(request)

    @staticmethod
    async def refresh(db: AsyncSession, request: RefreshRequest) -> TokenResponse:
        service = AuthService(db)
        return await service.refresh(request.refresh_token)

    @staticmethod
    async def logout(db: AsyncSession, user_id: str) -> dict:
        service = AuthService(db)
        return await service.logout(user_id)
