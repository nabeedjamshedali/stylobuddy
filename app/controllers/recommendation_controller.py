from sqlalchemy.ext.asyncio import AsyncSession

from app.services.recommendation_service import RecommendationService
from app.schemas.recommendation_schema import (
    RecommendationRequest,
    RecommendationResponse,
)
from app.models.user import User
from app.core.logger import get_logger

logger = get_logger("recommendation_controller")


class RecommendationController:

    @staticmethod
    async def get_outfit(
        db: AsyncSession, user: User, request: RecommendationRequest
    ) -> RecommendationResponse:
        service = RecommendationService(db)
        return await service.get_recommendation(user.id, request)

    @staticmethod
    async def get_history(db: AsyncSession, user: User, limit: int = 20) -> list[dict]:
        service = RecommendationService(db)
        return await service.get_history(user.id, limit=limit)
