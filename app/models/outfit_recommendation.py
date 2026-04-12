import uuid
from datetime import datetime

from sqlalchemy import String, Integer, Boolean, JSON, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class OutfitRecommendation(Base):
    __tablename__ = "outfit_recommendations"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    input_item_ids: Mapped[list] = mapped_column(JSON, nullable=False)
    occasion: Mapped[str | None] = mapped_column(String(100), nullable=True)
    recommendation_payload: Mapped[dict] = mapped_column(JSON, nullable=False)
    prompt_version: Mapped[str] = mapped_column(String(50), nullable=False)
    llm_model: Mapped[str] = mapped_column(String(100), nullable=False)
    token_usage: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # Whether the user explicitly saved this look (shown on /saved page)
    is_saved: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="recommendations")
