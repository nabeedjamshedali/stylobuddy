"""
TACN Scoring Service — StyloBuddy
==================================
Integrates the Type-Aware Compatibility Network into the recommendation pipeline.

Provides:
    - Model loading and caching
    - Pairwise and outfit-level scoring
    - Pre-filtering large item sets (Case 3)
    - Offline-only recommendations (Case 1 fallback)
    - Catalog pool ranking for auto-suggest (Case 2)
"""

import sys
from itertools import product as iter_product
from pathlib import Path

import torch

from app.core.config import config
from app.core.logger import get_logger

# Add project root to import the model module
PROJECT_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(PROJECT_ROOT))

from outfit_recommendation_model import (
    TACN,
    load_image_from_url,
    load_model,
)

logger = get_logger("tacn_service")

# ─── Singleton ────────────────────────────────────────────────────────────────

_model: TACN | None = None
_device: str = "cpu"


def _get_device() -> str:
    return "cuda" if torch.cuda.is_available() else "cpu"


def get_tacn_model() -> TACN:
    """Load or return cached TACN model."""
    global _model, _device

    if _model is not None:
        return _model

    _device = _get_device()
    model_path = Path(config.TACN_MODEL_PATH)

    if model_path.exists():
        logger.info("Loading TACN weights from %s (device=%s)", model_path, _device)
        _model = load_model(str(model_path), frozen_backbone=True)
    else:
        logger.warning("No TACN weights at '%s' — using untrained model", model_path)
        _model = TACN(frozen_backbone=True)
        _model.eval()

    _model.to(_device)
    return _model


# ─── Category Mapping ─────────────────────────────────────────────────────────

_CAT_MAP = {
    "uppers": "topwear",
    "lowers": "bottomwear",
    "outerwear": "outerwear",
    "topwear": "topwear",
    "bottomwear": "bottomwear",
}


def _map_cat(cat: str) -> str:
    return _CAT_MAP.get(cat.lower().strip(), "topwear")


# ─── Image Loading Helper ─────────────────────────────────────────────────────

def _load_img(url: str) -> torch.Tensor | None:
    try:
        return load_image_from_url(url).to(_device)
    except Exception as e:
        logger.debug("Image load failed (%s): %s", url[:60], e)
        return None


# ─── Core: Score a single pair ────────────────────────────────────────────────

def score_pair(item_a: dict, item_b: dict) -> float:
    """Score compatibility between two items. Returns float in [-1, 1]."""
    model = get_tacn_model()

    img_a = _load_img(item_a["image_url"])
    img_b = _load_img(item_b["image_url"])
    if img_a is None or img_b is None:
        return 0.0

    cat_a = _map_cat(item_a.get("ai_category") or item_a.get("type", "topwear"))
    cat_b = _map_cat(item_b.get("ai_category") or item_b.get("type", "bottomwear"))

    with torch.no_grad():
        score = model.score_outfit([(img_a, cat_a), (img_b, cat_b)])
    return round(score.item(), 4)


# ─── Case 3: Pre-filter large item sets ──────────────────────────────────────

def prefilter_combinations(
    uppers: list[dict],
    lowers: list[dict],
    top_k: int | None = None,
    threshold: float | None = None,
) -> list[dict]:
    """
    Enumerate upper×lower pairs, score each with TACN, return top-K above threshold.

    Returns: [{"upper": dict, "lower": dict, "tacn_score": float}, ...]
    """
    top_k = top_k or config.TACN_TOP_K
    threshold = threshold if threshold is not None else config.TACN_SCORE_THRESHOLD
    model = get_tacn_model()

    total = len(uppers) * len(lowers)
    logger.info("Pre-filtering %d×%d = %d pairs (top_k=%d)", len(uppers), len(lowers), total, top_k)

    scored = []

    with torch.no_grad():
        for upper in uppers:
            img_u = _load_img(upper["image_url"])
            if img_u is None:
                continue
            cat_u = _map_cat(upper.get("ai_category") or upper.get("type", "uppers"))

            for lower in lowers:
                img_l = _load_img(lower["image_url"])
                if img_l is None:
                    continue
                cat_l = _map_cat(lower.get("ai_category") or lower.get("type", "lowers"))

                s = model.score_outfit([(img_u, cat_u), (img_l, cat_l)]).item()
                if s >= threshold:
                    scored.append({"upper": upper, "lower": lower, "tacn_score": round(s, 4)})

    scored.sort(key=lambda x: x["tacn_score"], reverse=True)
    result = scored[:top_k]
    logger.info("Pre-filter done: %d passed threshold, returning %d", len(scored), len(result))
    return result


# ─── Case 2: Rank catalog pool for auto-suggest ──────────────────────────────

