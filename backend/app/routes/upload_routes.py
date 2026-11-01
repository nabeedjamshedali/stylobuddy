from fastapi import APIRouter, Depends, UploadFile, File

from app.controllers.upload_controller import upload_photo
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.upload_schema import PhotoUploadResponse

router = APIRouter(prefix="/api/upload", tags=["Upload"])


@router.post("/photo", response_model=PhotoUploadResponse)
async def upload_user_photo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
) -> PhotoUploadResponse:
    """
    Upload a user photo to Supabase Storage.

    - Accepts: JPEG, PNG, WEBP (max 10 MB)
    - Returns: public URL stored in Supabase Storage under user-photos/{user_id}/
    - The returned `photo_url` is passed to POST /api/recommendations/outfit
      for personalised outfit generation.
    """
    return await upload_photo(file=file, user_id=current_user.id)
