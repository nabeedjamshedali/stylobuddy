from pydantic import BaseModel, Field


class WardrobeAddRequest(BaseModel):
    item_ids: list[str] = Field(..., min_length=1, description="Clothing item IDs to add")


class WardrobeItemResponse(BaseModel):
    id: str
    clothing_item_id: str
    is_favorite: bool
    item: "CatalogItemResponse"

    model_config = {"from_attributes": True}


class WardrobeListResponse(BaseModel):
    items: list[WardrobeItemResponse]
    total: int


# Avoid circular import
from app.schemas.catalog_schema import CatalogItemResponse  # noqa: E402

WardrobeItemResponse.model_rebuild()
