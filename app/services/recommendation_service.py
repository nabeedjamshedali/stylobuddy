import json
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import config
from app.core.logger import get_logger
from app.models.outfit_recommendation import OutfitRecommendation
from app.prompts.outfit_prompt import SYSTEM_PROMPT, PROMPT_VERSION
from app.helpers.prompt_helpers import format_wardrobe_for_prompt
from app.repositories.catalog_repository import CatalogRepository
from app.repositories.recommendation_repository import RecommendationRepository
from app.schemas.recommendation_schema import (
    RecommendationRequest,
    RecommendationResponse,
    OutfitCombination,
    OutfitItem,
)
from app.services.llm_service import get_client

logger = get_logger("recommendation_service")


class RecommendationService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.catalog_repo = CatalogRepository(db)
        self.rec_repo = RecommendationRepository(db)
        self.client = get_client()

    async def get_recommendation(
        self, user_id: str, request: RecommendationRequest
    ) -> RecommendationResponse:
        """Fetch wardrobe items, build prompt, call LLM, return structured response."""

        # 1. Fetch items from catalog
        items = await self.catalog_repo.get_by_ids(request.item_ids)
        if len(items) < 2:
            raise ValueError("Need at least 2 valid items for outfit recommendation")

        # Build item lookup for attaching image_urls later
        item_lookup = {item.id: item for item in items}

        # 2. Format wardrobe text for prompt
        items_data = [
            {
                "id": item.id,
                "name": item.name,
                "ai_description": item.ai_description,
                "ai_category": item.ai_category,
            }
            for item in items
        ]
        wardrobe_text = format_wardrobe_for_prompt(items_data)

        # 3. Build user prompt
        user_prompt = wardrobe_text
        if request.occasion:
            user_prompt += f"\n\nOccasion: {request.occasion}"
        if request.preferences:
            user_prompt += f"\nStyle preferences: {request.preferences}"
        user_prompt += "\n\nSuggest the best outfit combinations from these items."

        # 4. Call LLM
        logger.info("Calling LLM for recommendation with %d items", len(items))
        response = await self.client.chat.completions.create(
            model=config.OPENAI_COMPASS_MODEL,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt},
            ],
            temperature=config.LLM_TEMPERATURE,
            max_tokens=config.LLM_MAX_TOKENS,
        )

        raw = response.choices[0].message.content.strip()
        # Strip markdown code fences if present
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[1] if "\n" in raw else raw[3:]
            raw = raw.rsplit("```", 1)[0]
            raw = raw.strip()

        parsed = json.loads(raw)
        token_usage = response.usage.total_tokens if response.usage else None

        # 5. Map to response schema — attach image_urls
        combinations = []
        for combo in parsed.get("combinations", []):
            outfit_items = []
            for oi in combo.get("items", []):
                item_id = oi["item_id"]
                db_item = item_lookup.get(item_id)
                outfit_items.append(
                    OutfitItem(
                        item_id=item_id,
                        item_name=oi.get("item_name", db_item.name if db_item else "Unknown"),
                        image_url=db_item.image_url if db_item else "",
                        category=oi.get("category", db_item.ai_category if db_item else "unknown"),
                        role_in_outfit=oi.get("role_in_outfit", ""),
                    )
                )
            combinations.append(
                OutfitCombination(
                    outfit_name=combo.get("outfit_name", "Outfit"),
                    items=outfit_items,
                    style_description=combo.get("style_description", ""),
                    occasion_fit=combo.get("occasion_fit", []),
                    confidence_score=combo.get("confidence_score", 0.7),
                )
            )

        # Items not used
        used_ids = {oi.item_id for combo in combinations for oi in combo.items}
        items_not_used = [
            OutfitItem(
                item_id=item.id,
                item_name=item.ai_description or item.name,
                image_url=item.image_url,
                category=item.ai_category or "unknown",
                role_in_outfit="",
            )
            for item in items
            if item.id not in used_ids
        ]

        # 6. Persist recommendation
        recommendation_id = str(uuid.uuid4())
        rec = OutfitRecommendation(
            id=recommendation_id,
            user_id=user_id,
            input_item_ids=request.item_ids,
            occasion=request.occasion,
            recommendation_payload=parsed,
            prompt_version=PROMPT_VERSION,
            llm_model=config.OPENAI_COMPASS_MODEL,
            token_usage=token_usage,
        )
        await self.rec_repo.save(rec)

        logger.info("Recommendation %s generated with %d combinations", recommendation_id, len(combinations))

        return RecommendationResponse(
            recommendation_id=recommendation_id,
            combinations=combinations,
            styling_tips=parsed.get("styling_tips", []),
            items_not_used=items_not_used,
        )

    async def get_history(self, user_id: str, limit: int = 20) -> list[dict]:
        recs = await self.rec_repo.get_by_user(user_id, limit=limit)
        return [
            {
                "recommendation_id": rec.id,
                "occasion": rec.occasion,
                "created_at": str(rec.created_at),
                "combinations_count": len(rec.recommendation_payload.get("combinations", [])),
            }
            for rec in recs
        ]

