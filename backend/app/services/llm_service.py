from openai import AsyncOpenAI

from app.core.config import config
from app.core.logger import get_logger

logger = get_logger("llm_service")

# Shared async OpenAI client (reused across services)
client = AsyncOpenAI(
    api_key=config.OPENAI_COMPASS_API_KEY,
    base_url=config.OPENAI_COMPASS_API_URL,
)


def get_client() -> AsyncOpenAI:
    return client
