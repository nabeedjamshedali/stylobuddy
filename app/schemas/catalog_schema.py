from pydantic import BaseModel


class CatalogItemResponse(BaseModel):
    id: str
    name: str
    image_url: str
    ai_description: str | None = None
    ai_category: str | None = None

    model_config = {"from_attributes": True}


class CatalogListResponse(BaseModel):
    items: list[CatalogItemResponse]
    total: int
