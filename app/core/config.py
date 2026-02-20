import os

from dotenv import load_dotenv

from app.core.logger import get_logger

load_dotenv()
logger = get_logger("config")


class Config:
    # App
    APP_NAME = os.getenv("APP_NAME", "StyLoBuddy")
    DEBUG = os.getenv("DEBUG", "false").lower() == "true"
    ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

    # Database
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./stylobuddy.db")

    # Core42 Compass OpenAI API
    OPENAI_COMPASS_API_KEY = os.getenv("OPENAI_COMPASS_API_KEY")
    OPENAI_COMPASS_API_URL = os.getenv("OPENAI_COMPASS_API_URL")
    OPENAI_COMPASS_MODEL = os.getenv("OPENAI_COMPASS_MODEL", "gpt-4o")

    # LLM Settings
    LLM_TEMPERATURE = float(os.getenv("LLM_TEMPERATURE", "0.7"))
    LLM_MAX_TOKENS = int(os.getenv("LLM_MAX_TOKENS", "1024"))

    # Static files
    STATIC_URL = os.getenv("STATIC_URL", "/static")
    IMAGES_DIR = os.getenv("IMAGES_DIR", "static/images")

    # JWT Auth
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "stylobuddy-secret-change-in-production")
    JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "15"))
    JWT_REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("JWT_REFRESH_TOKEN_EXPIRE_DAYS", "7"))

    # CORS
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")


config = Config()
