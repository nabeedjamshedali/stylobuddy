from fastapi import APIRouter, Query

from app.controllers.recommendation_controller import RecommendationController
from app.schemas.recommendation_schema import (
    RecommendationRequest,
    RecommendationResponse,
)
from app.core.dependencies import DbSession, CurrentUser

router = APIRouter(prefix="/api/recommendations", tags=["Recommendations"])


@router.post("/outfit", response_model=RecommendationResponse)
async def get_outfit_recommendation(
    db: DbSession, current_user: CurrentUser, request: RecommendationRequest
):
    return await RecommendationController.get_outfit(db, current_user, request)


@router.get("/history")
async def get_recommendation_history(
    db: DbSession,
    current_user: CurrentUser,
    limit: int = Query(20, ge=1, le=100),
):
    return await RecommendationController.get_history(db, current_user, limit=limit)
