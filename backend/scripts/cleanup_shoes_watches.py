"""
Remove shoes & watches data from Supabase.

What this script does
─────────────────────
1. Deletes all ClothingItem rows whose subcategory belongs to "shoes" or "watches".
2. Deletes CatalogSubcategory rows under "shoes" and "watches".
3. Deletes the CatalogCategory rows for "shoes" and "watches".
4. Removes the corresponding image files from the Supabase Storage
   "clothing-catalog" bucket.

Usage
─────
    python -m scripts.cleanup_shoes_watches

    # Dry-run (show what would be deleted without making changes):
    python -m scripts.cleanup_shoes_watches --dry-run
"""

import argparse
import asyncio
import os
import sys

import httpx

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select, delete

from app.core.config import config
from app.core.database import async_session_factory, init_db
from app.core.logger import get_logger
from app.models.catalog import CatalogCategory, CatalogSubcategory
from app.models.clothing_item import ClothingItem

logger = get_logger("cleanup_shoes_watches")

SLUGS_TO_REMOVE = ["shoes", "watches"]

# Filenames that were uploaded to the "clothing-catalog" bucket by seed_catalog.py
STORAGE_FILES_TO_DELETE = [
    "white_canvas_lowtops.jpg",
    "chunky_sole_runners.jpg",
    "minimalist_leather_sneakers.jpg",
    "leather_chelsea_boots.jpg",
    "suede_ankle_boots.jpg",
    "suede_penny_loafers.jpg",
    "oxford_brogues.jpg",
    "canvas_strap_field_watch.jpg",
    "slim_silver_dress_watch.jpg",
    "gold_tone_dress_watch.jpg",
    "stainless_chronograph.jpg",
]


async def delete_storage_files(dry_run: bool) -> int:
    """Delete image files from the Supabase Storage bucket."""
    bucket = config.SUPABASE_BUCKET_CLOTHING
    deleted = 0

    headers = {
        "Authorization": f"Bearer {config.SUPABASE_SERVICE_KEY}",
        "apikey": config.SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
    }

    if dry_run:
        for filename in STORAGE_FILES_TO_DELETE:
            logger.info("  [DRY-RUN] Would delete storage file: %s/%s", bucket, filename)
        return len(STORAGE_FILES_TO_DELETE)

    # Supabase Storage API: DELETE /storage/v1/object/{bucket}
    # expects a JSON body with {"prefixes": ["file1", "file2", ...]}
    url = f"{config.SUPABASE_URL}/storage/v1/object/{bucket}"

    async with httpx.AsyncClient(timeout=30) as client:
        try:
            response = await client.request(
                "DELETE",
                url,
                headers=headers,
                json={"prefixes": STORAGE_FILES_TO_DELETE},
            )
            if response.status_code in (200, 204):
                deleted = len(STORAGE_FILES_TO_DELETE)
                for filename in STORAGE_FILES_TO_DELETE:
                    logger.info("  Deleted storage file: %s/%s", bucket, filename)
            else:
                logger.warning(
                    "  Batch delete failed — %d: %s",
                    response.status_code, response.text,
                )
        except Exception as exc:
            logger.warning("  Error during batch delete: %s", exc)

    return deleted


async def cleanup(dry_run: bool = False) -> None:
    await init_db()

    async with async_session_factory() as db:
        # 1. Find category IDs for shoes & watches
        result = await db.execute(
            select(CatalogCategory).where(CatalogCategory.slug.in_(SLUGS_TO_REMOVE))
        )
        categories = result.scalars().all()

        if not categories:
            logger.info("No 'shoes' or 'watches' categories found in DB — nothing to clean up.")
        else:
            category_ids = [cat.id for cat in categories]
            category_names = [cat.name for cat in categories]
            logger.info("Found categories to remove: %s", ", ".join(category_names))

            # 2. Find subcategory IDs under those categories
            result = await db.execute(
                select(CatalogSubcategory).where(
                    CatalogSubcategory.category_id.in_(category_ids)
                )
            )
            subcategories = result.scalars().all()
            subcategory_ids = [sub.id for sub in subcategories]
            logger.info("Found %d subcategories to remove", len(subcategories))

            # 3. Delete clothing items under those subcategories
            if subcategory_ids:
                result = await db.execute(
                    select(ClothingItem).where(
                        ClothingItem.subcategory_id.in_(subcategory_ids)
                    )
                )
                items = result.scalars().all()
                logger.info("Found %d clothing items to remove", len(items))

                if dry_run:
                    for item in items:
                        logger.info("  [DRY-RUN] Would delete item: %s (id=%s)", item.name, item.id)
                else:
                    await db.execute(
                        delete(ClothingItem).where(
                            ClothingItem.subcategory_id.in_(subcategory_ids)
                        )
                    )
                    logger.info("  Deleted %d clothing items", len(items))

            # 4. Delete subcategories
            if dry_run:
                for sub in subcategories:
                    logger.info("  [DRY-RUN] Would delete subcategory: %s", sub.name)
            else:
                await db.execute(
                    delete(CatalogSubcategory).where(
                        CatalogSubcategory.category_id.in_(category_ids)
                    )
                )
                logger.info("  Deleted %d subcategories", len(subcategories))

            # 5. Delete categories
            if dry_run:
                for cat in categories:
                    logger.info("  [DRY-RUN] Would delete category: %s", cat.name)
            else:
                await db.execute(
                    delete(CatalogCategory).where(
                        CatalogCategory.slug.in_(SLUGS_TO_REMOVE)
                    )
                )
                logger.info("  Deleted %d categories", len(categories))

            if not dry_run:
                await db.commit()
                logger.info("Database cleanup committed.")

    # 6. Delete images from Supabase Storage
    logger.info("=== Cleaning up Supabase Storage ===")
    storage_deleted = await delete_storage_files(dry_run)

    mode = "DRY-RUN" if dry_run else "DONE"
    logger.info(
        "Cleanup %s — categories: %d, subcategories: %d, storage files: %d",
        mode,
        len(categories) if categories else 0,
        len(subcategories) if categories else 0,
        storage_deleted,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Remove shoes & watches data from Supabase DB and Storage"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be deleted without making any changes",
    )
    args = parser.parse_args()

    asyncio.run(cleanup(dry_run=args.dry_run))
