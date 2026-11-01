import json
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import config
from app.core.logger import get_logger
from app.models.outfit_recommendation import OutfitRecommendation
from app.prompts.outfit_prompt import (
    SYSTEM_PROMPT,
    AUTO_SUGGEST_SYSTEM_PROMPT,
    PHOTO_ONLY_SYSTEM_PROMPT,
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
from app.services import tacn_service

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

        # ── Photo-only mode: user uploaded a photo, no catalog items selected ────
        if not request.item_ids and request.photo_type in ("uppers", "lowers"):
            logger.info("Photo-only mode: photo_type=%s", request.photo_type)
            complementary = "lowers" if request.photo_type == "uppers" else "uppers"
            catalog_pool = await self.catalog_repo.get_all(category_slug=complementary)
            pool_lookup = {item.id: item for item in catalog_pool}
            return await self._handle_photo_only(
                user_id, request, catalog_pool, pool_lookup, request.photo_type
            )

        # 1. Fetch user-selected items
        logger.info("Received item_ids from frontend (%d): %s", len(request.item_ids), request.item_ids)
        items = await self.catalog_repo.get_by_ids(request.item_ids)
        if not items:
            raise ValueError("No valid items found for outfit recommendation")

        # Warn if some requested IDs were not found (stale frontend state)
        if len(items) != len(request.item_ids):
            found_ids = {item.id for item in items}
            missing = [iid for iid in request.item_ids if iid not in found_ids]
            logger.warning(
                "Requested %d item IDs but only %d found in DB. Missing: %s",
                len(request.item_ids), len(items), missing,
            )

        item_lookup = {item.id: item for item in items}

        # 2. Detect categories
        logger.info(
            "Items resolved: %s",
            [(item.id[:8], item.name, item.type) for item in items],
        )
        has_uppers = any(item.type == "uppers" for item in items)
        has_lowers = any(item.type == "lowers" for item in items)

        suggest_mode: str | None = None
        catalog_pool = []

        if has_uppers and not has_lowers:
            uppers_count = sum(1 for item in items if item.type == "uppers")
            catalog_pool = await self.catalog_repo.get_all(category_slug="lowers")
            suggest_mode = "lowers"
            # Only pass items that are actually uppers to auto-suggest
            items = [item for item in items if item.type == "uppers"]
            logger.info("Auto-suggest mode: %d upper(s) selected, %d catalog lowers available", uppers_count, len(catalog_pool))
        elif has_lowers and not has_uppers:
            lowers_count = sum(1 for item in items if item.type == "lowers")
            catalog_pool = await self.catalog_repo.get_all(category_slug="uppers")
            suggest_mode = "uppers"
            # Only pass items that are actually lowers to auto-suggest
            items = [item for item in items if item.type == "lowers"]
            logger.info("Auto-suggest mode: %d lower(s) selected, %d catalog uppers available", lowers_count, len(catalog_pool))

        # Add catalog pool items to lookup
        for pool_item in catalog_pool:
            item_lookup[pool_item.id] = pool_item

        # ─────────────────────────────────────────────────────────────────────
        # CASE 2: Auto-suggest — TACN ranks pool, then GPT picks best combos
        # ─────────────────────────────────────────────────────────────────────
        if suggest_mode:
            return await self._handle_auto_suggest(
                user_id, request, items, catalog_pool, suggest_mode, item_lookup
            )

        # ─────────────────────────────────────────────────────────────────────
        # CASE 1 & 3: Normal mode (user selected from both categories)
        # ─────────────────────────────────────────────────────────────────────
        if len(items) < 2:
            raise ValueError("Need at least 2 valid items for outfit recommendation")

        return await self._handle_normal(user_id, request, items, item_lookup)

    # ─────────────────────────────────────────────────────────────────────────────
    # Photo-only mode
    # ─────────────────────────────────────────────────────────────────────────────

    async def _handle_photo_only(
        self,
        user_id: str | None,
        request: RecommendationRequest,
        catalog_pool,
        pool_lookup: dict,
        photo_type: str,
    ) -> RecommendationResponse:
        """
        User uploaded a photo without selecting any catalog items.
        TACN is skipped (no stored image URL for the uploaded photo).
        GPT picks the best 5 catalog pieces from the complementary category.
        """
        suggest_mode = "lowers" if photo_type == "uppers" else "uppers"
        type_label = "TOP (shirt / t-shirt / knitwear)" if photo_type == "uppers" else "BOTTOM (jeans / trousers / chinos)"
        pool_label = "BOTTOM pieces" if photo_type == "uppers" else "TOP pieces"

        lines = [
            f"The user has uploaded a photo of a {type_label} they own.",
            f"From the catalog {pool_label} below, recommend the 5 best pairings:\n",
        ]
        for item in catalog_pool:
            desc = item.ai_description or item.name
            color = item.color or ""
            material = item.material or ""
            extra = f" ({color}, {material})" if color or material else ""
            lines.append(f"- [{item.id}] {item.name}{extra} — {desc}")

        if request.occasion:
            lines.append(f"\nOccasion: {request.occasion}")
        if request.preferences:
            lines.append(f"Style preferences: {request.preferences}")

        user_prompt = "\n".join(lines)

        try:
            parsed, token_usage = await self._call_llm(PHOTO_ONLY_SYSTEM_PROMPT, user_prompt)
            pipeline_mode = "online"
        except Exception as e:
            logger.warning("LLM unreachable (%s) in photo-only mode", e)
            raise ValueError("Could not reach the AI service. Please try again.")

        return await self._build_llm_response(
            user_id, request, parsed, token_usage, pool_lookup,
            suggest_mode=suggest_mode,
            pipeline_mode=pipeline_mode,
            tacn_prefiltered=False,
            selected_items=[],
        )

    # ─────────────────────────────────────────────────────────────────────────────
    # CASE 2: Auto-suggest
    # ─────────────────────────────────────────────────────────────────────────────

    async def _handle_auto_suggest(
        self,
        user_id: str | None,
        request: RecommendationRequest,
        selected_items,
        catalog_pool,
        suggest_mode: str,
        item_lookup: dict,
    ) -> RecommendationResponse:
        """
        User selected only uppers or only lowers.
        TACN ranks the catalog pool → top items sent to GPT for final styling.
        Falls back to TACN-only if LLM is unreachable.
        """
        selected_data = [
            {
                "id": item.id,
                "name": item.name,
                "image_url": item.image_url,
                "ai_description": item.ai_description,
                "ai_category": item.ai_category,
                "type": item.type,
                "color": getattr(item, "color", "") or "",
                "material": getattr(item, "material", "") or "",
            }
            for item in selected_items
        ]
        pool_data = [
            {
                "id": item.id,
                "name": item.name,
                "image_url": item.image_url,
                "ai_description": item.ai_description,
                "ai_category": item.ai_category,
                "type": item.type,
                "color": getattr(item, "color", "") or "",
                "material": getattr(item, "material", "") or "",
            }
            for item in catalog_pool
        ]

        # TACN: rank pool items by avg compatibility with all selected items
        ranked_pool = tacn_service.rank_catalog_pool(
            selected_items=selected_data,
            catalog_pool=pool_data,
            top_k=config.TACN_TOP_K,
        )
        logger.info("TACN ranked pool: sending top %d items to LLM", len(ranked_pool))

        user_prompt = format_auto_suggest_prompt(
            selected_items=selected_data,
            catalog_pool=ranked_pool,
            suggest_mode=suggest_mode,
            occasion=request.occasion,
            preferences=request.preferences,
        )

        try:
            parsed, token_usage = await self._call_llm(AUTO_SUGGEST_SYSTEM_PROMPT, user_prompt)
            pipeline_mode = "hybrid"
        except Exception as e:
            logger.warning("LLM unreachable (%s) — falling back to TACN offline mode", e)
            return self._build_offline_response(
                user_id, request, selected_items + catalog_pool[:config.TACN_TOP_K],
                suggest_mode, item_lookup
            )

        return await self._build_llm_response(
            user_id, request, parsed, token_usage, item_lookup,
            suggest_mode=suggest_mode,
            pipeline_mode=pipeline_mode,
            tacn_prefiltered=True,
            selected_items=selected_items,
        )

    # ─────────────────────────────────────────────────────────────────────────────
    # CASE 1 & 3: Normal mode (both categories selected)
    # ─────────────────────────────────────────────────────────────────────────────

    async def _handle_normal(
        self,
        user_id: str | None,
        request: RecommendationRequest,
        items,
        item_lookup: dict,
    ) -> RecommendationResponse:
        """
        User selected items from both categories.
        - If total items >= threshold → CASE 3: pre-filter with TACN then GPT
        - Otherwise → send all directly to GPT
        - If LLM fails → CASE 1 offline fallback with TACN
        """
        total_items = len(items)
        tacn_prefiltered = False

        uppers = [i for i in items if i.type == "uppers"]
        lowers = [i for i in items if i.type == "lowers"]

        # ── CASE 3: Pre-filter if item count exceeds threshold ───────────────
        if total_items >= config.TACN_PREFILTER_ITEM_THRESHOLD and len(uppers) > 0 and len(lowers) > 0:
            logger.info(
                "Case 3: %d items (>=%d threshold) -- TACN pre-filtering",
                total_items, config.TACN_PREFILTER_ITEM_THRESHOLD,
            )
            upper_data = [
                {
                    "id": i.id, "name": i.name, "image_url": i.image_url,
                    "ai_description": i.ai_description, "ai_category": i.ai_category, "type": i.type,
                }
                for i in uppers
            ]
            lower_data = [
                {
                    "id": i.id, "name": i.name, "image_url": i.image_url,
                    "ai_description": i.ai_description, "ai_category": i.ai_category, "type": i.type,
                }
                for i in lowers
            ]

            top_pairs = tacn_service.prefilter_combinations(upper_data, lower_data)

            # Build items_data from only the items that appear in top pairs
            seen_ids = set()
            items_data = []
            for pair in top_pairs:
                for key in ("upper", "lower"):
                    item = pair[key]
                    if item["id"] not in seen_ids:
                        seen_ids.add(item["id"])
                        items_data.append(item)

            tacn_prefiltered = True
            logger.info("Pre-filter kept %d unique items from %d top pairs", len(items_data), len(top_pairs))
        else:
            top_pairs = None
            # No pre-filtering needed — send all items to GPT
            items_data = [
                {
                    "id": item.id, "name": item.name,
                    "ai_description": item.ai_description, "ai_category": item.ai_category,
                    "type": item.type, "color": item.color, "material": item.material,
                }
                for item in items
            ]

        # Build prompt
        wardrobe_text = format_wardrobe_for_prompt(items_data)
        user_prompt = wardrobe_text

        # If TACN pre-filtered, tell GPT exactly which pairs to use
        if top_pairs:
            user_prompt += "\n\nPRE-APPROVED PAIRINGS (use these exact top+bottom combinations):\n"
            for i, pair in enumerate(top_pairs, 1):
                user_prompt += f"  {i}. [{pair['upper']['id']}] {pair['upper']['name']}  +  [{pair['lower']['id']}] {pair['lower']['name']}  (score: {pair['tacn_score']})\n"
            user_prompt += f"\nCreate outfit combinations for the top 5 best pairings above, ranked from best to least. Use the EXACT item IDs provided."
        else:
            user_prompt += "\n\nCreate up to 5 outfit combinations ranked from best to least. Use a DIFFERENT top-bottom pairing in each combination."

        if request.occasion:
            user_prompt += f"\n\nOccasion: {request.occasion}"
        if request.preferences:
            user_prompt += f"\nStyle preferences: {request.preferences}"

        # ── Try LLM (online) ─────────────────────────────────────────────────
        try:
            parsed, token_usage = await self._call_llm(SYSTEM_PROMPT, user_prompt)
            pipeline_mode = "hybrid" if tacn_prefiltered else "online"
        except Exception as e:
            # ── CASE 1 fallback: offline TACN-only ────────────────────────────
            logger.warning("LLM unreachable (%s) — falling back to TACN offline", e)
            return self._build_offline_response(
                user_id, request, items, None, item_lookup
            )

        return await self._build_llm_response(
            user_id, request, parsed, token_usage, item_lookup,
            suggest_mode=None,
            pipeline_mode=pipeline_mode,
            tacn_prefiltered=tacn_prefiltered,
            selected_items=items,
        )

    # ─────────────────────────────────────────────────────────────────────────────
    # Shared: LLM call
    # ─────────────────────────────────────────────────────────────────────────────

    async def _call_llm(self, system_prompt: str, user_prompt: str) -> tuple[dict, int | None]:
        """Call LLM and return parsed JSON + token usage. Raises on failure."""
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
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[1] if "\n" in raw else raw[3:]
            raw = raw.rsplit("```", 1)[0]
            raw = raw.strip()

        token_usage = response.usage.total_tokens if response.usage else None

        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            # LLM response was likely truncated — try to recover partial JSON
            parsed = self._recover_truncated_json(raw)
            if parsed is None:
                raise
            logger.warning("Recovered partial LLM response (%d combinations salvaged)",
                           len(parsed.get("combinations", [])))

        return parsed, token_usage

    @staticmethod
    def _recover_truncated_json(raw: str) -> dict | None:
        """Try to recover a truncated JSON response by closing open structures."""
        # Strategy: progressively trim from the end and try to close the JSON
        # Find the last complete combination by looking for the last "}," or "}" in items
        last_bracket = raw.rfind("}")
        if last_bracket == -1:
            return None

        # Try closing at various points
        for trim_pos in range(len(raw), max(0, len(raw) - 2000), -1):
            candidate = raw[:trim_pos]
            # Try adding closing brackets/braces
            for suffix in ["]}", "]}]}", '"]}", "]}]}', "]}}",
                           "]}]}", '"}]}]}', '"]}]}']:
                try:
                    result = json.loads(candidate + suffix)
                    if isinstance(result, dict) and "combinations" in result:
                        return result
                except json.JSONDecodeError:
                    continue

        return None

    # ─────────────────────────────────────────────────────────────────────────────
    # Shared: Build response from LLM output
    # ─────────────────────────────────────────────────────────────────────────────

    async def _build_llm_response(
        self,
        user_id: str | None,
        request: RecommendationRequest,
        parsed: dict,
        token_usage: int | None,
        item_lookup: dict,
        suggest_mode: str | None,
        pipeline_mode: str,
        tacn_prefiltered: bool,
        selected_items,
    ) -> RecommendationResponse:
        """Map LLM JSON to RecommendationResponse, persist to DB."""

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
                        category=oi.get("category") or (db_item.ai_category if db_item else None) or (db_item.type if db_item else None) or "unknown",
                        role_in_outfit=oi.get("role_in_outfit", ""),
                    )
                )
            combinations.append(
                OutfitCombination(
                    outfit_name=combo.get("outfit_name", "Outfit"),
                    items=outfit_items,
                    style_description=combo.get("style_description", ""),
                    occasion_fit=combo.get("occasion_fit", []),
                    confidence_score=max(0.0, min(1.0, combo.get("confidence_score", 0.7))),
                )
            )

        # Confidence filter:
        # - TACN pre-filtered: pairs already validated by TACN — skip filter,
        #   trust TACN scoring over GPT's self-reported confidence.
        # - Not pre-filtered: GPT chose the pairs itself, apply 50% floor.
        if not tacn_prefiltered:
            combinations = [c for c in combinations if c.confidence_score >= 0.5]
        else:
            logger.info(
                "Skipping confidence filter (TACN pre-filtered): keeping all %d combos",
                len(combinations),
            )

        # Auto-suggest: enforce max 2 combos per selected item when multiple items chosen.
        # GPT cannot reliably enforce this count constraint itself, so we do it in code.
        if suggest_mode and len(selected_items) > 1:
            MAX_PER_ITEM = 2
            selected_ids = {item.id for item in selected_items}
            per_item_count: dict[str, int] = {}
            capped: list[OutfitCombination] = []
            for combo in combinations:
                # Identify which selected item this combo uses
                sel_id = next(
                    (oi.item_id for oi in combo.items if oi.item_id in selected_ids),
                    None,
                )
                if sel_id is None:
                    continue  # combo doesn't reference a selected item — skip
                if per_item_count.get(sel_id, 0) < MAX_PER_ITEM:
                    capped.append(combo)
                    per_item_count[sel_id] = per_item_count.get(sel_id, 0) + 1

            before, after = len(combinations), len(capped)
            if before != after:
                logger.info(
                    "Per-item cap applied: %d -> %d combos (max %d per item)",
                    before, after, MAX_PER_ITEM,
                )
            combinations = capped

        # Items not used
        used_ids = {oi.item_id for combo in combinations for oi in combo.items}
        items_not_used = [
            OutfitItem(
                item_id=item.id,
                item_name=item.ai_description or item.name,
                image_url=item.image_url,
                category=item.ai_category or item.type or "unknown",
                role_in_outfit="",
            )
            for item in selected_items
            if item.id not in used_ids
        ]

        # Persist
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
            "Recommendation %s: %d combos (mode=%s, pipeline=%s, prefiltered=%s)",
            recommendation_id, len(combinations), suggest_mode or "normal",
            pipeline_mode, tacn_prefiltered,
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
            pipeline_mode=pipeline_mode,
            tacn_prefiltered=tacn_prefiltered,
        )

    # ─────────────────────────────────────────────────────────────────────────────
    # Case 1 fallback: Build response from TACN offline scoring
    # ─────────────────────────────────────────────────────────────────────────────

    def _build_offline_response(
        self,
        user_id: str | None,
        request: RecommendationRequest,
        items,
        suggest_mode: str | None,
        item_lookup: dict,
    ) -> RecommendationResponse:
        """Generate a recommendation using only TACN (no LLM). Used when offline."""

        items_data = [
            {
                "id": item.id,
                "name": item.name,
                "image_url": item.image_url,
                "ai_description": item.ai_description,
                "ai_category": item.ai_category,
                "type": item.type,
            }
            for item in items
        ]

        ranked_outfits = tacn_service.offline_recommend(items_data, top_k=5)

        # Convert TACN output to standard response format
        combinations = []
        for outfit in ranked_outfits:
            outfit_items = []
            for item_dict in outfit["items"]:
                outfit_items.append(
                    OutfitItem(
                        item_id=item_dict["id"],
                        item_name=item_dict.get("ai_description") or item_dict["name"],
                        image_url=item_dict["image_url"],
                        category=item_dict.get("ai_category") or item_dict.get("type") or "unknown",
                        role_in_outfit=item_dict.get("type") or "",
                    )
                )
            combinations.append(
                OutfitCombination(
                    outfit_name=f"Outfit #{outfit['rank']}",
                    items=outfit_items,
                    style_description=f"TACN compatibility score: {outfit['compatibility_score']}",
                    occasion_fit=[request.occasion] if request.occasion else ["casual"],
                    confidence_score=max(0.0, min(1.0, (outfit["compatibility_score"] + 1) / 2)),
                )
            )

        # Keep only combinations with >= 50% confidence
        combinations = [c for c in combinations if c.confidence_score >= 0.5]

        recommendation_id = str(uuid.uuid4())
        logger.info("Offline recommendation %s: %d combos via TACN (after 50%% filter)", recommendation_id, len(combinations))

        if not combinations:
            raise ValueError("No outfit combinations met the quality threshold. Try selecting different items.")

        return RecommendationResponse(
            recommendation_id=recommendation_id,
            aesthetic="AI-Scored Look",
            description="Recommended by StyloBuddy's compatibility model (offline mode).",
            palette=[],
            tags=["offline", "tacn-scored"],
            combinations=combinations,
            styling_tips=["These outfits are ranked by visual compatibility scoring."],
            items_not_used=[],
            is_saved=False,
            suggest_mode=suggest_mode,
            pipeline_mode="offline",
            tacn_prefiltered=False,
        )

    # ─────────────────────────────────────────────────────────────────────────────
    # History
    # ─────────────────────────────────────────────────────────────────────────────

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
