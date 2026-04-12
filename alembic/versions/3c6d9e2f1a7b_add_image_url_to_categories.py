"""add_image_url_to_categories

Adds optional image_url to catalog_categories and catalog_subcategories
so the frontend can show thumbnails on category tabs and filter chips.

Revision ID: 3c6d9e2f1a7b
Revises: 2a4f8b1c3d5e
Create Date: 2026-04-12
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "3c6d9e2f1a7b"
down_revision: Union[str, None] = "2a4f8b1c3d5e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "catalog_categories",
        sa.Column("image_url", sa.String(500), nullable=True),
    )
    op.add_column(
        "catalog_subcategories",
        sa.Column("image_url", sa.String(500), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("catalog_subcategories", "image_url")
    op.drop_column("catalog_categories", "image_url")
