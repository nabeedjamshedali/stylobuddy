import base64
import json
import os

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import config
from app.core.logger import get_logger
from app.prompts.vision_prompt import VISION_ANALYSIS_PROMPT
from app.repositories.catalog_repository import CatalogRepository
from app.schemas.vision_schema import ClothingAnalysis
from app.services.llm_service import get_client

logger = get_logger("vision_service")


class VisionService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.catalog_repo = CatalogRepository(db)
        self.client = get_client()

    async def _load_image(self, image_url: str) -> tuple[bytes, str]:
        """Load image bytes and mime type from a URL or local path."""
        if image_url.startswith("http://") or image_url.startswith("https://"):
            async with httpx.AsyncClient(timeout=30) as http_client:
                response = await http_client.get(image_url, follow_redirects=True)
                response.raise_for_status()
                image_bytes = response.content
            # Detect mime from content-type header or fall back to jpeg
            content_type = response.headers.get("content-type", "image/jpeg")
            mime_type = content_type.split(";")[0].strip()
            return image_bytes, mime_type
        else:
            # Legacy local file path support
            local_path = image_url.lstrip("/")
            if not os.path.exists(local_path):
                raise FileNotFoundError(f"Image file not found: {local_path}")
            with open(local_path, "rb") as f:
                image_bytes = f.read()
            ext = os.path.splitext(local_path)[1].lower()
            mime_map = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png", ".webp": "image/webp"}
            mime_type = mime_map.get(ext, "image/jpeg")
            return image_bytes, mime_type

    async def analyze_image(self, image_url: str) -> ClothingAnalysis:
        """Send a clothing image (URL or local path) to GPT-4o vision and get structured analysis."""

        image_bytes, mime_type = await self._load_image(image_url)
        image_data = base64.b64encode(image_bytes).decode("utf-8")

        response = await self.client.chat.completions.create(
            model=config.OPENAI_COMPASS_MODEL,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": VISION_ANALYSIS_PROMPT},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:{mime_type};base64,{image_data}",
                                "detail": "low",
                            },
                        },
                    ],
                }
            ],
            max_tokens=200,
            temperature=0.3,
        )

        raw = response.choices[0].message.content.strip()
        # Strip markdown code fences if present
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[1] if "\n" in raw else raw[3:]
            raw = raw.rsplit("```", 1)[0]
            raw = raw.strip()

        parsed = json.loads(raw)
        return ClothingAnalysis(**parsed)

    async def analyze_item(self, item_id: str) -> ClothingAnalysis | None:
        """Analyze a single catalog item's image and update its AI fields."""

        item = await self.catalog_repo.get_by_id(item_id)
        if not item:
            logger.error("Item %s not found", item_id)
            return None

        if not item.image_url:
            logger.error("Item %s has no image_url", item_id)
            return None

        logger.info("Analyzing image for item %s: %s", item_id, item.image_url)
        analysis = await self.analyze_image(item.image_url)

        item.ai_description = analysis.description
        item.ai_category = analysis.category
        await self.catalog_repo.update(item)

        logger.info("Item %s analyzed: %s", item_id, analysis.description)
        return analysis

    async def analyze_all_unanalyzed(self) -> int:
        """Analyze all catalog items that haven't been analyzed yet."""

        items = await self.catalog_repo.get_unanalyzed()
        logger.info("Found %d unanalyzed items", len(items))
        count = 0

        for item in items:
            try:
                result = await self.analyze_item(item.id)
                if result:
                    count += 1
            except Exception as e:
                logger.error("Failed to analyze item %s: %s", item.id, str(e))

        logger.info("Analyzed %d/%d items", count, len(items))
        return count
