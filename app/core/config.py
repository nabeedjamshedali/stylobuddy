import os

from dotenv import load_dotenv

from app.core.logger import get_logger

load_dotenv()
logger = get_logger("config")


class Config:
    # App
    APP_NAME = os.getenv("APP_NAME", "StyLoBuddy")
    DEBUG = False
    ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

    # Database — Supabase PostgreSQL
    DATABASE_URL = os.getenv(
        "DATABASE_URL",
        "postgresql+asyncpg://postgres:password@localhost:5432/stylobuddy",
    )

    # Supabase Storage
    SUPABASE_URL = os.getenv("SUPABASE_URL", "")
    SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")
    # Service role key is needed for backend storage uploads that bypass RLS.
    # Falls back to anon key if not set (only works with public buckets).
    SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_ANON_KEY", "")
    SUPABASE_BUCKET_CLOTHING = os.getenv("SUPABASE_BUCKET_CLOTHING", "clothing-catalog")
    SUPABASE_BUCKET_USER_PHOTOS = os.getenv("SUPABASE_BUCKET_USER_PHOTOS", "user-photos")

    # Core42 Compass OpenAI API
    OPENAI_COMPASS_API_KEY = os.getenv("OPENAI_COMPASS_API_KEY")
    OPENAI_COMPASS_API_URL = os.getenv("OPENAI_COMPASS_API_URL")
    OPENAI_COMPASS_MODEL = os.getenv("OPENAI_COMPASS_MODEL", "gpt-4o")

    # LLM Settings
    LLM_TEMPERATURE = float(os.getenv("LLM_TEMPERATURE", "0.7"))
    LLM_MAX_TOKENS = int(os.getenv("LLM_MAX_TOKENS", "1500"))

    # JWT Auth
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "stylobuddy-secret-change-in-production")
    JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "15"))
    JWT_REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("JWT_REFRESH_TOKEN_EXPIRE_DAYS", "7"))

    # CORS
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")


config = Config()
