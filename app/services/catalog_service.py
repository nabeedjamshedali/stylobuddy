from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.catalog_repository import CatalogRepository
from app.schemas.catalog_schema import CatalogItemResponse, CatalogListResponse
from app.core.logger import get_logger

logger = get_logger("catalog_service")


class CatalogService:
    def __init__(self, db: AsyncSession):
        self.repo = CatalogRepository(db)

    async def list_items(self, category: str | None = None) -> CatalogListResponse:
        items = await self.repo.get_all(category=category)
        total = await self.repo.count(category=category)
        return CatalogListResponse(
            items=[CatalogItemResponse.model_validate(item) for item in items],
            total=total,
        )

    async def get_item(self, item_id: str) -> CatalogItemResponse | None:
        item = await self.repo.get_by_id(item_id)
        if not item:
            return None
        return CatalogItemResponse.model_validate(item)
