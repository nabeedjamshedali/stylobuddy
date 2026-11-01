from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.catalog import CatalogCategory, CatalogSubcategory  # noqa: F401 — ensures models are registered
from app.models.clothing_item import ClothingItem
from app.core.logger import get_logger

logger = get_logger("catalog_repository")


class CatalogRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Clothing items ────────────────────────────────────────────────────────

    async def get_all(
        self,
        category: str | None = None,
        category_slug: str | None = None,
        subcategory_slug: str | None = None,
        catalog_only: bool = True,
    ) -> list[ClothingItem]:
        """
        Return clothing items, optionally filtered.

        Parameters
        ----------
        category        Filter by Vision-AI label (e.g. "topwear").
        category_slug   Filter by top-level category slug (e.g. "uppers").
        subcategory_slug Filter by subcategory slug (e.g. "t-shirts").
        catalog_only    When True (default), exclude user-uploaded items.
        """
        stmt = (
            select(ClothingItem)
            .order_by(ClothingItem.created_at.desc())
        )

        if catalog_only:
            stmt = stmt.where(ClothingItem.is_catalog_item.is_(True))

        if category:
            stmt = stmt.where(ClothingItem.ai_category == category)

        if category_slug or subcategory_slug:
            stmt = stmt.join(
                CatalogSubcategory,
                ClothingItem.subcategory_id == CatalogSubcategory.id,
                isouter=True,
            )
            if subcategory_slug:
                stmt = stmt.where(CatalogSubcategory.slug == subcategory_slug)
            if category_slug:
                stmt = stmt.join(
                    CatalogCategory,
                    CatalogSubcategory.category_id == CatalogCategory.id,
                    isouter=True,
                ).where(CatalogCategory.slug == category_slug)

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

    async def count(
        self,
        category: str | None = None,
        category_slug: str | None = None,
        subcategory_slug: str | None = None,
        catalog_only: bool = True,
    ) -> int:
        stmt = select(func.count()).select_from(ClothingItem)

        if catalog_only:
            stmt = stmt.where(ClothingItem.is_catalog_item.is_(True))
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

    # ── Category tree ─────────────────────────────────────────────────────────

    async def get_all_categories(self) -> list[CatalogCategory]:
        """Return all top-level categories, each with its subcategories pre-loaded."""
        stmt = select(CatalogCategory).order_by(CatalogCategory.sort_order)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_subcategory_by_slug(
        self, category_slug: str, subcategory_slug: str
    ) -> CatalogSubcategory | None:
        stmt = (
            select(CatalogSubcategory)
            .join(CatalogCategory, CatalogSubcategory.category_id == CatalogCategory.id)
            .where(
                CatalogCategory.slug == category_slug,
                CatalogSubcategory.slug == subcategory_slug,
            )
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
