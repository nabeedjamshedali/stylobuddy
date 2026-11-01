import uuid
from datetime import datetime

from sqlalchemy import String, Text, DateTime, Boolean, ForeignKey, JSON, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class ClothingItem(Base):
    """
    A single garment or accessory that can appear in the catalog or a user's
    personal wardrobe.

    Category hierarchy
    ------------------
    Every item optionally links to a CatalogSubcategory row, which in turn
    links to a CatalogCategory.  The ``type`` and ``category`` computed
    properties surface these relationships for the API without storing
    redundant string columns in the database.

    is_catalog_item
    ---------------
    True  → seeded / admin-managed catalog entry (shown in the explore grid)
    False → uploaded by a specific user (private wardrobe photo)
    """

    __tablename__ = "clothing_items"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    image_url: Mapped[str] = mapped_column(String(500), nullable=False)

    # ── Normalized category FK ────────────────────────────────────────────────
    # Nullable so existing rows survive a migration before backfilling.
    # SET NULL on delete keeps the item if its subcategory is removed.
    subcategory_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("catalog_subcategories.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    # ── Item attributes ───────────────────────────────────────────────────────
    material: Mapped[str | None] = mapped_column(String(255), nullable=True)
    color: Mapped[str | None] = mapped_column(String(100), nullable=True)
    brand: Mapped[str | None] = mapped_column(String(255), nullable=True)
    # Free-form style tags, e.g. ["minimalist", "workwear", "casual"]
    tags: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)

    # ── Source tracking ───────────────────────────────────────────────────────
    is_catalog_item: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, index=True
    )

    # ── Vision AI analysis ────────────────────────────────────────────────────
    # Populated once per image by VisionService.
    ai_description: Mapped[str | None] = mapped_column(Text, nullable=True)
    # LLM category label: topwear | bottomwear | footwear | accessory | outerwear | ethnic
    ai_category: Mapped[str | None] = mapped_column(
        String(50), nullable=True, index=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # ── Relationships ─────────────────────────────────────────────────────────
    # selectin keeps the subcategory (and its parent category) in sync with
    # every query that returns ClothingItem rows, at the cost of two extra
    # batch SELECTs — acceptable for catalog-scale data sets.
    subcategory: Mapped["CatalogSubcategory | None"] = relationship(  # type: ignore[name-defined]
        "CatalogSubcategory",
        back_populates="clothing_items",
        lazy="selectin",
    )
    wardrobe_entries: Mapped[list["UserWardrobe"]] = relationship(  # type: ignore[name-defined]
        back_populates="clothing_item", cascade="all, delete-orphan"
    )

    # ── Backward-compat computed properties ──────────────────────────────────
    # These let the existing API response schema remain unchanged while the
    # underlying storage is now fully normalized.

    @property
    def type(self) -> str | None:
        """Top-level category slug, e.g. 'uppers', 'lowers', 'shoes', 'watches'."""
        if self.subcategory is not None and self.subcategory.category is not None:
            return self.subcategory.category.slug
        return None

    @property
    def category(self) -> str | None:
        """Subcategory display name, e.g. 'T-Shirts', 'Jeans', 'Sneakers'."""
        if self.subcategory is not None:
            return self.subcategory.name
        return None
