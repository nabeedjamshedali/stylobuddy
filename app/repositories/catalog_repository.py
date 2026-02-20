from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.clothing_item import ClothingItem
from app.core.logger import get_logger

logger = get_logger("catalog_repository")


class CatalogRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_all(self, category: str | None = None) -> list[ClothingItem]:
        stmt = select(ClothingItem).order_by(ClothingItem.created_at.desc())
        if category:
            stmt = stmt.where(ClothingItem.ai_category == category)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, item_id: str) -> ClothingItem | None:
        stmt = select(ClothingItem).where(ClothingItem.id == item_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_ids(self, item_ids: list[str]) -> list[ClothingItem]:
        stmt = select(ClothingItem).where(ClothingItem.id.in_(item_ids))
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_unanalyzed(self) -> list[ClothingItem]:
        stmt = select(ClothingItem).where(ClothingItem.ai_description.is_(None))
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def count(self, category: str | None = None) -> int:
        stmt = select(func.count()).select_from(ClothingItem)
        if category:
            stmt = stmt.where(ClothingItem.ai_category == category)
        result = await self.db.execute(stmt)
        return result.scalar_one()

    async def create(self, item: ClothingItem) -> ClothingItem:
        self.db.add(item)
        await self.db.flush()
        return item

    async def update(self, item: ClothingItem) -> ClothingItem:
        await self.db.flush()
        return item
