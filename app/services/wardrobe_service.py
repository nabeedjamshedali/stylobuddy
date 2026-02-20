from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.wardrobe_repository import WardrobeRepository
from app.repositories.catalog_repository import CatalogRepository
from app.schemas.wardrobe_schema import WardrobeItemResponse, WardrobeListResponse
from app.schemas.catalog_schema import CatalogItemResponse
from app.core.logger import get_logger

logger = get_logger("wardrobe_service")


class WardrobeService:
    def __init__(self, db: AsyncSession):
        self.wardrobe_repo = WardrobeRepository(db)
        self.catalog_repo = CatalogRepository(db)

    async def list_items(self, user_id: str) -> WardrobeListResponse:
        entries = await self.wardrobe_repo.get_all(user_id)
        total = await self.wardrobe_repo.count(user_id)
        items = [
            WardrobeItemResponse(
                id=entry.id,
                clothing_item_id=entry.clothing_item_id,
                is_favorite=entry.is_favorite,
                item=CatalogItemResponse.model_validate(entry.clothing_item),
            )
            for entry in entries
        ]
        return WardrobeListResponse(items=items, total=total)

    async def add_items(self, user_id: str, item_ids: list[str]) -> list[WardrobeItemResponse]:
        added = []
        for item_id in item_ids:
            catalog_item = await self.catalog_repo.get_by_id(item_id)
            if not catalog_item:
                logger.warning("Item %s not found in catalog, skipping", item_id)
                continue

            existing = await self.wardrobe_repo.get_by_item_id(user_id, item_id)
            if existing:
                logger.warning("Item %s already in wardrobe, skipping", item_id)
                continue

            entry = await self.wardrobe_repo.add(user_id, item_id)
            added.append(
                WardrobeItemResponse(
                    id=entry.id,
                    clothing_item_id=entry.clothing_item_id,
                    is_favorite=entry.is_favorite,
                    item=CatalogItemResponse.model_validate(catalog_item),
                )
            )
        return added

    async def remove_item(self, user_id: str, wardrobe_id: str) -> bool:
        return await self.wardrobe_repo.remove(user_id, wardrobe_id)
