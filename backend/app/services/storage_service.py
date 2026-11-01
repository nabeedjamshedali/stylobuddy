"""
Supabase Storage service.

Uses the Supabase REST Storage API directly via httpx so we don't need
the supabase-py SDK as an extra dependency (httpx is already in requirements).

IMPORTANT: Set SUPABASE_SERVICE_KEY in .env for backend uploads.
The service role key bypasses Row Level Security on private buckets.
The anon key only works if the bucket policy allows public inserts.
"""
import uuid
from typing import Literal

import httpx

from app.core.config import config
from app.core.logger import get_logger

logger = get_logger("storage_service")

BucketName = Literal["clothing-catalog", "user-photos"]


def _storage_headers() -> dict[str, str]:
    return {
        "Authorization": f"Bearer {config.SUPABASE_SERVICE_KEY}",
        "apikey": config.SUPABASE_ANON_KEY,
    }


def public_url(bucket: str, path: str) -> str:
    """Return the Supabase public URL for a file in a public bucket."""
    return f"{config.SUPABASE_URL}/storage/v1/object/public/{bucket}/{path}"


async def upload_file(
    bucket: str,
    path: str,
    file_bytes: bytes,
    content_type: str,
) -> str:
    """
    Upload bytes to Supabase Storage and return the public URL.

    Raises httpx.HTTPStatusError on non-2xx responses.
    """
    url = f"{config.SUPABASE_URL}/storage/v1/object/{bucket}/{path}"
    headers = {
        **_storage_headers(),
        "Content-Type": content_type,
        "x-upsert": "true",      # overwrite if the path already exists
    }

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(url, content=file_bytes, headers=headers)
        response.raise_for_status()

    logger.info("Uploaded %d bytes to %s/%s", len(file_bytes), bucket, path)
    return public_url(bucket, path)


async def upload_user_photo(
    user_id: str,
    file_bytes: bytes,
    content_type: str,
    original_filename: str = "",
) -> str:
    """
    Upload a user photo to the user-photos bucket.
    Stored at: user-photos/{user_id}/{uuid}.{ext}
    Returns the public URL.
    """
    ext = original_filename.rsplit(".", 1)[-1] if "." in original_filename else "jpg"
    path = f"{user_id}/{uuid.uuid4()}.{ext}"
    return await upload_file(
        bucket=config.SUPABASE_BUCKET_USER_PHOTOS,
        path=path,
        file_bytes=file_bytes,
        content_type=content_type,
    )


async def upload_clothing_image(
    file_bytes: bytes,
    content_type: str,
    filename: str,
) -> str:
    """
    Upload a clothing catalog image to the clothing-catalog bucket.
    Returns the public URL.
    """
    return await upload_file(
        bucket=config.SUPABASE_BUCKET_CLOTHING,
        path=filename,
        file_bytes=file_bytes,
        content_type=content_type,
    )
