"""
Remove extra subcategories (jackets, hoodies, shorts) and specific clothing
items from the Supabase database and storage.

Usage
─────
    python -m scripts.cleanup_extra_items --dry-run
    python -m scripts.cleanup_extra_items
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
from app.models.catalog import CatalogSubcategory
from app.models.clothing_item import ClothingItem

logger = get_logger("cleanup_extra_items")

# Subcategories to remove entirely (all items under them go too)
SUBCATEGORY_SLUGS_TO_REMOVE = ["jackets", "hoodies", "shorts"]

# Individual items to remove by name (from subcategories that stay)
ITEM_NAMES_TO_REMOVE = [
    "Navy Pocket Tee",
    "Oxford Button-Down",
    "Flannel Plaid Shirt",
    "Chunky Ribbed Sweater",
    "Essential Pullover Hoodie",
    "Indigo Selvedge Jeans",
    "Slim Fit Black Jeans",
    "Relaxed Linen Trousers",
    "Slim Beige Chinos",
    "Tailored Twill Shorts",
]

# Storage filenames to delete from the clothing-catalog bucket
STORAGE_FILES_TO_DELETE = [
    # Jackets
    "leather_biker_jacket.jpg",
    "denim_trucker_jacket.jpg",
    # Hoodies
    "essential_pullover_hoodie.jpg",
    # Shorts
    "tailored_twill_shorts.jpg",
    # Individual items
    "navy_pocket_tee.jpg",
    "oxford_button_down.jpg",
    "flannel_plaid_shirt.jpg",
    "chunky_ribbed_sweater.jpg",
    "indigo_selvedge_jeans.jpg",
    "slim_fit_black_jeans.jpg",
    "relaxed_linen_trousers.jpg",
    "slim_beige_chinos.jpg",
]


async def delete_storage_files(dry_run: bool) -> int:
    """Delete image files from the Supabase Storage bucket."""
    bucket = config.SUPABASE_BUCKET_CLOTHING
    deleted = 0

    if dry_run:
        for filename in STORAGE_FILES_TO_DELETE:
            logger.info("  [DRY-RUN] Would delete storage file: %s/%s", bucket, filename)
        return len(STORAGE_FILES_TO_DELETE)

    headers = {
        "Authorization": f"Bearer {config.SUPABASE_SERVICE_KEY}",
        "apikey": config.SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
    }

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

    total_items_deleted = 0
    total_subcats_deleted = 0

    async with async_session_factory() as db:
        # 1. Delete items under subcategories being removed
        result = await db.execute(
            select(CatalogSubcategory).where(
                CatalogSubcategory.slug.in_(SUBCATEGORY_SLUGS_TO_REMOVE)
            )
        )
        subcategories = result.scalars().all()

        if subcategories:
            subcategory_ids = [sub.id for sub in subcategories]
            logger.info(
                "Found subcategories to remove: %s",
                ", ".join(f"{sub.name} ({sub.slug})" for sub in subcategories),
            )

            # Find items under those subcategories
            result = await db.execute(
                select(ClothingItem).where(
                    ClothingItem.subcategory_id.in_(subcategory_ids)
                )
            )
            subcat_items = result.scalars().all()

            if subcat_items:
                if dry_run:
                    for item in subcat_items:
                        logger.info("  [DRY-RUN] Would delete item (subcat): %s", item.name)
                else:
                    await db.execute(
                        delete(ClothingItem).where(
                            ClothingItem.subcategory_id.in_(subcategory_ids)
                        )
                    )
                    logger.info("  Deleted %d items from removed subcategories", len(subcat_items))
                total_items_deleted += len(subcat_items)

            # Delete the subcategories themselves
            if dry_run:
                for sub in subcategories:
                    logger.info("  [DRY-RUN] Would delete subcategory: %s", sub.name)
            else:
                await db.execute(
                    delete(CatalogSubcategory).where(
                        CatalogSubcategory.slug.in_(SUBCATEGORY_SLUGS_TO_REMOVE)
                    )
                )
                logger.info("  Deleted %d subcategories", len(subcategories))
            total_subcats_deleted = len(subcategories)
        else:
            logger.info("No matching subcategories found — already removed.")

        # 2. Delete individual items by name
        result = await db.execute(
            select(ClothingItem).where(ClothingItem.name.in_(ITEM_NAMES_TO_REMOVE))
        )
        named_items = result.scalars().all()

        if named_items:
            if dry_run:
                for item in named_items:
                    logger.info("  [DRY-RUN] Would delete item (by name): %s", item.name)
            else:
                await db.execute(
                    delete(ClothingItem).where(
                        ClothingItem.name.in_(ITEM_NAMES_TO_REMOVE)
                    )
                )
                logger.info("  Deleted %d items by name", len(named_items))
            total_items_deleted += len(named_items)
        else:
            logger.info("No matching named items found — already removed.")

        if not dry_run:
            await db.commit()
            logger.info("Database cleanup committed.")

    # 3. Delete storage files
    logger.info("=== Cleaning up Supabase Storage ===")
    storage_deleted = await delete_storage_files(dry_run)

    mode = "DRY-RUN" if dry_run else "DONE"
    logger.info(
        "Cleanup %s — subcategories: %d, items: %d, storage files: %d",
        mode, total_subcats_deleted, total_items_deleted, storage_deleted,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Remove extra subcategories and items from Supabase"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be deleted without making any changes",
    )
    args = parser.parse_args()

    asyncio.run(cleanup(dry_run=args.dry_run))
