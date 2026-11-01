from pydantic import BaseModel, Field


class RecommendationRequest(BaseModel):
    item_ids: list[str] = Field(
        ..., min_length=1, max_length=30,
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
    # ── Top-level summary — consumed directly by the frontend result panel ──
    aesthetic: str                    # e.g. "Clean Minimalist"
    description: str                  # 1–2 sentence style description
    palette: list[str]                # hex colour strings e.g. ["#F5F0E8", "#2F3331"]
    tags: list[str]                   # style tags e.g. ["Minimalist", "Tonal Dressing"]
    # ── Detailed outfit combinations (can be used for future multi-look UI) ──
    combinations: list[OutfitCombination]
    styling_tips: list[str]
    items_not_used: list[OutfitItem] = []
    is_saved: bool = False
    # 'lowers' | 'uppers' | null — tells the frontend if this was auto-suggest mode
    suggest_mode: str | None = None


class SavedLookResponse(BaseModel):
    recommendation_id: str
    aesthetic: str
    description: str
    palette: list[str]
    tags: list[str]
    combinations: list[OutfitCombination]
    styling_tips: list[str]
    is_saved: bool = True
    created_at: str


class RecommendationHistoryResponse(BaseModel):
    recommendations: list[RecommendationResponse]
    total: int
