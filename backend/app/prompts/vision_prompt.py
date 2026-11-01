PROMPT_VERSION = "v1.0"

VISION_ANALYSIS_PROMPT = """Analyze this clothing item image. Return a JSON object with exactly these two fields:

1. "description": A concise description (15-25 words max) covering: clothing type, color, pattern, material if visible, and style.
   Example: "Navy blue cotton polo shirt, solid pattern, casual style, suitable for summer"

2. "category": Exactly one of these values: topwear, bottomwear, footwear, accessory, outerwear, ethnic

Return ONLY valid JSON. No extra text."""
