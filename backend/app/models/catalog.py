import uuid
from datetime import datetime

from sqlalchemy import String, Text, Integer, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class CatalogCategory(Base):
    """
    Top-level clothing category.
    Seeded values: Uppers, Lowers, Shoes, Wrist Watch.

    New categories can be added by inserting rows — no code change required.
    """

    __tablename__ = "catalog_categories"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    # URL-safe identifier used by the frontend and API filters.
    # e.g. "uppers", "lowers", "shoes", "watches"
    slug: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Representative thumbnail shown on category cards / tab headers.
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    # Controls display order in the UI (ascending).
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Subcategories are loaded automatically via selectin so callers don't
    # have to think about eager-loading.
    subcategories: Mapped[list["CatalogSubcategory"]] = relationship(
        back_populates="category",
        order_by="CatalogSubcategory.sort_order",
        lazy="selectin",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<CatalogCategory slug={self.slug!r}>"


class CatalogSubcategory(Base):
    """
    Subcategory that sits inside a CatalogCategory.

    Examples
    --------
    Uppers  → T-Shirts, Shirts, Knitwear, Jackets, Hoodies
    Lowers  → Jeans, Trousers, Chinos, Shorts
    Shoes   → Sneakers, Boots, Loafers, Formal Shoes, Sandals
    Watches → Casual, Dress, Sport
    """

    __tablename__ = "catalog_subcategories"
    __table_args__ = (
        # Each slug must be unique within its parent category.
        UniqueConstraint("category_id", "slug", name="uq_subcategory_category_slug"),
    )

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    category_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("catalog_categories.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # URL-safe identifier, e.g. "t-shirts", "sneakers", "dress-watches"
    slug: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    # Representative thumbnail shown on filter chips / subcategory cards.
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Parent category is always loaded with the subcategory row.
    category: Mapped["CatalogCategory"] = relationship(
        back_populates="subcategories",
        lazy="selectin",
    )
    clothing_items: Mapped[list["ClothingItem"]] = relationship(  # type: ignore[name-defined]
        back_populates="subcategory",
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<CatalogSubcategory slug={self.slug!r}>"
