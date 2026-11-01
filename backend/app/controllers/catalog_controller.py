from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.catalog_service import CatalogService
from app.schemas.catalog_schema import (
    CatalogListResponse,
    CatalogItemResponse,
    CategoryTreeResponse,
)
from app.core.logger import get_logger

logger = get_logger("catalog_controller")


class CatalogController:

    @staticmethod
    async def list_items(
        db: AsyncSession,
        category: str | None = None,
        category_slug: str | None = None,
        subcategory_slug: str | None = None,
    ) -> CatalogListResponse:
        service = CatalogService(db)
        return await service.list_items(
            category=category,
            category_slug=category_slug,
            subcategory_slug=subcategory_slug,
        )

    @staticmethod
    async def get_item(db: AsyncSession, item_id: str) -> CatalogItemResponse:
        service = CatalogService(db)
        item = await service.get_item(item_id)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        return item

    @staticmethod
    async def get_categories(db: AsyncSession) -> CategoryTreeResponse:
        service = CatalogService(db)
        return await service.get_category_tree()
