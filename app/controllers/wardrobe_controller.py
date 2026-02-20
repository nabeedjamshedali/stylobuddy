from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.wardrobe_service import WardrobeService
from app.schemas.wardrobe_schema import (
    WardrobeAddRequest,
    WardrobeItemResponse,
    WardrobeListResponse,
)
from app.models.user import User
from app.core.logger import get_logger

logger = get_logger("wardrobe_controller")


class WardrobeController:

    @staticmethod
    async def list_items(db: AsyncSession, user: User) -> WardrobeListResponse:
        service = WardrobeService(db)
        return await service.list_items(user.id)

    @staticmethod
    async def add_items(
        db: AsyncSession, user: User, request: WardrobeAddRequest
    ) -> list[WardrobeItemResponse]:
        service = WardrobeService(db)
        added = await service.add_items(user.id, request.item_ids)
        if not added:
            raise HTTPException(
                status_code=400,
                detail="No items were added. Items may not exist or are already in wardrobe.",
            )
        return added

    @staticmethod
    async def remove_item(db: AsyncSession, user: User, wardrobe_id: str) -> dict:
        service = WardrobeService(db)
        removed = await service.remove_item(user.id, wardrobe_id)
        if not removed:
            raise HTTPException(status_code=404, detail="Wardrobe entry not found")
        return {"message": "Item removed from wardrobe"}
