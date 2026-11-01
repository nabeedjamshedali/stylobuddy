import json

from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.recommendation_repository import RecommendationRepository
from app.schemas.recommendation_schema import (
    SavedLookResponse,
    OutfitCombination,
    OutfitItem,
)
from app.core.logger import get_logger

logger = get_logger("saved_controller")


def _rec_to_saved_response(rec) -> SavedLookResponse:
    """Convert an OutfitRecommendation ORM object to SavedLookResponse."""
    payload = rec.recommendation_payload or {}

    combinations = []
    for combo in payload.get("combinations", []):
        outfit_items = [
            OutfitItem(
                item_id=oi.get("item_id", ""),
                item_name=oi.get("item_name", ""),
                image_url=oi.get("image_url", ""),
                category=oi.get("category", ""),
                role_in_outfit=oi.get("role_in_outfit", ""),
            )
            for oi in combo.get("items", [])
        ]
        combinations.append(
            OutfitCombination(
                outfit_name=combo.get("outfit_name", "Outfit"),
                items=outfit_items,
                style_description=combo.get("style_description", ""),
                occasion_fit=combo.get("occasion_fit", []),
                confidence_score=combo.get("confidence_score", 0.7),
            )
        )

    return SavedLookResponse(
        recommendation_id=rec.id,
        aesthetic=payload.get("aesthetic", "Curated Look"),
        description=payload.get("description", ""),
        palette=payload.get("palette", []),
        tags=payload.get("tags", []),
        combinations=combinations,
        styling_tips=payload.get("styling_tips", []),
        is_saved=rec.is_saved,
        created_at=str(rec.created_at),
    )


async def save_look(rec_id: str, user_id: str, db: AsyncSession) -> SavedLookResponse:
    repo = RecommendationRepository(db)
    rec = await repo.set_saved(rec_id, user_id, saved=True)
    if not rec:
        raise HTTPException(status_code=404, detail="Recommendation not found.")
    logger.info("User %s saved look %s", user_id, rec_id)
    return _rec_to_saved_response(rec)


async def unsave_look(rec_id: str, user_id: str, db: AsyncSession) -> dict:
    repo = RecommendationRepository(db)
    rec = await repo.set_saved(rec_id, user_id, saved=False)
    if not rec:
        raise HTTPException(status_code=404, detail="Recommendation not found.")
    logger.info("User %s unsaved look %s", user_id, rec_id)
    return {"message": "Look removed from saved."}


async def get_saved_looks(user_id: str, db: AsyncSession) -> list[SavedLookResponse]:
    repo = RecommendationRepository(db)
    recs = await repo.get_saved(user_id)
    return [_rec_to_saved_response(r) for r in recs]
