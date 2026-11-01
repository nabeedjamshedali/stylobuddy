from fastapi import UploadFile, HTTPException

from app.schemas.upload_schema import PhotoUploadResponse
from app.services.storage_service import upload_user_photo
from app.core.logger import get_logger

logger = get_logger("upload_controller")

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB


async def upload_photo(file: UploadFile, user_id: str) -> PhotoUploadResponse:
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type '{file.content_type}'. Allowed: JPEG, PNG, WEBP, GIF.",
        )

    file_bytes = await file.read()

    if len(file_bytes) > MAX_SIZE_BYTES:
        raise HTTPException(
            status_code=413,
            detail="File too large. Maximum size is 10 MB.",
        )

    try:
        photo_url = await upload_user_photo(
            user_id=user_id,
            file_bytes=file_bytes,
            content_type=file.content_type,
            original_filename=file.filename or "photo.jpg",
        )
    except Exception as exc:
        logger.error("Storage upload failed for user %s: %s", user_id, exc)
        raise HTTPException(status_code=500, detail="Failed to upload photo. Please try again.")

    return PhotoUploadResponse(photo_url=photo_url)
