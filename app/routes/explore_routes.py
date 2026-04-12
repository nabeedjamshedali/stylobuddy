from fastapi import APIRouter, Query

from app.schemas.explore_schema import ExploreItem, ExploreListResponse

router = APIRouter(prefix="/api/explore", tags=["Explore"])

# ── Curated seed data ─────────────────────────────────────────────────────────
# Replace image_url values with your Supabase Storage URLs after seeding.
# Category values must match the filter chips in the frontend Explore page.

_EXPLORE_ITEMS: list[ExploreItem] = [
    ExploreItem(
        id=1,
        title="Urban Nomad Ensemble",
        category="Casual",
        image_url="https://lh3.googleusercontent.com/aida-public/AB6AXuChle3559RIuuP_jWCZjo7PtY1EC13e1FExVRDsoRymCex3jAFM7kKZj5c-QskVrOn9tJe2RgJZej8tYumPnFpeLb2vpoMIAWstSxO0jr9kRYnKRi0RWfAftBEnrvW5UJiZNmLR1iOlnNkmfLIFkmTU5M7PQHOoXDOyauls8K9U_qq4e9vsY3lFcrNimi3GhOC_SwBtmX9qwiiUnu-pXOXr4lGs9beWK-2K8ow5-OXY-1pK5aJfbfnks2Ox1g_UXEo5n0PL7uLAP73Q",
        aspect_ratio="16/10",
    ),
    ExploreItem(
        id=2,
        title="Midnight Gala",
        category="Formal",
        image_url="https://lh3.googleusercontent.com/aida-public/AB6AXuBo3QdOCLe1iLWynbZuo2JHmsObL2BnYPjLDjNDToZpGZuVomL1cxxSGoz_CXOM9YVpqRxV1vR8ORqeghR4GVYP0vTnmIqTzwTlbFbTDCOzJlCRBxNN8j_O0pMyzJlJ0eB8aHwEKhxF12wiOn_AXM5lekdEqDkkyP2Fz5CHUhfSx6Ifhv3tvn6xreSKRxnrdIs7RJ51OGY0eO0mhuBCevSEauRqGDIaZApKhYCBmhri3r669c4PHUArta9XvR5Zlbj3K4GdI9nTyoze",
        aspect_ratio="3/4",
    ),
    ExploreItem(
        id=3,
        title="Linen Breeze",
        category="Minimalist",
        image_url="https://lh3.googleusercontent.com/aida-public/AB6AXuAKGQSIknCX5SBx0ludKWSBw0wbvIjPJ20_xAhj3g3Hg6YtsDVE-TS2ZLubMJAPZnMiZpEXYv8Qb9DTmQX4BJFZqJ0QJsrpjhQsvBhYedaIQxBWMigA-U9JKYxn3uL0uzpTMcX5Sz-Hx7TOIDs_5RVO31FpJzvmGMXrR2KGLBLYP8wn8BEL8izx2dNPvDDnPSK_6tCedCTxbR1iPT3blx5JhGilmUSWZi2oEkEOSnZ6vLbRluz4H4riIZNMNHJFAShgsz8OK-azLKZL",
        aspect_ratio="1/1",
    ),
    ExploreItem(
        id=4,
        title="Active Pulse",
        category="Streetwear",
        image_url="https://lh3.googleusercontent.com/aida-public/AB6AXuD8B8i7lKU5mNWjz19uzCEyc5tGdKmZlBmhAQrck2imsZeIW7BkuoOGUQ1nHGRTeb2fVQY-3rYbu58F-dZ3t2gw1umuwTt1itQTF2o0KskBJVHDKPsBXQodf7mLgRwLLXN0SUDMXgnVcexWAntt9A3OugbYVJ0trI6KOCm1TodqMCA20oBHnK4bEhqMQFzqgXcTEJFrHtUN8SyDm3IzxVdlMf9g3_kUwWZMOQjz2jAEfd2EA2v1RToqofaztPyWOD1bwsQpGyHYqlOX",
        aspect_ratio="21/9",
    ),
    ExploreItem(
        id=5,
        title="Grey Scale",
        category="Minimalist",
        image_url="https://lh3.googleusercontent.com/aida-public/AB6AXuBF4kQPcGjbzfl4on9Tfpn7jBmaTa721OZx2Dk-UKS1qxxE206t7zNnVV44oOEyGj23u8IVbwUkTk-4kCjoilUUWn_KsIqdjfjt1xeMeTGvAZ-SKpnP2DYsN9K3PfupZ4mH5vpWPbtXr_y1WAR5ZmKCP_F3AVKyNcfARG2Th-NNJW2EPy7kQ2rUENVYDDib2UT7D-is4cqSScRNwUSu_5RZv5YH49GMOWwcAbCPC6iDiKN0LfmxgtE8jZvicMfG4OZvJmP_jqjMJR_N",
        aspect_ratio="3/4",
    ),
    ExploreItem(
        id=6,
        title="Heritage Modern",
        category="Smart Casual",
        image_url="https://lh3.googleusercontent.com/aida-public/AB6AXuATtwRQEBSW9Dq115Hx2ER3hUjITjMetogz7oglUvQmC-sl5rxnrLjfVX3HTcr4U2chbYMSf_zVoFbUbEWplqqavbfZBu9cDn8X6gjCOHNkV6GoZdhyMuyWNT6GhE51A6OFzcQQmowBhy-YGk72hExAlm9-MrpDKRYoj6pfoPo5FPIQ96WxC9zjDLEdLXGhU5uQ0R4Ksx-Vu2uHkneQJIcX4eyu50e0P26hMTd4RJUbq1HkQcbjhTgMIeo3ARzP_TD23PXI0-MVTq_6",
        aspect_ratio="4/5",
    ),
    ExploreItem(
        id=7,
        title="Golden Hour Set",
        category="Casual",
        image_url="https://lh3.googleusercontent.com/aida-public/AB6AXuBt28X2VVxij7YBsD1d6W4_dlwspDdNB50y6OxTJH-rMfZIZQ5HYMbeZEnmbUFf1VJhV7Pljq4tbP3k4Tr9uBwEb3PUvjdaBhGpYCP09Y13GYmx8NAtPKjU-WZjJuLB9nxK8Jtv0vjd1QNo659IC6SShHSq8aPBMd1gPS6Htq6Tf2ErR1sUp5fFIkmbUAcn9k5yJUwxGV_fq9tl101eKLtdlyClaYyC2H7DlgVDITgVZ3nipAteIWCFJe4cEcT-6jN1eFXm-FlXGpH-",
        aspect_ratio="1/1",
    ),
]

ALL_CATEGORIES = {"All Styles", "Casual", "Formal", "Minimalist", "Smart Casual", "Streetwear"}


@router.get("/", response_model=ExploreListResponse)
async def list_explore_looks(
    category: str | None = Query(None, description="Filter by style category"),
) -> ExploreListResponse:
    """
    Return curated outfit looks for the Explore page.
    Pass ?category=Casual to filter. Omit for all styles.
    """
    items = _EXPLORE_ITEMS
    if category and category != "All Styles":
        items = [i for i in items if i.category == category]

    return ExploreListResponse(items=items, total=len(items))
