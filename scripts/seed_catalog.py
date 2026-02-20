"""
Seed the catalog with sample clothing images from the internet.
Downloads images, saves to static/images/, runs vision analysis, inserts to DB.

Usage: python -m scripts.seed_catalog
"""

import asyncio
import os
import sys

import httpx

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import async_session_factory, init_db
from app.core.config import config
from app.core.logger import get_logger
from app.models.clothing_item import ClothingItem
from app.services.vision_service import VisionService

logger = get_logger("seed_catalog")

# Sample clothing images (royalty-free from Unsplash/Pexels)
SAMPLE_ITEMS = [
    {
        "name": "item_001",
        "url": "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400",
        "filename": "white_tshirt.jpg",
    },
    {
        "name": "item_002",
        "url": "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400",
        "filename": "blue_denim_shirt.jpg",
    },
    {
        "name": "item_003",
        "url": "https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=400",
        "filename": "black_polo.jpg",
    },
    {
        "name": "item_004",
        "url": "https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400",
        "filename": "blue_jeans.jpg",
    },
    {
        "name": "item_005",
        "url": "https://images.unsplash.com/photo-1517438476312-10d79c077509?w=400",
        "filename": "khaki_chinos.jpg",
    },
    {
        "name": "item_006",
        "url": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400",
        "filename": "red_nike_sneakers.jpg",
    },
    {
        "name": "item_007",
        "url": "https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400",
        "filename": "colorful_sneakers.jpg",
    },
    {
        "name": "item_008",
        "url": "https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=400",
        "filename": "classic_watch.jpg",
    },
    {
        "name": "item_009",
        "url": "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=400",
        "filename": "beige_jacket.jpg",
    },
    {
        "name": "item_010",
        "url": "https://images.unsplash.com/photo-1622445275463-afa2ab738c34?w=400",
        "filename": "black_shorts.jpg",
    },
]


async def download_image(client: httpx.AsyncClient, url: str, filepath: str) -> bool:
    """Download image from URL and save to filepath."""
    try:
        response = await client.get(url, follow_redirects=True, timeout=30.0)
        response.raise_for_status()
        with open(filepath, "wb") as f:
            f.write(response.content)
        logger.info("Downloaded: %s", filepath)
        return True
    except Exception as e:
        logger.error("Failed to download %s: %s", url, str(e))
        return False


async def seed():
    """Main seeding function."""
    os.makedirs(config.IMAGES_DIR, exist_ok=True)
    await init_db()

    async with httpx.AsyncClient() as http_client:
        async with async_session_factory() as db:
            vision_service = VisionService(db)

            for item_data in SAMPLE_ITEMS:
                filepath = os.path.join(config.IMAGES_DIR, item_data["filename"])
                image_url = f"/{config.IMAGES_DIR}/{item_data['filename']}"

                # Download image if not exists
                if not os.path.exists(filepath):
                    success = await download_image(http_client, item_data["url"], filepath)
                    if not success:
                        continue

                # Create catalog item
                catalog_item = ClothingItem(
                    name=item_data["name"],
                    image_url=image_url,
                )
                db.add(catalog_item)
                await db.flush()

                # Run vision analysis
                try:
                    analysis = await vision_service.analyze_item(catalog_item.id)
                    if analysis:
                        logger.info(
                            "  -> %s: [%s] %s",
                            item_data["name"],
                            analysis.category,
                            analysis.description,
                        )
                except Exception as e:
                    logger.error("  -> Vision analysis failed for %s: %s", item_data["name"], str(e))

            await db.commit()
            logger.info("Seeding complete!")


if __name__ == "__main__":
    asyncio.run(seed())
