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
