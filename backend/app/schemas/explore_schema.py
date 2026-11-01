from pydantic import BaseModel


class ExploreItem(BaseModel):
    id: int
    title: str
    category: str
    image_url: str
    aspect_ratio: str = "3/4"


class ExploreListResponse(BaseModel):
    items: list[ExploreItem]
    total: int
