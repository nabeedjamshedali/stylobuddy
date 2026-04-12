from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.controllers.saved_controller import save_look, unsave_look, get_saved_looks
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.recommendation_schema import SavedLookResponse

router = APIRouter(prefix="/api/saved-looks", tags=["Saved Looks"])


@router.post("/{recommendation_id}", response_model=SavedLookResponse)
async def save_outfit_look(
    recommendation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SavedLookResponse:
    """
    Mark a generated outfit recommendation as saved.
    The recommendation must belong to the current user.
    """
    return await save_look(recommendation_id, current_user.id, db)


@router.delete("/{recommendation_id}")
async def unsave_outfit_look(
    recommendation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Remove a look from saved. Does not delete the recommendation record."""
    return await unsave_look(recommendation_id, current_user.id, db)


@router.get("/", response_model=list[SavedLookResponse])
async def list_saved_looks(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[SavedLookResponse]:
    """
    Return all looks the current user has saved, newest first.
    Used by the /saved page.
    """
    return await get_saved_looks(current_user.id, db)
