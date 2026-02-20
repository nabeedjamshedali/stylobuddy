import os
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import config
from app.core.database import init_db, close_db
from app.core.logger import get_logger
from app.exceptions.handlers import generic_exception_handler, value_error_handler
from app.middlewares.logging_middleware import LoggingMiddleware
from app.routes.catalog_routes import router as catalog_router
from app.routes.wardrobe_routes import router as wardrobe_router
from app.routes.recommendation_routes import router as recommendation_router
from app.routes.auth_routes import router as auth_router

logger = get_logger("main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting %s...", config.APP_NAME)
    await init_db()

    # Ensure static images directory exists
    os.makedirs(config.IMAGES_DIR, exist_ok=True)

    yield

    logger.info("Shutting down %s...", config.APP_NAME)
    await close_db()


app = FastAPI(
    title=config.APP_NAME,
    description="AI-Powered Outfit Recommendation API",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS
origins = config.CORS_ORIGINS.split(",") if config.CORS_ORIGINS != "*" else ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Logging middleware
app.add_middleware(LoggingMiddleware)

# Exception handlers
app.add_exception_handler(Exception, generic_exception_handler)
app.add_exception_handler(ValueError, value_error_handler)

# Static files (clothing images)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Routes
app.include_router(auth_router)
app.include_router(catalog_router)
app.include_router(wardrobe_router)
app.include_router(recommendation_router)


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy", "app": config.APP_NAME}


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="127.0.0.1",
        port=8000,
        reload=True,
        timeout_keep_alive=30,
    )
