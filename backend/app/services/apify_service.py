"""
Apify-based Pinterest trend scraper for the Explore page.

Actor: automation-lab/pinterest-scraper
Docs: https://apify.com/automation-lab/pinterest-scraper
Pricing: pay-per-use $0.003/pin — no rental required

Architecture:
- Results are cached in-memory for 24 hours.
- On first call (empty cache) the endpoint returns seed data immediately and
  kicks off a background fetch. Once Apify responds the cache is populated
  and all subsequent calls are served instantly.
- On cache expiry the same background-refresh pattern repeats.
"""

import asyncio
import time
from typing import Any

import httpx

from app.core.config import config
from app.core.logger import get_logger

logger = get_logger("apify")

# ── Constants ─────────────────────────────────────────────────────────────────

CACHE_TTL_SECONDS = config.APIFY_CACHE_TTL_SECONDS
APIFY_BASE        = config.APIFY_BASE_URL
ACTOR_ID          = config.APIFY_ACTOR_ID

# Search keywords per gender passed to the actor's `searchQueries` array
GENDER_SEARCHES: dict[str, list[str]] = {
    "men": [
        "men outfit ideas 2025",
        "mens streetwear casual",
    ],
    "women": [
        "women outfit ideas 2025",
        "womens streetwear fashion",
    ],
}

MAX_PINS_PER_SEARCH = 12   # 2 searches × 2 genders = ~48 pins total (~$0.14 per refresh)

# ── In-memory cache ───────────────────────────────────────────────────────────

_cache: dict[str, Any] = {
    "items":       [],    # list[dict]
    "fetched_at":  0.0,   # unix timestamp of last successful fetch
    "is_fetching": False, # prevents concurrent refreshes
}

# ── Public API ────────────────────────────────────────────────────────────────

async def get_trending_looks(gender: str = "all") -> list[dict]:
    """
    Return trending Pinterest outfit pins, optionally filtered by gender
    ('men' | 'women' | 'all').  Triggers a background cache refresh when stale.
    """
    now         = time.time()
    cache_stale = (now - _cache["fetched_at"]) > CACHE_TTL_SECONDS

    if (cache_stale or not _cache["items"]) and not _cache["is_fetching"]:
        asyncio.create_task(_refresh_cache())

    items = _cache["items"]
    if gender != "all":
        items = [i for i in items if i.get("gender") == gender]
    return items


async def warm_cache() -> None:
    """Call once on startup to pre-populate the cache (non-blocking background task)."""
    if not _cache["items"]:
        await _refresh_cache()


# ── Cache refresh ─────────────────────────────────────────────────────────────

async def _refresh_cache() -> None:
    if _cache["is_fetching"]:
        return
    _cache["is_fetching"] = True
    logger.info("Apify cache refresh started")

    try:
        items: list[dict] = []
        # Use a single long-lived client for all requests in this refresh cycle
        async with httpx.AsyncClient(timeout=180.0) as client:
            for gender, searches in GENDER_SEARCHES.items():
                for keyword in searches:
                    pins = await _search_pinterest(client, keyword, gender)
                    items.extend(pins)
                    logger.info(
                        "Apify [%s] search='%s' -> %d pins", gender, keyword, len(pins)
                    )

        if items:
            _cache["items"]      = _dedupe(items)
            _cache["fetched_at"] = time.time()
            logger.info("Apify cache updated: %d pins total", len(_cache["items"]))
        else:
            logger.warning("Apify returned 0 pins — keeping previous cache")
    except Exception as exc:
        logger.error("Apify cache refresh failed: %s", exc)
    finally:
        _cache["is_fetching"] = False


# ── Apify API call ────────────────────────────────────────────────────────────

async def _search_pinterest(
    client: httpx.AsyncClient,
    keyword: str,
    gender: str,
) -> list[dict]:
    """
    Run automation-lab/pinterest-scraper synchronously.

    Input schema (https://apify.com/automation-lab/pinterest-scraper):
      searchQueries : list[str] — Pinterest keyword search terms
      maxPins       : int       — max pins to return (default 50, max 1000)
      proxy         : dict      — proxy config; {useApifyProxy: true} is sufficient
    """
    if not config.APIFY_API_TOKEN:
        logger.warning("APIFY_API_TOKEN not set — skipping Apify fetch")
        return []

    endpoint = f"{APIFY_BASE}/acts/{ACTOR_ID}/run-sync-get-dataset-items"
    params   = {"token": config.APIFY_API_TOKEN}

    payload = {
        "searchQueries": [keyword],
        "maxPins":       MAX_PINS_PER_SEARCH,
        "proxy": {
            "useApifyProxy": True,
        },
    }

    try:
        resp = await client.post(endpoint, params=params, json=payload)

        if not resp.is_success:
            logger.error(
                "Apify HTTP %s for keyword='%s': %s",
                resp.status_code, keyword, resp.text[:500],
            )
            return []

        raw: list[dict] = resp.json()
        logger.info("Apify raw items for '%s': %d", keyword, len(raw))
        return [_map_pin(pin, gender) for pin in raw if _has_image(pin)]

    except httpx.TimeoutException:
        logger.error("Apify timeout for keyword='%s'", keyword)
        return []
    except Exception as exc:
        logger.error("Apify unexpected error for keyword='%s': %s", keyword, exc)
        return []


def _has_image(pin: dict) -> bool:
    return bool(pin.get("imageUrl") or pin.get("thumbnailUrl"))


def _extract_image(pin: dict) -> str:
    return pin.get("imageUrl") or pin.get("thumbnailUrl") or ""


def _map_pin(pin: dict, gender: str) -> dict:
    """Map an automation-lab Pinterest pin to our ExploreItem dict shape."""
    title       = (pin.get("title") or "").strip()
    description = (pin.get("description") or pin.get("altText") or "").strip()

    # Use description as title if title is empty
    if not title and description:
        title = description[:80]
    if not title:
        title = "Trending Look"

    hashtags: list[str] = pin.get("hashtags") or []

    saves = pin.get("saves") or 0

    style_category = _classify(title, description, " ".join(hashtags))

    return {
        "id":             str(pin.get("id") or ""),
        "title":          title,
        "description":    description,
        "gender":         gender,
        "category":       style_category,
        "image_url":      _extract_image(pin),
        "source_url":     pin.get("url") or "",
        "dominant_color": pin.get("dominantColor") or "",
        "saves":          int(saves) if isinstance(saves, (int, float)) else 0,
        "hashtags":       [h.lstrip("#") for h in hashtags][:5],
    }


def _classify(title: str, description: str, pin_category: str) -> str:
    text = (title + " " + description + " " + pin_category).lower()
    if any(w in text for w in ["suit", "formal", "blazer", "office", "gala", "tuxedo"]):
        return "Formal"
    if any(w in text for w in ["street", "hype", "urban", "cargo", "hoodie", "skate"]):
        return "Streetwear"
    if any(w in text for w in ["minimal", "clean", "simple", "mono", "tonal"]):
        return "Minimalist"
    if any(w in text for w in ["casual", "everyday", "weekend", "relax", "jeans"]):
        return "Casual"
    return "Smart Casual"


def _dedupe(items: list[dict]) -> list[dict]:
    seen: set[str] = set()
    out:  list[dict] = []
    for item in items:
        key = item.get("image_url", "")
        if key and key not in seen:
            seen.add(key)
            out.append(item)
    return out
