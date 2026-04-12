"""
Seed the clothing catalog with dummy data covering all four main categories.

What this script does
─────────────────────
1. Upserts the 4 top-level CatalogCategory rows.
2. Upserts all CatalogSubcategory rows (17 subcategories total).
3. For each ClothingItem entry:
   a. Downloads the image from its source URL.
   b. Uploads it to the Supabase Storage "clothing-catalog" bucket.
   c. Inserts (or skips if already present) a ClothingItem row linked to
      the correct subcategory.
   d. Runs Vision-AI analysis to populate ai_description + ai_category.

Category structure
──────────────────
  Uppers   → T-Shirts · Shirts · Knitwear · Jackets · Hoodies
  Lowers   → Jeans · Trousers · Chinos · Shorts
  Shoes    → Sneakers · Boots · Loafers · Formal Shoes · Sandals
  Watches  → Casual · Dress · Sport

Usage
─────
    python -m scripts.seed_catalog

    # Skip Vision AI (faster, useful when API key is not set):
    python -m scripts.seed_catalog --no-vision

    # Re-upload even if the item already exists in the DB:
    python -m scripts.seed_catalog --force
"""

import argparse
import asyncio
import os
import sys
import uuid

import httpx

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select

from app.core.database import async_session_factory, init_db
from app.core.logger import get_logger
from app.models.catalog import CatalogCategory, CatalogSubcategory
from app.models.clothing_item import ClothingItem
from app.services.storage_service import upload_clothing_image
from app.services.vision_service import VisionService

logger = get_logger("seed_catalog")

# ── Category & subcategory definitions ───────────────────────────────────────

CATEGORIES: list[dict] = [
    {
        "slug": "uppers", "name": "Uppers", "sort_order": 1,
        "description": "Tops, shirts, jackets and knitwear",
        # Representative image — Classic White Tee
        "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCK33WoXw1FTDfIgyBRxxMqkGKiiS-Hv1eSrkUSY50ksu2QDFesxhcp0Mi1J7UoouiZnJqPATPZHnZ2HuvCs0Nuij6oWXv8Fc2LIrHscTMBcHxFDTZkRXOP8o58gqWhjf_x3ddrvzLjrT-FQyYttblCJh2xScLi-kHuMYQz8YBZcutH3mJNqriqOWeNhaJGksysXD77fumBHfbOMl3D44hja3DGaqNmWhElMQyARnX7J779KFXLUBT3fVAs2CCYW6T5ZnSTAl2Br_Me",
    },
    {
        "slug": "lowers", "name": "Lowers", "sort_order": 2,
        "description": "Trousers, jeans, shorts and chinos",
        # Representative image — Straight Leg Denim
        "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDS8_1Q6adlNGkunic8xUPDpVSbhoiNThDV6X1CWrFa9C7jk9QC1oY_XkVKmARa-h_GxdMMeosyhAAvh0jJz1os0F1TaiTsNa75GnU7zFqD7u7TexkPWqDSPkHUAkIEnlBFN4O3sR8dUA-p5GMYTYeC4dWHSuMh7djsuDGGX26U7Z-UDT1zrJOzs5Lqt9L2esE4miD3Kso6gIcjWjPuNLFgC9m5Ap-3LAN_u3bK9HtPw52opHHIj0HzNhFC-vHUV1dSAKYR7riWUsvJ",
    },
    {
        "slug": "shoes", "name": "Shoes", "sort_order": 3,
        "description": "Sneakers, boots, loafers and more",
        # Representative image — White Canvas Low-Tops
        "image_url": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=800&fit=crop&q=80",
    },
    {
        "slug": "watches", "name": "Wrist Watch", "sort_order": 4,
        "description": "Casual, dress and sport timepieces",
        # Representative image — Slim Silver Dress Watch
        "image_url": "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&h=800&fit=crop&q=80",
    },
]

