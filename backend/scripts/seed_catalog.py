"""
Seed the clothing catalog with dummy data covering the two main categories.

What this script does
─────────────────────
1. Upserts the 2 top-level CatalogCategory rows.
2. Upserts all CatalogSubcategory rows (6 subcategories total).
3. For each ClothingItem entry:
   a. Downloads the image from its source URL.
   b. Uploads it to the Supabase Storage "clothing-catalog" bucket.
   c. Inserts (or skips if already present) a ClothingItem row linked to
      the correct subcategory.
   d. Runs Vision-AI analysis to populate ai_description + ai_category.

Category structure
──────────────────
  Uppers   → T-Shirts · Shirts · Knitwear
  Lowers   → Jeans · Trousers · Chinos

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
]

SUBCATEGORIES: dict[str, list[dict]] = {
    "uppers": [
        {"slug": "t-shirts", "name": "T-Shirts", "sort_order": 1,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCK33WoXw1FTDfIgyBRxxMqkGKiiS-Hv1eSrkUSY50ksu2QDFesxhcp0Mi1J7UoouiZnJqPATPZHnZ2HuvCs0Nuij6oWXv8Fc2LIrHscTMBcHxFDTZkRXOP8o58gqWhjf_x3ddrvzLjrT-FQyYttblCJh2xScLi-kHuMYQz8YBZcutH3mJNqriqOWeNhaJGksysXD77fumBHfbOMl3D44hja3DGaqNmWhElMQyARnX7J779KFXLUBT3fVAs2CCYW6T5ZnSTAl2Br_Me"},
        {"slug": "shirts", "name": "Shirts", "sort_order": 2,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDfv6avVvhh1tpVlUxrVmLvkAvEmTGD3wbCjAzQC0dsEF86BVTUto20SCsPc4jETxFsVL2B_hDNDa0HnCz_HkcXGq9xw0ijBF29xNBX3aFOM5HaqtoUdRQuAZs58z_HInWKknXXd2QXK8c1Gc3aI0D0b2PslCE0NYNgq7as2yu6yLVj1P4M9F97xRjwuliXeRPuGd0rhxzXaedhHWL5bL0ZNr-cJQFr3cdQeKWq4xpflf6ph7velEDBbnR24Ltkgt0Kz4-0TKEZqv1d"},
        {"slug": "knitwear", "name": "Knitwear", "sort_order": 3,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCQevpDfeOhkaOF7qff6q3ZcNCIPEpMAhgBHCINe_00ApoCnLnu_2Va6vT_gjSZqCUL7F7NupQ5WWeewBjguersBvRrdwpW1Mok40vc3EGNWlRnUQinVABpkWdWoRYA5-WEf_39D--SZkpmXCdnUBuMKnetJIedMaDc7HRVIj19ckY95jHoDNtu0f-3Hy8BBaukz5OUdpDNo426uAn2HNQh9mBb86cPlxP3KMF-D0VUtkdpneS1zHMslO9Wh3MgedNJprDZlQHfOmWN"},
    ],
    "lowers": [
        {"slug": "jeans", "name": "Jeans", "sort_order": 1,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDS8_1Q6adlNGkunic8xUPDpVSbhoiNThDV6X1CWrFa9C7jk9QC1oY_XkVKmARa-h_GxdMMeosyhAAvh0jJz1os0F1TaiTsNa75GnU7zFqD7u7TexkPWqDSPkHUAkIEnlBFN4O3sR8dUA-p5GMYTYeC4dWHSuMh7djsuDGGX26U7Z-UDT1zrJOzs5Lqt9L2esE4miD3Kso6gIcjWjPuNLFgC9m5Ap-3LAN_u3bK9HtPw52opHHIj0HzNhFC-vHUV1dSAKYR7riWUsvJ"},
        {"slug": "trousers", "name": "Trousers", "sort_order": 2,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuA1vjQCNS8wOTQFSqkuOLMYHED5_pJGzm0QMLAuSSa_vNXjRnEgiMhKztwh5xdb4iMuQVp6bDXJDVXewMnMIZpKY4F-hnijfB8afF3EiJzx94lLdtmhSZN0nzij1dCrWL43Pevx2g_6D7cNg0vnbzrvF8MVDfUk6mbIp_L_Vk6vLsiZTRuPYuiVZsKwzBdI431F0iWEo_6YNhyLywx5ZCud-Bf7X7Q3l9t9Gv-ujwZQBoPULg9OF034wlmE-EmS4fx70cv71aUvGTdD"},
        {"slug": "chinos", "name": "Chinos", "sort_order": 3,
         "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCvoU6IY_XC238MVjMw68Z-bhdfIKy5fIplVcAJDUKrn4Tt5E7IHnSQ6H16uOSfPXpqpdg8am4H9llT92GVCiKMnHhPu9LP-cwfhcZHklluKJe7C1JaJpgNRAcoY_QynJ-PCEaGN2cAnvoKbvfCK4a8Hlvsv2UCcOz6VXn0stdM6z8JvDk7C8vsfyUnnNyNLq2r2rJ_Lr2QMDTSrgRE97yu7WhC_53Pt5FzpvAZcUu13lKpyqjR-_AyzL_by6uXsrZ-hfsR8j6j6Ths"},
    ],
}

# ── Clothing items ────────────────────────────────────────────────────────────
# Each entry must have:
#   category_slug    → matches a key in SUBCATEGORIES
#   subcategory_slug → matches a slug inside that category's list
#   name, material, color, tags, filename, url
#
# Image URLs are sourced from:
#   • lh3.googleusercontent.com  — the original items (preserved exactly)
#   • images.unsplash.com        — free stock photos for the newer items
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
        "name": "Striped Navy Tee",
        "category_slug": "uppers", "subcategory_slug": "t-shirts",
        "material": "Cotton Jersey", "color": "Navy Stripe",
        "tags": ["casual", "classic", "weekend"],
        "filename": "striped_navy_tee.jpg",
        "url": "https://teetall.pk/cdn/shop/files/1680833966d4227976a7622a1db4ced952bede4c47_thumbnail_750x_515f1e94-d41b-4449-8226-91e27a2c1078.jpg?crop=center&height=999&v=1685321527&width=750",
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
        "name": "Classic White Formal Shirt",
        "category_slug": "uppers", "subcategory_slug": "shirts",
        "material": "Cotton Poplin", "color": "White",
        "tags": ["formal", "office", "classic"],
        "filename": "classic_white_formal_shirt.jpg",
        "url": "https://discountstore.pk/cdn/shop/files/1_9cc90884-c3ff-432e-887d-f2ba7a37dde0.webp?v=1732890801",
    },
    {
        "name": "Embroidered Dress Shirt",
        "category_slug": "uppers", "subcategory_slug": "shirts",
        "material": "100% Cotton", "color": "Light Blue",
        "tags": ["formal", "smart-casual", "premium"],
        "filename": "embroidered_dress_shirt.jpg",
        "url": "https://image.made-in-china.com/155f0j00ZorbILNqMckn/Formal-Long-Sleeve-Shirt-Man-Shirt-Eco-Friendly-Fabric-High-Quality-Custom-Embroidered-Dress-Shirts-OEM-100-Cotton.webp",
    },
    {
        "name": "Slim Fit Check Shirt",
        "category_slug": "uppers", "subcategory_slug": "shirts",
        "material": "Cotton Blend", "color": "Blue Check",
        "tags": ["smart-casual", "workwear", "slim-fit"],
        "filename": "slim_fit_check_shirt.jpg",
        "url": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTj5U8JBez88qX6uQLoTz6Zt8unBwuPlSOirW6sMuI7tA&s",
    },
    {
        "name": "Cotton Chambray Shirt",
        "category_slug": "uppers", "subcategory_slug": "shirts",
        "material": "Cotton Chambray", "color": "Forest Green",
        "tags": ["casual", "earthy", "weekend"],
        "filename": "cotton_chambray_shirt.jpg",
        "url": "https://saimfashion.com/cdn/shop/files/Cotton_Chambray_Shirt_Forest_Green.webp?v=1770966625&width=1600",
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
        "name": "Teviot Green Knit",
        "category_slug": "uppers", "subcategory_slug": "knitwear",
        "material": "Lambswool", "color": "Forest Green",
        "tags": ["heritage", "autumn", "classic"],
        "filename": "teviot_green_knit.jpg",
        "url": "https://www.kestin.co/cdn/shop/files/Teviot_Green.jpg?v=1776249832&width=832",
    },
    {
        "name": "Cable Knit Pullover",
        "category_slug": "uppers", "subcategory_slug": "knitwear",
        "material": "Wool Blend", "color": "Navy",
        "tags": ["cosy", "winter", "textured"],
        "filename": "cable_knit_pullover.jpg",
        "url": "https://www.kestin.co/cdn/shop/files/Knit2_1.jpg?v=1775141335&width=832",
    },
    {
        "name": "Shetland Crew Neck",
        "category_slug": "uppers", "subcategory_slug": "knitwear",
        "material": "Shetland Wool", "color": "Oatmeal",
        "tags": ["heritage", "casual", "layering"],
        "filename": "shetland_crew_neck.jpg",
        "url": "https://www.kestin.co/cdn/shop/files/SHETLAND_01.jpg?v=1744833434&width=832",
    },
    {
        "name": "Shetland Rust Sweater",
        "category_slug": "uppers", "subcategory_slug": "knitwear",
        "material": "Shetland Wool", "color": "Rust",
        "tags": ["heritage", "autumn", "warm"],
        "filename": "shetland_rust_sweater.jpg",
        "url": "https://www.kestin.co/cdn/shop/files/SHETLAND_09.jpg?v=1744979188&width=832",
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
        "name": "Slim Fit Dark Wash Jeans",
        "category_slug": "lowers", "subcategory_slug": "jeans",
        "material": "Stretch Denim", "color": "Dark Blue",
        "tags": ["slim-fit", "versatile", "modern"],
        "filename": "slim_fit_dark_wash_jeans.jpg",
        "url": "https://www.prexstore.com/cdn/shop/files/IMG_3874.jpg?v=1735808713&width=5000",
    },
    {
        "name": "Classic Blue Straight Jeans",
        "category_slug": "lowers", "subcategory_slug": "jeans",
        "material": "Cotton Denim", "color": "Medium Blue",
        "tags": ["classic", "everyday", "straight-leg"],
        "filename": "classic_blue_straight_jeans.jpg",
        "url": "https://outfitters.com.pk/cdn/shop/files/F0283209626_1.jpg?v=1726831024&width=493",
    },
    {
        "name": "Tapered Indigo Jeans",
        "category_slug": "lowers", "subcategory_slug": "jeans",
        "material": "Raw Denim", "color": "Deep Indigo",
        "tags": ["premium", "tapered", "heritage"],
        "filename": "tapered_indigo_jeans.jpg",
        "url": "https://frenchcrown.in/cdn/shop/products/J-151_7.jpg?v=1700653952&width=112",
    },
    {
        "name": "White Straight Leg Jeans",
        "category_slug": "lowers", "subcategory_slug": "jeans",
        "material": "Cotton Denim", "color": "White",
        "tags": ["summer", "clean", "statement"],
        "filename": "white_straight_leg_jeans.jpg",
        "url": "https://tiimg.tistatic.com/fp/1/007/571/white-color-straight-comfortable-daily-wear-denim-rough-jeans-for-men-815.jpg",
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
        "name": "Slim Fit Formal Trousers",
        "category_slug": "lowers", "subcategory_slug": "trousers",
        "material": "Polyester Blend", "color": "Black",
        "tags": ["formal", "office", "slim-fit"],
        "filename": "slim_fit_formal_trousers.jpg",
        "url": "https://www.exportleftovers.com/cdn/shop/files/vfe_d43c55cf-287b-47e7-afee-a853d909393c_2048x2048.jpg?v=1768969379",
    },
    {
        "name": "Cotton Dress Trousers",
        "category_slug": "lowers", "subcategory_slug": "trousers",
        "material": "Cotton Twill", "color": "Beige",
        "tags": ["smart-casual", "summer", "versatile"],
        "filename": "cotton_dress_trousers.jpg",
        "url": "https://www.almas.pk/cdn/shop/files/STW49_1_31dfbac1-cd51-466e-aeb1-adbb7da85cda.jpg?v=1753985041",
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
        "name": "Slim Fit Olive Chinos",
        "category_slug": "lowers", "subcategory_slug": "chinos",
        "material": "Stretch Cotton", "color": "Olive",
        "tags": ["smart-casual", "slim-fit", "versatile"],
        "filename": "slim_fit_olive_chinos.jpg",
        "url": "https://outfitters.com.pk/cdn/shop/files/F0241308801_3.jpg?v=1727179802&width=493",
    },
    {
        "name": "Tapered Beige Chinos",
        "category_slug": "lowers", "subcategory_slug": "chinos",
        "material": "Cotton Twill", "color": "Beige",
        "tags": ["classic", "workwear", "tapered"],
        "filename": "tapered_beige_chinos.jpg",
        "url": "https://be.benetton.com/cdn/shop/files/TBkyd1tkRBKh0z2aAHWurw.jpg?crop=center&height=853&v=1776769349&width=640",
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
