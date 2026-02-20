from fastapi import APIRouter

from app.controllers.wardrobe_controller import WardrobeController
from app.schemas.wardrobe_schema import (
    WardrobeAddRequest,
    WardrobeItemResponse,
    WardrobeListResponse,
)
from app.core.dependencies import DbSession, CurrentUser

router = APIRouter(prefix="/api/wardrobe", tags=["Wardrobe"])


@router.get("/", response_model=WardrobeListResponse)
async def list_wardrobe(db: DbSession, current_user: CurrentUser):
    return await WardrobeController.list_items(db, current_user)


@router.post("/", response_model=list[WardrobeItemResponse], status_code=201)
async def add_to_wardrobe(db: DbSession, current_user: CurrentUser, request: WardrobeAddRequest):
    return await WardrobeController.add_items(db, current_user, request)


@router.delete("/{wardrobe_id}")
async def remove_from_wardrobe(db: DbSession, current_user: CurrentUser, wardrobe_id: str):
    return await WardrobeController.remove_item(db, current_user, wardrobe_id)