SUBCATEGORIES: dict[str, list[dict]] = {
    "uppers": [
        {"slug": "t-shirts", "name": "T-Shirts", "sort_order": 1,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCK33WoXw1FTDfIgyBRxxMqkGKiiS-Hv1eSrkUSY50ksu2QDFesxhcp0Mi1J7UoouiZnJqPATPZHnZ2HuvCs0Nuij6oWXv8Fc2LIrHscTMBcHxFDTZkRXOP8o58gqWhjf_x3ddrvzLjrT-FQyYttblCJh2xScLi-kHuMYQz8YBZcutH3mJNqriqOWeNhaJGksysXD77fumBHfbOMl3D44hja3DGaqNmWhElMQyARnX7J779KFXLUBT3fVAs2CCYW6T5ZnSTAl2Br_Me"},
        {"slug": "shirts", "name": "Shirts", "sort_order": 2,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDfv6avVvhh1tpVlUxrVmLvkAvEmTGD3wbCjAzQC0dsEF86BVTUto20SCsPc4jETxFsVL2B_hDNDa0HnCz_HkcXGq9xw0ijBF29xNBX3aFOM5HaqtoUdRQuAZs58z_HInWKknXXd2QXK8c1Gc3aI0D0b2PslCE0NYNgq7as2yu6yLVj1P4M9F97xRjwuliXeRPuGd0rhxzXaedhHWL5bL0ZNr-cJQFr3cdQeKWq4xpflf6ph7velEDBbnR24Ltkgt0Kz4-0TKEZqv1d"},
        {"slug": "knitwear", "name": "Knitwear", "sort_order": 3,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCQevpDfeOhkaOF7qff6q3ZcNCIPEpMAhgBHCINe_00ApoCnLnu_2Va6vT_gjSZqCUL7F7NupQ5WWeewBjguersBvRrdwpW1Mok40vc3EGNWlRnUQinVABpkWdWoRYA5-WEf_39D--SZkpmXCdnUBuMKnetJIedMaDc7HRVIj19ckY95jHoDNtu0f-3Hy8BBaukz5OUdpDNo426uAn2HNQh9mBb86cPlxP3KMF-D0VUtkdpneS1zHMslO9Wh3MgedNJprDZlQHfOmWN"},
        {"slug": "jackets", "name": "Jackets", "sort_order": 4,
         "image_url": "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&h=800&fit=crop&q=80"},
        {"slug": "hoodies", "name": "Hoodies", "sort_order": 5,
         "image_url": "https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=600&h=800&fit=crop&q=80"},
    ],
    "lowers": [
        {"slug": "jeans", "name": "Jeans", "sort_order": 1,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDS8_1Q6adlNGkunic8xUPDpVSbhoiNThDV6X1CWrFa9C7jk9QC1oY_XkVKmARa-h_GxdMMeosyhAAvh0jJz1os0F1TaiTsNa75GnU7zFqD7u7TexkPWqDSPkHUAkIEnlBFN4O3sR8dUA-p5GMYTYeC4dWHSuMh7djsuDGGX26U7Z-UDT1zrJOzs5Lqt9L2esE4miD3Kso6gIcjWjPuNLFgC9m5Ap-3LAN_u3bK9HtPw52opHHIj0HzNhFC-vHUV1dSAKYR7riWUsvJ"},
        {"slug": "trousers", "name": "Trousers", "sort_order": 2,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuA1vjQCNS8wOTQFSqkuOLMYHED5_pJGzm0QMLAuSSa_vNXjRnEgiMhKztwh5xdb4iMuQVp6bDXJDVXewMnMIZpKY4F-hnijfB8afF3EiJzx94lLdtmhSZN0nzij1dCrWL43Pevx2g_6D7cNg0vnbzrvF8MVDfUk6mbIp_L_Vk6vLsiZTRuPYuiVZsKwzBdI431F0iWEo_6YNhyLywx5ZCud-Bf7X7Q3l9t9Gv-ujwZQBoPULg9OF034wlmE-EmS4fx70cv71aUvGTdD"},
        {"slug": "chinos", "name": "Chinos", "sort_order": 3,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCvoU6IY_XC238MVjMw68Z-bhdfIKy5fIplVcAJDUKrn4Tt5E7IHnSQ6H16uOSfPXpqpdg8am4H9llT92GVCiKMnHhPu9LP-cwfhcZHklluKJe7C1JaJpgNRAcoY_QynJ-PCEaGN2cAnvoKbvfCK4a8Hlvsv2UCcOz6VXn0stdM6z8JvDk7C8vsfyUnnNyNLq2r2rJ_Lr2QMDTSrgRE97yu7WhC_53Pt5FzpvAZcUu13lKpyqjR-_AyzL_by6uXsrZ-hfsR8j6j6Ths"},
        {"slug": "shorts", "name": "Shorts", "sort_order": 4,
         "image_url": "https://images.unsplash.com/photo-1562157873-818bc0726f68?w=600&h=800&fit=crop&q=80"},
    ],
    "shoes": [
        {"slug": "sneakers", "name": "Sneakers", "sort_order": 1,
         "image_url": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=800&fit=crop&q=80"},
        {"slug": "boots", "name": "Boots", "sort_order": 2,
         "image_url": "https://images.unsplash.com/photo-1605812860427-4024433a70fd?w=600&h=800&fit=crop&q=80"},
        {"slug": "loafers", "name": "Loafers", "sort_order": 3,
         "image_url": "https://images.unsplash.com/photo-1626947346165-4c2288dadc2a?w=600&h=800&fit=crop&q=80"},
        {"slug": "formal-shoes", "name": "Formal Shoes", "sort_order": 4,
         "image_url": "https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=600&h=800&fit=crop&q=80"},
        {"slug": "sandals", "name": "Sandals", "sort_order": 5,
         "image_url": "https://images.unsplash.com/photo-1603487742131-4160ec999306?w=600&h=800&fit=crop&q=80"},
    ],
    "watches": [
        {"slug": "casual-watches", "name": "Casual", "sort_order": 1,
         "image_url": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&h=800&fit=crop&q=80"},
        {"slug": "dress-watches", "name": "Dress", "sort_order": 2,
         "image_url": "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&h=800&fit=crop&q=80"},
        {"slug": "sport-watches", "name": "Sport", "sort_order": 3,
         "image_url": "https://images.unsplash.com/photo-1585386959984-a4155224a1ad?w=600&h=800&fit=crop&q=80"},
    ],
}

# ── Clothing items ────────────────────────────────────────────────────────────
# Each entry must have:
#   category_slug    → matches a key in SUBCATEGORIES
#   subcategory_slug → matches a slug inside that category's list
#   name, material, color, tags, filename, url
#
# Image URLs are sourced from:
#   • lh3.googleusercontent.com  — the original 9 items (preserved exactly)
#   • images.unsplash.com        — free stock photos for the new items
#
# All images are re-uploaded to Supabase Storage on first run so the app
# never depends on third-party URLs at runtime.

CATALOG_ITEMS: list[dict] = [

    # ── Uppers / T-Shirts ─────────────────────────────────────────────────────
    {
        "name": "Classic White Tee",
        "category_slug": "uppers", "subcategory_slug": "t-shirts",
        "material": "Premium Cotton", "color": "White",
        "tags": ["minimalist", "essential", "casual"],
        "filename": "classic_white_tee.jpg",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCK33WoXw1FTDfIgyBRxxMqkGKiiS-Hv1eSrkUSY50ksu2QDFesxhcp0Mi1J7UoouiZnJqPATPZHnZ2HuvCs0Nuij6oWXv8Fc2LIrHscTMBcHxFDTZkRXOP8o58gqWhjf_x3ddrvzLjrT-FQyYttblCJh2xScLi-kHuMYQz8YBZcutH3mJNqriqOWeNhaJGksysXD77fumBHfbOMl3D44hja3DGaqNmWhElMQyARnX7J779KFXLUBT3fVAs2CCYW6T5ZnSTAl2Br_Me",
    },
    {
        "name": "Ribbed Long Sleeve",
        "category_slug": "uppers", "subcategory_slug": "t-shirts",
        "material": "Cotton Rib", "color": "Cream",
        "tags": ["layering", "minimal", "casual"],
        "filename": "ribbed_long_sleeve.jpg",
        "url": "https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600&h=800&fit=crop&q=80",
    },
    {
        "name": "Washed Olive Tee",
        "category_slug": "uppers", "subcategory_slug": "t-shirts",
        "material": "Slub Jersey", "color": "Olive",
        "tags": ["casual", "earthy", "relaxed"],
        "filename": "washed_olive_tee.jpg",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuABPULg2DKUqxYUiZ1a3qzTajnUcznHn9aNqr75Fe-aT6UR1UV7AhA2Ufmc74C0DOXYsURQQ5_48ixPzWfviDDted-H9aoYFu6Lx1rd8_dseLInh0oBvzZaqR0qbsoMBT0YU9IA4H7eFzjXlmpXwqEb4D_eBOslCjBs-cFnbeaEpTHvUaa9QUfB6CjwsF_sucv7r9VEAllVKuA9Nqy09R0Fwc2iW4v44O8PDYydIoRW5O1uXm9bFrQP5HqSWtiE-A1_Xa4NMojcJdT8",
    },
    {
        "name": "Black Crew Neck Tee",
        "category_slug": "uppers", "subcategory_slug": "t-shirts",
        "material": "Organic Cotton", "color": "Black",
        "tags": ["essential", "minimalist", "versatile"],
        "filename": "black_crew_neck_tee.jpg",
        "url": "https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=600&h=800&fit=crop&q=80",
    },
    {
        "name": "Navy Pocket Tee",
        "category_slug": "uppers", "subcategory_slug": "t-shirts",
        "material": "Slub Cotton", "color": "Navy",
        "tags": ["casual", "classic", "weekend"],
        "filename": "navy_pocket_tee.jpg",
        "url": "https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=600&h=800&fit=crop&q=80",
    },

    # ── Uppers / Shirts ───────────────────────────────────────────────────────
    {
        "name": "Linen Overshirt",
        "category_slug": "uppers", "subcategory_slug": "shirts",
        "material": "Belgian Linen", "color": "Sand",
        "tags": ["relaxed", "summer", "layering"],
        "filename": "linen_overshirt.jpg",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDfv6avVvhh1tpVlUxrVmLvkAvEmTGD3wbCjAzQC0dsEF86BVTUto20SCsPc4jETxFsVL2B_hDNDa0HnCz_HkcXGq9xw0ijBF29xNBX3aFOM5HaqtoUdRQuAZs58z_HInWKknXXd2QXK8c1Gc3aI0D0b2PslCE0NYNgq7as2yu6yLVj1P4M9F97xRjwuliXeRPuGd0rhxzXaedhHWL5bL0ZNr-cJQFr3cdQeKWq4xpflf6ph7velEDBbnR24Ltkgt0Kz4-0TKEZqv1d",
    },
    {
        "name": "Oxford Button-Down",
        "category_slug": "uppers", "subcategory_slug": "shirts",
        "material": "Oxford Cloth", "color": "Light Blue",
        "tags": ["smart-casual", "workwear", "classic"],
        "filename": "oxford_button_down.jpg",
        "url": "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=600&h=800&fit=crop&q=80",
    },
    {
        "name": "Flannel Plaid Shirt",
        "category_slug": "uppers", "subcategory_slug": "shirts",
        "material": "Brushed Flannel", "color": "Red/Navy Plaid",
        "tags": ["casual", "autumn", "rugged"],
        "filename": "flannel_plaid_shirt.jpg",
        "url": "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&h=800&fit=crop&q=80",
    },

    # ── Uppers / Knitwear ─────────────────────────────────────────────────────
    {
        "name": "Merino Turtleneck",
        "category_slug": "uppers", "subcategory_slug": "knitwear",
        "material": "Fine Merino Wool", "color": "Charcoal",
        "tags": ["minimalist", "smart-casual", "autumn"],
        "filename": "merino_turtleneck.jpg",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCQevpDfeOhkaOF7qff6q3ZcNCIPEpMAhgBHCINe_00ApoCnLnu_2Va6vT_gjSZqCUL7F7NupQ5WWeewBjguersBvRrdwpW1Mok40vc3EGNWlRnUQinVABpkWdWoRYA5-WEf_39D--SZkpmXCdnUBuMKnetJIedMaDc7HRVIj19ckY95jHoDNtu0f-3Hy8BBaukz5OUdpDNo426uAn2HNQh9mBb86cPlxP3KMF-D0VUtkdpneS1zHMslO9Wh3MgedNJprDZlQHfOmWN",
    },
    {
        "name": "Chunky Ribbed Sweater",
        "category_slug": "uppers", "subcategory_slug": "knitwear",
        "material": "Wool Blend", "color": "Oatmeal",
        "tags": ["cosy", "winter", "oversized"],
        "filename": "chunky_ribbed_sweater.jpg",
        "url": "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=600&h=800&fit=crop&q=80",
    },

    # ── Uppers / Jackets ──────────────────────────────────────────────────────
    {
        "name": "Leather Biker Jacket",
        "category_slug": "uppers", "subcategory_slug": "jackets",
        "material": "Genuine Leather", "color": "Black",
        "tags": ["edgy", "streetwear", "statement"],
        "filename": "leather_biker_jacket.jpg",
        "url": "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&h=800&fit=crop&q=80",
    },
    {
        "name": "Denim Trucker Jacket",
        "category_slug": "uppers", "subcategory_slug": "jackets",
        "material": "12oz Denim", "color": "Mid Wash Blue",
        "tags": ["casual", "layering", "american-classic"],
        "filename": "denim_trucker_jacket.jpg",
        "url": "https://images.unsplash.com/photo-1611312449408-fcece27cdbb7?w=600&h=800&fit=crop&q=80",
    },

    # ── Uppers / Hoodies ──────────────────────────────────────────────────────
    {
        "name": "Essential Pullover Hoodie",
        "category_slug": "uppers", "subcategory_slug": "hoodies",
        "material": "Heavyweight Fleece", "color": "Stone Grey",
        "tags": ["streetwear", "casual", "comfort"],
        "filename": "essential_pullover_hoodie.jpg",
        "url": "https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=600&h=800&fit=crop&q=80",
    },

    # ── Lowers / Jeans ────────────────────────────────────────────────────────
    {
        "name": "Straight Leg Denim",
        "category_slug": "lowers", "subcategory_slug": "jeans",
        "material": "Japanese Cotton", "color": "Mid Indigo",
        "tags": ["classic", "versatile", "casual"],
        "filename": "straight_leg_denim.jpg",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDS8_1Q6adlNGkunic8xUPDpVSbhoiNThDV6X1CWrFa9C7jk9QC1oY_XkVKmARa-h_GxdMMeosyhAAvh0jJz1os0F1TaiTsNa75GnU7zFqD7u7TexkPWqDSPkHUAkIEnlBFN4O3sR8dUA-p5GMYTYeC4dWHSuMh7djsuDGGX26U7Z-UDT1zrJOzs5Lqt9L2esE4miD3Kso6gIcjWjPuNLFgC9m5Ap-3LAN_u3bK9HtPw52opHHIj0HzNhFC-vHUV1dSAKYR7riWUsvJ",
    },
    {
        "name": "Indigo Selvedge Jeans",
        "category_slug": "lowers", "subcategory_slug": "jeans",
        "material": "Raw Denim", "color": "Deep Indigo",
        "tags": ["premium", "heritage", "tapered"],
        "filename": "indigo_selvedge_jeans.jpg",
        "url": "https://images.unsplash.com/photo-1542272454315-4c01d7abdf4a?w=600&h=800&fit=crop&q=80",
    },
    {
        "name": "Slim Fit Black Jeans",
        "category_slug": "lowers", "subcategory_slug": "jeans",
        "material": "Stretch Denim", "color": "Black",
        "tags": ["versatile", "night-out", "smart-casual"],
        "filename": "slim_fit_black_jeans.jpg",
        "url": "https://images.unsplash.com/photo-1604176354204-9268737828e4?w=600&h=800&fit=crop&q=80",
    },

    # ── Lowers / Trousers ─────────────────────────────────────────────────────
    {
        "name": "Tailored Wool Trousers",
        "category_slug": "lowers", "subcategory_slug": "trousers",
        "material": "Merino Blend", "color": "Charcoal",
        "tags": ["formal", "workwear", "tailored"],
        "filename": "tailored_wool_trousers.jpg",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuA1vjQCNS8wOTQFSqkuOLMYHED5_pJGzm0QMLAuSSa_vNXjRnEgiMhKztwh5xdb4iMuQVp6bDXJDVXewMnMIZpKY4F-hnijfB8afF3EiJzx94lLdtmhSZN0nzij1dCrWL43Pevx2g_6D7cNg0vnbzrvF8MVDfUk6mbIp_L_Vk6vLsiZTRuPYuiVZsKwzBdI431F0iWEo_6YNhyLywx5ZCud-Bf7X7Q3l9t9Gv-ujwZQBoPULg9OF034wlmE-EmS4fx70cv71aUvGTdD",
    },
    {
        "name": "Relaxed Linen Trousers",
        "category_slug": "lowers", "subcategory_slug": "trousers",
        "material": "Pure Linen", "color": "Ecru",
        "tags": ["summer", "resort", "relaxed"],
        "filename": "relaxed_linen_trousers.jpg",
        "url": "https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600&h=800&fit=crop&q=80",
    },

    # ── Lowers / Chinos ───────────────────────────────────────────────────────
    {
        "name": "Wide Leg Chinos",
        "category_slug": "lowers", "subcategory_slug": "chinos",
        "material": "Cotton Twill", "color": "Khaki",
        "tags": ["relaxed", "streetwear", "wide-leg"],
        "filename": "wide_leg_chinos.jpg",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCvoU6IY_XC238MVjMw68Z-bhdfIKy5fIplVcAJDUKrn4Tt5E7IHnSQ6H16uOSfPXpqpdg8am4H9llT92GVCiKMnHhPu9LP-cwfhcZHklluKJe7C1JaJpgNRAcoY_QynJ-PCEaGN2cAnvoKbvfCK4a8Hlvsv2UCcOz6VXn0stdM6z8JvDk7C8vsfyUnnNyNLq2r2rJ_Lr2QMDTSrgRE97yu7WhC_53Pt5FzpvAZcUu13lKpyqjR-_AyzL_by6uXsrZ-hfsR8j6j6Ths",
    },
    {
        "name": "Slim Beige Chinos",
        "category_slug": "lowers", "subcategory_slug": "chinos",
        "material": "Stretch Twill", "color": "Beige",
        "tags": ["smart-casual", "workwear", "slim"],
        "filename": "slim_beige_chinos.jpg",
        "url": "https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600&h=800&fit=crop&q=80",
    },

    # ── Lowers / Shorts ───────────────────────────────────────────────────────
    {
        "name": "Tailored Twill Shorts",
        "category_slug": "lowers", "subcategory_slug": "shorts",
        "material": "Cotton Twill", "color": "Olive",
        "tags": ["summer", "casual", "clean-cut"],
        "filename": "tailored_twill_shorts.jpg",
        "url": "https://images.unsplash.com/photo-1562157873-818bc0726f68?w=600&h=800&fit=crop&q=80",
    },

    # ── Shoes / Sneakers ──────────────────────────────────────────────────────
    {
        "name": "White Canvas Low-Tops",
        "category_slug": "shoes", "subcategory_slug": "sneakers",
        "material": "Canvas Upper, Rubber Sole", "color": "White",
        "tags": ["minimal", "summer", "versatile"],
        "filename": "white_canvas_lowtops.jpg",
        "url": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=800&fit=crop&q=80",
    },
    {
        "name": "Chunky Sole Runners",
        "category_slug": "shoes", "subcategory_slug": "sneakers",
        "material": "Mesh & Synthetic", "color": "Triple White",
        "tags": ["streetwear", "sporty", "chunky"],
        "filename": "chunky_sole_runners.jpg",
        "url": "https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=600&h=800&fit=crop&q=80",
    },
    {
        "name": "Minimalist Leather Sneakers",
        "category_slug": "shoes", "subcategory_slug": "sneakers",
        "material": "Full-Grain Leather", "color": "Off-White",
        "tags": ["minimal", "premium", "smart-casual"],
        "filename": "minimalist_leather_sneakers.jpg",
        "url": "https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=600&h=800&fit=crop&q=80",
    },

    # ── Shoes / Boots ─────────────────────────────────────────────────────────
    {
        "name": "Leather Chelsea Boots",
        "category_slug": "shoes", "subcategory_slug": "boots",
        "material": "Calfskin Leather", "color": "Tan",
        "tags": ["smart-casual", "autumn", "heritage"],
        "filename": "leather_chelsea_boots.jpg",
        "url": "https://images.unsplash.com/photo-1605812860427-4024433a70fd?w=600&h=800&fit=crop&q=80",
    },
    {
        "name": "Suede Ankle Boots",
        "category_slug": "shoes", "subcategory_slug": "boots",
        "material": "Suede", "color": "Desert Sand",
        "tags": ["casual", "transitional", "lace-up"],
        "filename": "suede_ankle_boots.jpg",
        "url": "https://images.unsplash.com/photo-1542204165-65bf26472b9b?w=600&h=800&fit=crop&q=80",
    },

    # ── Shoes / Loafers ───────────────────────────────────────────────────────
    {
        "name": "Suede Penny Loafers",
        "category_slug": "shoes", "subcategory_slug": "loafers",
        "material": "Suede", "color": "Chocolate Brown",
        "tags": ["smart-casual", "preppy", "no-lace"],
        "filename": "suede_penny_loafers.jpg",
        "url": "https://images.unsplash.com/photo-1626947346165-4c2288dadc2a?w=600&h=800&fit=crop&q=80",
    },

    # ── Shoes / Formal Shoes ──────────────────────────────────────────────────
    {
        "name": "Oxford Brogues",
        "category_slug": "shoes", "subcategory_slug": "formal-shoes",
        "material": "Polished Leather", "color": "Dark Brown",
        "tags": ["formal", "office", "classic"],
        "filename": "oxford_brogues.jpg",
        "url": "https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=600&h=800&fit=crop&q=80",
    },

    # ── Watches / Casual ──────────────────────────────────────────────────────
    {
        "name": "Canvas Strap Field Watch",
        "category_slug": "watches", "subcategory_slug": "casual-watches",
        "material": "Stainless Steel Case, Canvas Strap", "color": "Olive/Gunmetal",
        "tags": ["casual", "utility", "outdoor"],
        "filename": "canvas_strap_field_watch.jpg",
        "url": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&h=800&fit=crop&q=80",
    },

    # ── Watches / Dress ───────────────────────────────────────────────────────
    {
        "name": "Slim Silver Dress Watch",
        "category_slug": "watches", "subcategory_slug": "dress-watches",
        "material": "Stainless Steel, Sapphire Crystal", "color": "Silver/White Dial",
        "tags": ["formal", "minimal", "classic"],
        "filename": "slim_silver_dress_watch.jpg",
        "url": "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&h=800&fit=crop&q=80",
    },
    {
        "name": "Gold Tone Dress Watch",
        "category_slug": "watches", "subcategory_slug": "dress-watches",
        "material": "Gold-Plated Steel, Leather Strap", "color": "Gold/Cream Dial",
        "tags": ["formal", "luxury", "statement"],
        "filename": "gold_tone_dress_watch.jpg",
        "url": "https://images.unsplash.com/photo-1548171915-e79a380a2a4b?w=600&h=800&fit=crop&q=80",
    },

    # ── Watches / Sport ───────────────────────────────────────────────────────
    {
        "name": "Stainless Chronograph",
        "category_slug": "watches", "subcategory_slug": "sport-watches",
        "material": "316L Stainless Steel, Rubber Strap", "color": "Black/Silver",
        "tags": ["sport", "chronograph", "rugged"],
        "filename": "stainless_chronograph.jpg",
        "url": "https://images.unsplash.com/photo-1585386959984-a4155224a1ad?w=600&h=800&fit=crop&q=80",
    },
]


# ── Helpers ───────────────────────────────────────────────────────────────────

async def download_image(client: httpx.AsyncClient, url: str) -> bytes | None:
    try:
        response = await client.get(url, follow_redirects=True, timeout=30.0)
        response.raise_for_status()
        logger.info("  Downloaded %d bytes", len(response.content))
        return response.content
    except Exception as exc:
        logger.error("  Download failed: %s", exc)
        return None


async def upsert_category(db, data: dict) -> CatalogCategory:
    """Insert or update a CatalogCategory by slug."""
    result = await db.execute(
        select(CatalogCategory).where(CatalogCategory.slug == data["slug"])
    )
    existing = result.scalar_one_or_none()
    if existing:
        # Always sync mutable fields so re-runs pick up changes.
        existing.name = data["name"]
        existing.description = data.get("description")
        existing.image_url = data.get("image_url")
        existing.sort_order = data["sort_order"]
        await db.flush()
        return existing
    cat = CatalogCategory(
        id=str(uuid.uuid4()),
        slug=data["slug"],
        name=data["name"],
        description=data.get("description"),
        image_url=data.get("image_url"),
        sort_order=data["sort_order"],
    )
    db.add(cat)
    await db.flush()
    logger.info("  Created category: %s", cat.name)
    return cat


async def upsert_subcategory(
    db, category: CatalogCategory, data: dict
) -> CatalogSubcategory:
    """Insert or update a CatalogSubcategory by (category_id, slug)."""
    result = await db.execute(
        select(CatalogSubcategory).where(
            CatalogSubcategory.category_id == category.id,
            CatalogSubcategory.slug == data["slug"],
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        # Always sync mutable fields so re-runs pick up changes.
        existing.name = data["name"]
        existing.image_url = data.get("image_url")
        existing.sort_order = data["sort_order"]
        await db.flush()
        return existing
    sub = CatalogSubcategory(
        id=str(uuid.uuid4()),
        category_id=category.id,
        slug=data["slug"],
        name=data["name"],
        image_url=data.get("image_url"),
        sort_order=data["sort_order"],
    )
    db.add(sub)
    await db.flush()
    logger.info("    Created subcategory: %s > %s", category.name, sub.name)
    return sub


# ── Main seed routine ─────────────────────────────────────────────────────────

async def seed(run_vision: bool = True, force: bool = False) -> None:
    await init_db()

    async with httpx.AsyncClient() as http_client:
        async with async_session_factory() as db:
            vision_service = VisionService(db)

            # 1. Seed categories
            logger.info("=== Seeding categories ===")
            category_map: dict[str, CatalogCategory] = {}
            for cat_data in CATEGORIES:
                cat = await upsert_category(db, cat_data)
                category_map[cat_data["slug"]] = cat

            # 2. Seed subcategories
            logger.info("=== Seeding subcategories ===")
            subcategory_map: dict[tuple[str, str], CatalogSubcategory] = {}
            for cat_slug, subs in SUBCATEGORIES.items():
                cat = category_map[cat_slug]
                for sub_data in subs:
                    sub = await upsert_subcategory(db, cat, sub_data)
                    subcategory_map[(cat_slug, sub_data["slug"])] = sub

            # 3. Seed clothing items
            logger.info("=== Seeding clothing items (%d items) ===", len(CATALOG_ITEMS))
            inserted = skipped = failed = 0

            for item_data in CATALOG_ITEMS:
                cat_slug = item_data["category_slug"]
                sub_slug = item_data["subcategory_slug"]
                name = item_data["name"]

                # Skip if already in DB (unless --force)
                if not force:
                    result = await db.execute(
                        select(ClothingItem).where(ClothingItem.name == name).limit(1)
                    )
                    if result.scalars().first():
                        logger.info("  SKIP (exists): %s", name)
                        skipped += 1
                        continue

                logger.info("  Processing: %s  (%s / %s)", name, cat_slug, sub_slug)

                # a. Download image
                image_bytes = await download_image(http_client, item_data["url"])
                if not image_bytes:
                    logger.warning("  FAIL (download): %s", name)
                    failed += 1
                    continue

                # b. Upload to Supabase Storage
                try:
                    image_url = await upload_clothing_image(
                        file_bytes=image_bytes,
                        content_type="image/jpeg",
                        filename=item_data["filename"],
                    )
                    logger.info("  Uploaded: %s", image_url)
                except Exception as exc:
                    logger.warning(
                        "  Storage upload failed (%s) — using source URL as fallback", exc
                    )
                    image_url = item_data["url"]

                # c. Insert ClothingItem row
                sub = subcategory_map[(cat_slug, sub_slug)]
                clothing_item = ClothingItem(
                    id=str(uuid.uuid4()),
                    name=name,
                    image_url=image_url,
                    subcategory_id=sub.id,
                    material=item_data.get("material"),
                    color=item_data.get("color"),
                    tags=item_data.get("tags"),
                    is_catalog_item=True,
                )
                db.add(clothing_item)
                await db.flush()

                # d. Vision AI analysis
                if run_vision:
                    try:
                        analysis = await vision_service.analyze_item(clothing_item.id)
                        if analysis:
                            logger.info(
                                "  Vision [%s]: %s…",
                                analysis.category,
                                analysis.description[:55],
                            )
                    except Exception as exc:
                        logger.warning("  Vision skipped: %s", exc)

                inserted += 1

            await db.commit()

    logger.info(
        "Seed complete — inserted: %d | skipped: %d | failed: %d",
        inserted, skipped, failed,
    )


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed StyLoBuddy clothing catalog")
    parser.add_argument(
        "--no-vision",
        action="store_true",
        help="Skip Vision AI analysis (faster; useful when LLM keys are not set)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-insert items even if they already exist in the database",
    )
    args = parser.parse_args()

    asyncio.run(seed(run_vision=not args.no_vision, force=args.force))
