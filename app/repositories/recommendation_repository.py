from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.outfit_recommendation import OutfitRecommendation
from app.core.logger import get_logger

logger = get_logger("recommendation_repository")


class RecommendationRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def save(self, recommendation: OutfitRecommendation) -> OutfitRecommendation:
        self.db.add(recommendation)
        await self.db.flush()
        return recommendation

    async def get_by_user(self, user_id: str, limit: int = 20) -> list[OutfitRecommendation]:
        stmt = (
            select(OutfitRecommendation)
            .where(OutfitRecommendation.user_id == user_id)
            .order_by(OutfitRecommendation.created_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, rec_id: str, user_id: str) -> OutfitRecommendation | None:
        stmt = select(OutfitRecommendation).where(
            OutfitRecommendation.id == rec_id,
            OutfitRecommendation.user_id == user_id,
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
