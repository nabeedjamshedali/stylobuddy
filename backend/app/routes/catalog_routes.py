from fastapi import APIRouter, Query

from app.controllers.catalog_controller import CatalogController
from app.schemas.catalog_schema import (
    CatalogListResponse,
    CatalogItemResponse,
    CategoryTreeResponse,
)
from app.core.dependencies import DbSession

router = APIRouter(prefix="/api/catalog", tags=["Catalog"])


@router.get("/categories", response_model=CategoryTreeResponse)
async def get_category_tree(db: DbSession):
    """
    Return the full category → subcategory hierarchy.

    The frontend uses this to dynamically render tab labels and filter chips
    instead of hard-coding them.
    """
    return await CatalogController.get_categories(db)


@router.get("/items", response_model=CatalogListResponse)
async def list_catalog_items(
    db: DbSession,
    category: str | None = Query(None, description="Filter by AI-detected label (e.g. 'topwear')"),
    category_slug: str | None = Query(None, description="Filter by top-level category slug (e.g. 'uppers')"),
    subcategory_slug: str | None = Query(None, description="Filter by subcategory slug (e.g. 't-shirts')"),
):
    return await CatalogController.list_items(
        db,
        category=category,
        category_slug=category_slug,
        subcategory_slug=subcategory_slug,
    )


@router.get("/items/{item_id}", response_model=CatalogItemResponse)
async def get_catalog_item(db: DbSession, item_id: str):
    return await CatalogController.get_item(db, item_id)
