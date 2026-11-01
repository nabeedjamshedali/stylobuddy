from pydantic import BaseModel


class ExploreItem(BaseModel):
    id: str
    title: str
    category: str
    gender: str               # "men" | "women"
    image_url: str
    source_url: str = ""
    dominant_color: str = ""  # hex colour from Pinterest pin metadata
    hashtags: list[str] = []
    saves: int = 0


class ExploreListResponse(BaseModel):
    items: list[ExploreItem]
    total: int
    cached: bool = True  # False when serving seed data before Apify responds
