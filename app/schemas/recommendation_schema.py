from pydantic import BaseModel, Field


class RecommendationRequest(BaseModel):
    item_ids: list[str] = Field(
        ..., min_length=2, max_length=30,
        description="IDs of wardrobe items to consider"
    )
    occasion: str | None = Field(None, description="e.g. office, casual, party")
    preferences: str | None = Field(None, description="Free-text style preferences")


class OutfitItem(BaseModel):
    item_id: str
    item_name: str
    image_url: str
    category: str
    role_in_outfit: str


class OutfitCombination(BaseModel):
    outfit_name: str
    items: list[OutfitItem]
    style_description: str
    occasion_fit: list[str]
    confidence_score: float = Field(ge=0.0, le=1.0)


class RecommendationResponse(BaseModel):
    recommendation_id: str
    combinations: list[OutfitCombination]
    styling_tips: list[str]
    items_not_used: list[OutfitItem] = []


class RecommendationHistoryResponse(BaseModel):
    recommendations: list[RecommendationResponse]
    total: int
