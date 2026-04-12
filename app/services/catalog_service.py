from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.catalog_repository import CatalogRepository
from app.schemas.catalog_schema import (
    CatalogItemResponse,
    CatalogListResponse,
    CategoryTreeResponse,
    CategoryResponse,
)
from app.core.logger import get_logger

logger = get_logger("catalog_service")


class CatalogService:
    def __init__(self, db: AsyncSession):
        self.repo = CatalogRepository(db)

    async def list_items(
        self,
        category: str | None = None,
        category_slug: str | None = None,
        subcategory_slug: str | None = None,
    ) -> CatalogListResponse:
        items = await self.repo.get_all(
            category=category,
            category_slug=category_slug,
            subcategory_slug=subcategory_slug,
        )
        total = await self.repo.count(
            category=category,
            category_slug=category_slug,
            subcategory_slug=subcategory_slug,
        )
        return CatalogListResponse(
            items=[CatalogItemResponse.model_validate(item) for item in items],
            total=total,
        )

    async def get_item(self, item_id: str) -> CatalogItemResponse | None:
        item = await self.repo.get_by_id(item_id)
        if not item:
            return None
        return CatalogItemResponse.model_validate(item)

    async def get_category_tree(self) -> CategoryTreeResponse:
        categories = await self.repo.get_all_categories()
        return CategoryTreeResponse(
            categories=[CategoryResponse.model_validate(c) for c in categories]
        )
