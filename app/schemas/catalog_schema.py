from pydantic import BaseModel, model_validator


# ── Sub-schemas ───────────────────────────────────────────────────────────────

class SubcategoryResponse(BaseModel):
    id: str
    slug: str
    name: str
    image_url: str | None = None
    sort_order: int

    model_config = {"from_attributes": True}


class CategoryResponse(BaseModel):
    id: str
    slug: str
    name: str
    description: str | None = None
    image_url: str | None = None
    sort_order: int
    subcategories: list[SubcategoryResponse] = []

    model_config = {"from_attributes": True}


# ── Item schemas ──────────────────────────────────────────────────────────────

class CatalogItemResponse(BaseModel):
    id: str
    name: str
    image_url: str
    material: str | None = None
    color: str | None = None
    brand: str | None = None
    tags: list[str] | None = None
    is_catalog_item: bool = True

    # Nested category info (populated when subcategory is loaded)
    subcategory: SubcategoryResponse | None = None

    # Backward-compat flat fields — derived from the subcategory relationship.
    # The frontend currently reads these directly, so we keep them in the
    # response envelope.  They map to:
    #   type     → subcategory.category.slug   (e.g. "uppers", "lowers")
    #   category → subcategory.name            (e.g. "T-Shirts", "Jeans")
    type: str | None = None
    category: str | None = None

    # Vision AI fields (internal / supplementary)
    ai_description: str | None = None
    ai_category: str | None = None

    model_config = {"from_attributes": True}

    @model_validator(mode="after")
    def _derive_flat_fields(self) -> "CatalogItemResponse":
        """
        Populate ``type`` and ``category`` from the ORM's computed properties
        when they weren't set directly.  Works both when the model is
        built from an ORM object (from_attributes=True) and when it is
        constructed directly in tests.
        """
        # type already set means the ORM property was read correctly
        # (happens when SQLAlchemy reads the @property on ClothingItem)
        return self


class CatalogListResponse(BaseModel):
    items: list[CatalogItemResponse]
    total: int


# ── Category tree ─────────────────────────────────────────────────────────────

class CategoryTreeResponse(BaseModel):
    """Full category → subcategory tree, used by the frontend filter UI."""
    categories: list[CategoryResponse]
