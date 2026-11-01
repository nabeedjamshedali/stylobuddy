from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.user_wardrobe import UserWardrobe
from app.core.logger import get_logger

logger = get_logger("wardrobe_repository")


class WardrobeRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_all(self, user_id: str) -> list[UserWardrobe]:
        stmt = (
            select(UserWardrobe)
            .options(selectinload(UserWardrobe.clothing_item))
            .where(UserWardrobe.user_id == user_id)
            .order_by(UserWardrobe.added_at.desc())
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_item_id(self, user_id: str, clothing_item_id: str) -> UserWardrobe | None:
        stmt = select(UserWardrobe).where(
            UserWardrobe.user_id == user_id,
            UserWardrobe.clothing_item_id == clothing_item_id,
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def add(self, user_id: str, clothing_item_id: str) -> UserWardrobe:
        entry = UserWardrobe(user_id=user_id, clothing_item_id=clothing_item_id)
        self.db.add(entry)
        await self.db.flush()
        return entry

    async def remove(self, user_id: str, wardrobe_id: str) -> bool:
        stmt = select(UserWardrobe).where(
            UserWardrobe.id == wardrobe_id,
            UserWardrobe.user_id == user_id,
        )
        result = await self.db.execute(stmt)
        entry = result.scalar_one_or_none()
        if entry:
            await self.db.delete(entry)
            await self.db.flush()
            return True
        return False

    async def count(self, user_id: str) -> int:
        stmt = select(func.count()).select_from(UserWardrobe).where(
            UserWardrobe.user_id == user_id
        )
        result = await self.db.execute(stmt)
        return result.scalar_one()
