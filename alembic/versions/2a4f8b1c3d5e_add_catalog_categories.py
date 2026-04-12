"""add_catalog_categories

Redesigns the clothing catalog to support a normalized two-level hierarchy:
  catalog_categories   (Uppers, Lowers, Shoes, Wrist Watch)
  catalog_subcategories (T-Shirts, Jeans, Sneakers, Dress Watches, …)

clothing_items is updated:
  - Drops the denormalized `type` and `category` string columns
  - Adds `subcategory_id` FK → catalog_subcategories
  - Adds `color`, `brand`, `tags`, `is_catalog_item`

Revision ID: 2a4f8b1c3d5e
Revises: 8879a14c0e1f
Create Date: 2026-04-12
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "2a4f8b1c3d5e"
down_revision: Union[str, None] = "8879a14c0e1f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── 1. catalog_categories ─────────────────────────────────────────────────
    op.create_table(
        "catalog_categories",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("slug", sa.String(50), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_catalog_categories_slug"), "catalog_categories", ["slug"], unique=True
    )

    # ── 2. catalog_subcategories ──────────────────────────────────────────────
    op.create_table(
        "catalog_subcategories",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("category_id", sa.String(36), nullable=False),
        sa.Column("slug", sa.String(50), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["category_id"], ["catalog_categories.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "category_id", "slug", name="uq_subcategory_category_slug"
        ),
    )
    op.create_index(
        op.f("ix_catalog_subcategories_category_id"),
        "catalog_subcategories",
        ["category_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_catalog_subcategories_slug"),
        "catalog_subcategories",
        ["slug"],
        unique=False,
    )

    # ── 3. Update clothing_items ──────────────────────────────────────────────
    # Drop old denormalized indexes and columns
    op.drop_index("ix_clothing_items_type", table_name="clothing_items")
    op.drop_index("ix_clothing_items_category", table_name="clothing_items")
    op.drop_column("clothing_items", "type")
    op.drop_column("clothing_items", "category")

    # Add normalized FK
    op.add_column(
        "clothing_items",
        sa.Column("subcategory_id", sa.String(36), nullable=True),
    )
    op.create_foreign_key(
        "fk_clothing_items_subcategory_id",
        "clothing_items",
        "catalog_subcategories",
        ["subcategory_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index(
        op.f("ix_clothing_items_subcategory_id"),
        "clothing_items",
        ["subcategory_id"],
        unique=False,
    )

    # Add new attribute columns
    op.add_column(
        "clothing_items",
        sa.Column("color", sa.String(100), nullable=True),
    )
    op.add_column(
        "clothing_items",
        sa.Column("brand", sa.String(255), nullable=True),
    )
    op.add_column(
        "clothing_items",
        sa.Column("tags", sa.JSON(), nullable=True),
    )
    op.add_column(
        "clothing_items",
        sa.Column(
            "is_catalog_item",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
    )
    op.create_index(
        op.f("ix_clothing_items_is_catalog_item"),
        "clothing_items",
        ["is_catalog_item"],
        unique=False,
    )


def downgrade() -> None:
    # ── Reverse clothing_items changes ────────────────────────────────────────
    op.drop_index("ix_clothing_items_is_catalog_item", table_name="clothing_items")
    op.drop_column("clothing_items", "is_catalog_item")
    op.drop_column("clothing_items", "tags")
    op.drop_column("clothing_items", "brand")
    op.drop_column("clothing_items", "color")

    op.drop_index("ix_clothing_items_subcategory_id", table_name="clothing_items")
    op.drop_constraint(
        "fk_clothing_items_subcategory_id", "clothing_items", type_="foreignkey"
    )
    op.drop_column("clothing_items", "subcategory_id")

    # Restore original denormalized columns
    op.add_column(
        "clothing_items",
        sa.Column("category", sa.String(100), nullable=True),
    )
    op.add_column(
        "clothing_items",
        sa.Column("type", sa.String(20), nullable=True),
    )
    op.create_index(
        "ix_clothing_items_category", "clothing_items", ["category"], unique=False
    )
    op.create_index(
        "ix_clothing_items_type", "clothing_items", ["type"], unique=False
    )

    # ── Drop new category tables ──────────────────────────────────────────────
    op.drop_index("ix_catalog_subcategories_slug", table_name="catalog_subcategories")
    op.drop_index(
        "ix_catalog_subcategories_category_id", table_name="catalog_subcategories"
    )
    op.drop_table("catalog_subcategories")

    op.drop_index("ix_catalog_categories_slug", table_name="catalog_categories")
    op.drop_table("catalog_categories")
