def format_wardrobe_for_prompt(items: list[dict]) -> str:
    """Format wardrobe items as compact text for the LLM prompt.

    Each item becomes ~15-20 tokens. For 20 items = ~400 tokens total.
    """
    lines = ["WARDROBE ITEMS:"]
    for item in items:
        desc = item.get("ai_description") or item.get("name") or "Unknown item"
        category = item.get("ai_category") or item.get("type") or "unknown"
        name = item.get("name", "")
        color = item.get("color", "")
        material = item.get("material", "")
        extra = f" ({color}, {material})" if color and material else ""
        lines.append(f"- [{item['id']}] {name}{extra} — {desc} | Category: {category}")
    return "\n".join(lines)


def format_auto_suggest_prompt(
    selected_items: list[dict],
    catalog_pool: list[dict],
    suggest_mode: str,  # 'lowers' | 'uppers'
    occasion: str | None = None,
    preferences: str | None = None,
) -> str:
    """Build the user-turn prompt for auto-suggest mode.

    selected_items  — items the user explicitly chose (must appear in every combo).
    catalog_pool    — candidate items from the complementary category.
    suggest_mode    — 'lowers' (user picked uppers) or 'uppers' (user picked lowers).
    """
    if suggest_mode == "lowers":
        pool_label = "BOTTOM pieces from catalog (trousers / jeans / shorts / skirts)"
    else:
        pool_label = "TOP pieces from catalog (shirts / t-shirts / sweatshirts)"

    lines = [
        f"USER SELECTED ITEMS ({len(selected_items)} items — you MUST recommend pairings for EVERY item below, do NOT skip any):",
    ]
    for item in selected_items:
        desc = item.get("ai_description") or item.get("name", "Unknown")
        cat = item.get("ai_category") or item.get("type") or "unknown"
        name = item.get("name", "")
        color = item.get("color", "")
        material = item.get("material", "")
        extra = f" ({color}, {material})" if color and material else ""
        lines.append(f"- [{item['id']}] {name}{extra} — {desc} | Category: {cat}")

    lines.append("")
    lines.append(f"CATALOG POOL — available {pool_label} — pick the best matches:")
    for item in catalog_pool:
        desc = item.get("ai_description") or item.get("name", "Unknown")
        cat = item.get("ai_category") or item.get("type") or "unknown"
        name = item.get("name", "")
        color = item.get("color", "")
        material = item.get("material", "")
        extra = f" ({color}, {material})" if color and material else ""
        lines.append(f"- [{item['id']}] {name}{extra} — {desc} | Category: {cat}")

    if occasion:
        lines.append(f"\nOccasion: {occasion}")
    if preferences:
        lines.append(f"Style preferences: {preferences}")

    lines.append(
        f"\nTask: Create up to 5 outfit combinations ranked best-to-worst. "
        f"Each combination pairs ONE user-selected item with ONE catalog pool item. "
        f"STRICT RULES: "
        f"(1) Every user-selected item MUST appear in at least one combination. "
        f"(2) No single user-selected item may appear in MORE THAN 2 combinations — "
        f"spread pairings across all {len(selected_items)} selected items. "
        f"(3) Use a DIFFERENT catalog pool item in each combination."
    )

    return "\n".join(lines)
