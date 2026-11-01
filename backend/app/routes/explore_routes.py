from fastapi import APIRouter, Query

from app.schemas.explore_schema import ExploreItem, ExploreListResponse
from app.services.apify_service import get_trending_looks

router = APIRouter(prefix="/api/explore", tags=["Explore"])

# ── Seed data — shown while Apify cache warms up on first boot ───────────────
# Images are royalty-free fashion photos (Unsplash / public domain).

_SEED_ITEMS: list[dict] = [
    {"id": "s1", "title": "Clean Urban Look", "gender": "men",   "category": "Minimalist",  "image_url": "https://images.unsplash.com/photo-1617137968427-85924c800a22?w=600&q=80", "source_url": "", "dominant_color": "#e8e0d8", "hashtags": [], "saves": 0},
    {"id": "s2", "title": "Street Ready",     "gender": "men",   "category": "Streetwear",  "image_url": "https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80", "source_url": "", "dominant_color": "#2a2a2a", "hashtags": [], "saves": 0},
    {"id": "s3", "title": "Smart Casual Day", "gender": "men",   "category": "Smart Casual","image_url": "https://images.unsplash.com/photo-1593030761757-71fae45fa0e7?w=600&q=80", "source_url": "", "dominant_color": "#c9b89a", "hashtags": [], "saves": 0},
    {"id": "s4", "title": "Office Chic",      "gender": "men",   "category": "Formal",      "image_url": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80", "source_url": "", "dominant_color": "#1a2540", "hashtags": [], "saves": 0},
    {"id": "s5", "title": "Boho Summer",      "gender": "women", "category": "Casual",      "image_url": "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&q=80", "source_url": "", "dominant_color": "#d4a574", "hashtags": [], "saves": 0},
    {"id": "s6", "title": "Power Blazer",     "gender": "women", "category": "Formal",      "image_url": "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=600&q=80", "source_url": "", "dominant_color": "#3d3d3d", "hashtags": [], "saves": 0},
    {"id": "s7", "title": "Monochrome Mood",  "gender": "women", "category": "Minimalist",  "image_url": "https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=600&q=80", "source_url": "", "dominant_color": "#f0ede8", "hashtags": [], "saves": 0},
    {"id": "s8", "title": "Street Style",     "gender": "women", "category": "Streetwear",  "image_url": "https://images.unsplash.com/photo-1554412933-514a83d2f3c8?w=600&q=80", "source_url": "", "dominant_color": "#1c1c1e", "hashtags": [], "saves": 0},
]

ALL_CATEGORIES = ["All Styles", "Casual", "Formal", "Minimalist", "Smart Casual", "Streetwear"]


@router.get("/", response_model=ExploreListResponse)
async def list_explore_looks(
    gender: str | None = Query(None, description="'men' | 'women' | 'all'"),
    category: str | None = Query(None, description="Style category filter"),
) -> ExploreListResponse:
    """
    Return trending outfit looks for the Explore page.
    Data is fetched from Pinterest via Apify and cached for 24 hours.
    Seed data is returned on first call while the cache warms up.
    """
    gender_filter = gender or "all"
    items = await get_trending_looks(gender_filter)

    using_seed = False
    if not items:
        # Cache not warm yet — return seed data
        using_seed = True
        items = _SEED_ITEMS
        if gender_filter != "all":
            items = [i for i in items if i["gender"] == gender_filter]

    # Category filter
    if category and category != "All Styles":
        items = [i for i in items if i.get("category") == category]

    explore_items = [ExploreItem(**i) for i in items]
    return ExploreListResponse(items=explore_items, total=len(explore_items), cached=not using_seed)


@router.get("/categories", response_model=list[str])
async def list_categories() -> list[str]:
    return ALL_CATEGORIES