def rank_catalog_pool(
    selected_items: list[dict],
    catalog_pool: list[dict],
    top_k: int | None = None,
) -> list[dict]:
    """
    Rank catalog pool items by avg compatibility with user's selected items.
    Returns top-K pool items with 'tacn_score' field added.
    """
    top_k = top_k or config.TACN_TOP_K
    model = get_tacn_model()

    pool_scores = []

    with torch.no_grad():
        # Pre-load selected images
        sel_loaded = []
        for sel in selected_items:
            img = _load_img(sel["image_url"])
            if img is not None:
                cat = _map_cat(sel.get("ai_category") or sel.get("type", ""))
                sel_loaded.append((img, cat))

        if not sel_loaded:
            return catalog_pool[:top_k]

        for pool_item in catalog_pool:
            img_p = _load_img(pool_item["image_url"])
            if img_p is None:
                continue
            cat_p = _map_cat(pool_item.get("ai_category") or pool_item.get("type", ""))

            pair_scores = []
            for img_s, cat_s in sel_loaded:
                s = model.score_outfit([(img_s, cat_s), (img_p, cat_p)]).item()
                pair_scores.append(s)

            avg = sum(pair_scores) / len(pair_scores)
            pool_scores.append({**pool_item, "tacn_score": round(avg, 4)})

    pool_scores.sort(key=lambda x: x["tacn_score"], reverse=True)
    result = pool_scores[:top_k]
    logger.info("Pool ranking: %d items scored, returning top %d", len(pool_scores), len(result))
    return result


# ─── Case 2 (improved): Per-item pool ranking for auto-suggest ───────────────

def rank_pool_per_selected_item(
    selected_items: list[dict],
    catalog_pool: list[dict],
    pairs_per_item: int = 3,
) -> list[dict]:
    """
    Score each catalog pool item against EACH selected item independently.
    Returns top `pairs_per_item` pool matches for every selected item.

    Returns:
        [
            {
                "selected": item_dict,
                "matches": [{"item": pool_dict, "score": float}, ...]
            },
            ...
        ]
    """
    model = get_tacn_model()
    result = []

    with torch.no_grad():
        # Pre-load all pool images once
        pool_loaded: list[tuple[dict, torch.Tensor, str]] = []
        for pool_item in catalog_pool:
            img = _load_img(pool_item["image_url"])
            if img is not None:
                cat = _map_cat(pool_item.get("ai_category") or pool_item.get("type", ""))
                pool_loaded.append((pool_item, img, cat))

        if not pool_loaded:
            # No images loaded — return raw pool slices
            for sel in selected_items:
                result.append({
                    "selected": sel,
                    "matches": [{"item": p, "score": 0.0} for p in catalog_pool[:pairs_per_item]],
                })
            return result

        for sel in selected_items:
            img_s = _load_img(sel["image_url"])
            if img_s is None:
                result.append({
                    "selected": sel,
                    "matches": [{"item": p, "score": 0.0} for p, _, _ in pool_loaded[:pairs_per_item]],
                })
                continue

            cat_s = _map_cat(sel.get("ai_category") or sel.get("type", ""))
            scores = []
            for pool_item, img_p, cat_p in pool_loaded:
                s = model.score_outfit([(img_s, cat_s), (img_p, cat_p)]).item()
                scores.append({"item": pool_item, "score": round(s, 4)})

            scores.sort(key=lambda x: x["score"], reverse=True)
            result.append({"selected": sel, "matches": scores[:pairs_per_item]})

    logger.info(
        "Per-item pool ranking: %d selected x %d pool -> %d pairs_per_item",
        len(selected_items), len(pool_loaded), pairs_per_item,
    )
    return result


# ─── Case 1 fallback: Full offline recommendation ────────────────────────────

def offline_recommend(items: list[dict], top_k: int = 3) -> list[dict]:
    """
    Generate outfit recommendations using only TACN (no LLM needed).
    Groups items by category, enumerates combos, ranks them.

    Returns: [{"items": [item_dict, ...], "compatibility_score": float, "rank": int}]
    """
    model = get_tacn_model()

    by_cat: dict[str, list[dict]] = {}
    for item in items:
        cat = _map_cat(item.get("ai_category") or item.get("type", "topwear"))
        by_cat.setdefault(cat, []).append(item)

    required = [cat for cat in ["topwear", "bottomwear"] if cat in by_cat]
    if len(required) < 2:
        # Can't compute cross-category scores, return all items as one outfit
        return [{"items": items, "compatibility_score": 0.5, "rank": 1}]

    pools = [by_cat[cat] for cat in required]
    all_combos = list(iter_product(*pools))

    scored = []
    with torch.no_grad():
        for combo in all_combos:
            tensors = []
            valid = True
            for item in combo:
                cat = _map_cat(item.get("ai_category") or item.get("type", ""))
                img = _load_img(item["image_url"])
                if img is None:
                    valid = False
                    break
                tensors.append((img, cat))

            if not valid or len(tensors) < 2:
                continue

            s = model.score_outfit(tensors).item()
            scored.append({"items": list(combo), "compatibility_score": round(s, 4)})

    scored.sort(key=lambda x: x["compatibility_score"], reverse=True)
    top = scored[:top_k]
    for rank, outfit in enumerate(top, start=1):
        outfit["rank"] = rank

    logger.info("Offline recommendation: %d combos scored, returning top %d", len(scored), len(top))
    return top
