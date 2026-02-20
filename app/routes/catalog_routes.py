from fastapi import APIRouter, Query

from app.controllers.catalog_controller import CatalogController
from app.schemas.catalog_schema import CatalogListResponse, CatalogItemResponse
from app.core.dependencies import DbSession

router = APIRouter(prefix="/api/catalog", tags=["Catalog"])


@router.get("/items", response_model=CatalogListResponse)
async def list_catalog_items(
    db: DbSession,
    category: str | None = Query(None, description="Filter by AI-detected category"),
):
    return await CatalogController.list_items(db, category=category)


@router.get("/items/{item_id}", response_model=CatalogItemResponse)
async def get_catalog_item(db: DbSession, item_id: str):
    return await CatalogController.get_item(db, item_id)
