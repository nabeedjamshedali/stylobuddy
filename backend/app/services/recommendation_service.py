import json
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import config
from app.core.logger import get_logger
from app.models.outfit_recommendation import OutfitRecommendation
from app.prompts.outfit_prompt import (
    SYSTEM_PROMPT,
    AUTO_SUGGEST_SYSTEM_PROMPT,
    PROMPT_VERSION,
)
from app.helpers.prompt_helpers import format_wardrobe_for_prompt, format_auto_suggest_prompt
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
        self, user_id: str | None, request: RecommendationRequest
    ) -> RecommendationResponse:
        """Fetch wardrobe items, build prompt, call LLM, return structured response."""

        # 1. Fetch user-selected items
        items = await self.catalog_repo.get_by_ids(request.item_ids)
        if not items:
            raise ValueError("No valid items found for outfit recommendation")

        # Build item lookup (extended with catalog pool items below)
        item_lookup = {item.id: item for item in items}

        # 2. Detect categories — determine if we need auto-suggest mode
        has_uppers = any(item.type == "uppers" for item in items)
        has_lowers = any(item.type == "lowers" for item in items)

        suggest_mode: str | None = None
        catalog_pool = []

        if has_uppers and not has_lowers:
            # User picked only tops → suggest best matching bottoms from catalog
            catalog_pool = await self.catalog_repo.get_all(category_slug="lowers")
            suggest_mode = "lowers"
            logger.info(
                "Auto-suggest mode: user selected %d upper(s), fetched %d catalog lowers",
                len(items),
                len(catalog_pool),
            )
        elif has_lowers and not has_uppers:
            # User picked only bottoms → suggest best matching tops from catalog
            catalog_pool = await self.catalog_repo.get_all(category_slug="uppers")
            suggest_mode = "uppers"
            logger.info(
                "Auto-suggest mode: user selected %d lower(s), fetched %d catalog uppers",
                len(items),
                len(catalog_pool),
            )

        # Add catalog pool items to lookup so image_urls are available in response
        for pool_item in catalog_pool:
            item_lookup[pool_item.id] = pool_item

        # 3. Build prompt based on mode
        if suggest_mode:
            selected_data = [
                {
                    "id": item.id,
                    "name": item.name,
                    "ai_description": item.ai_description,
                    "ai_category": item.ai_category,
                }
                for item in items
            ]
            pool_data = [
                {
                    "id": item.id,
                    "name": item.name,
                    "ai_description": item.ai_description,
                    "ai_category": item.ai_category,
                }
                for item in catalog_pool
            ]
            user_prompt = format_auto_suggest_prompt(
                selected_items=selected_data,
                catalog_pool=pool_data,
                suggest_mode=suggest_mode,
                occasion=request.occasion,
                preferences=request.preferences,
            )
            system_prompt = AUTO_SUGGEST_SYSTEM_PROMPT
        else:
            # Normal mode: user selected items from multiple categories
            if len(items) < 2:
                raise ValueError("Need at least 2 valid items for outfit recommendation")
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
            user_prompt = wardrobe_text
            if request.occasion:
                user_prompt += f"\n\nOccasion: {request.occasion}"
            if request.preferences:
                user_prompt += f"\nStyle preferences: {request.preferences}"
            user_prompt += "\n\nSuggest the best outfit combinations from these items."
            system_prompt = SYSTEM_PROMPT

        # 4. Call LLM
        logger.info(
            "Calling LLM for recommendation — mode=%s, selected=%d, pool=%d",
            suggest_mode or "normal",
            len(items),
            len(catalog_pool),
        )
        response = await self.client.chat.completions.create(
            model=config.OPENAI_COMPASS_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
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

        # 5. Map to response schema — attach image_urls from item_lookup
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

        # Items not used (only from user-selected items in normal mode;
        # in auto-suggest mode the not-used concept isn't meaningful for display)
        used_ids = {oi.item_id for combo in combinations for oi in combo.items}
        items_not_used = [
            OutfitItem(
                item_id=item.id,
                item_name=item.ai_description or item.name,
                image_url=item.image_url,
                category=item.ai_category or "unknown",
                role_in_outfit="",
            )
            for item in items  # only user-selected, not the entire pool
            if item.id not in used_ids
        ]

        # 6. Persist recommendation (only for authenticated users)
        recommendation_id = str(uuid.uuid4())
        if user_id:
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
        else:
            logger.info("Guest recommendation %s — skipping DB save", recommendation_id)

        logger.info(
            "Recommendation %s generated with %d combinations (mode=%s)",
            recommendation_id,
            len(combinations),
            suggest_mode or "normal",
        )

        return RecommendationResponse(
            recommendation_id=recommendation_id,
            aesthetic=parsed.get("aesthetic", "Curated Look"),
            description=parsed.get("description", ""),
            palette=parsed.get("palette", []),
            tags=parsed.get("tags", []),
            combinations=combinations,
            styling_tips=parsed.get("styling_tips", []),
            items_not_used=items_not_used,
            is_saved=False,
            suggest_mode=suggest_mode,
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
