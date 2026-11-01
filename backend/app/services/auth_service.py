from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import config
from app.core.logger import get_logger
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.models.user import User
from app.models.refresh_token import RefreshToken
from app.repositories.user_repository import UserRepository
from app.repositories.refresh_token_repository import RefreshTokenRepository
from app.schemas.auth_schema import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    UserResponse,
)

logger = get_logger("auth_service")


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
        self.token_repo = RefreshTokenRepository(db)

    async def register(self, request: RegisterRequest) -> TokenResponse:
        existing = await self.user_repo.get_by_email(request.email)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered",
            )

        user = User(
            email=request.email,
            hashed_password=hash_password(request.password),
            full_name=request.full_name,
        )
        user = await self.user_repo.create(user)
        logger.info("User registered: %s", user.email)

        return await self._generate_tokens(user.id)

    async def login(self, request: LoginRequest) -> TokenResponse:
        user = await self.user_repo.get_by_email(request.email)
        if not user or not verify_password(request.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )

        logger.info("User logged in: %s", user.email)
        return await self._generate_tokens(user.id)

    async def refresh(self, refresh_token_str: str) -> TokenResponse:
        # Decode and validate
        payload = decode_token(refresh_token_str)
        if not payload or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token",
            )

        # Find token in DB
        token_record = await self.token_repo.get_by_token(refresh_token_str)
        if not token_record:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token not found",
            )

        # Check if already revoked (possible token reuse attack)
        if token_record.is_revoked:
            # Token reuse detected — revoke all tokens for this user
            logger.warning(
                "Refresh token reuse detected for user %s. Revoking all tokens.",
                token_record.user_id,
            )
            await self.token_repo.revoke_all_for_user(token_record.user_id)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token reuse detected. All sessions revoked.",
            )

        # Rotate: generate new tokens and revoke old one
        new_tokens = await self._generate_tokens(token_record.user_id)
        await self.token_repo.revoke(token_record, replaced_by=new_tokens.refresh_token)

        logger.info("Token rotated for user %s", token_record.user_id)
        return new_tokens

    async def logout(self, user_id: str) -> dict:
        count = await self.token_repo.revoke_all_for_user(user_id)
        logger.info("Logged out user %s, revoked %d tokens", user_id, count)
        return {"message": "Logged out successfully", "revoked_tokens": count}

    async def _generate_tokens(self, user_id: str) -> TokenResponse:
        access_token = create_access_token(user_id)
        refresh_token_str, expires_at = create_refresh_token(user_id)

        # Store refresh token in DB
        token_record = RefreshToken(
            user_id=user_id,
            token=refresh_token_str,
            expires_at=expires_at,
        )
        await self.token_repo.create(token_record)

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token_str,
            expires_in=config.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )
