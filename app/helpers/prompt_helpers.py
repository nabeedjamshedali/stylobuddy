def format_wardrobe_for_prompt(items: list[dict]) -> str:
    """Format wardrobe items as compact text for the LLM prompt.

    Each item becomes ~15-20 tokens. For 20 items = ~400 tokens total.
    """
    lines = ["WARDROBE ITEMS:"]
    for item in items:
        desc = item.get("ai_description", item.get("name", "Unknown item"))
        category = item.get("ai_category", "unknown")
        lines.append(f"- [{item['id']}] {desc} | Category: {category}")
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
        "USER SELECTED ITEMS (these MUST appear in every outfit combination):",
    ]
    for item in selected_items:
        desc = item.get("ai_description") or item.get("name", "Unknown")
        cat = item.get("ai_category", "unknown")
        name = item.get("name", "")
        lines.append(f"- [{item['id']}] {name} — {desc} | Category: {cat}")

    lines.append("")
    lines.append(f"CATALOG POOL — available {pool_label} — pick the 3 best matches:")
    for item in catalog_pool:
        desc = item.get("ai_description") or item.get("name", "Unknown")
        cat = item.get("ai_category", "unknown")
        name = item.get("name", "")
        lines.append(f"- [{item['id']}] {name} — {desc} | Category: {cat}")

    if occasion:
        lines.append(f"\nOccasion: {occasion}")
    if preferences:
        lines.append(f"Style preferences: {preferences}")

    lines.append(
        "\nTask: Create exactly 3 outfit combinations ranked best-to-worst. "
        "Each combination must include the user's selected item(s) paired with "
        "a DIFFERENT item from the catalog pool."
    )

    return "\n".join(lines)
