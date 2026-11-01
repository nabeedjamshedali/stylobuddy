from fastapi import Request
from fastapi.responses import JSONResponse

from app.core.logger import get_logger

logger = get_logger("exception_handler")


async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.error("Unhandled exception: %s | Path: %s", str(exc), request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


async def value_error_handler(request: Request, exc: ValueError) -> JSONResponse:
    logger.warning("Validation error: %s | Path: %s", str(exc), request.url.path)
    return JSONResponse(
        status_code=400,
        content={"detail": str(exc)},
    )
