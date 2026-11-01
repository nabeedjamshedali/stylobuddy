/**
 * Typed API client for the StyLoBuddy FastAPI backend.
 *
 * All functions read NEXT_PUBLIC_API_URL from the environment so the base
 * URL can be switched between local dev and production without code changes.
 */

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

// ── Shared fetch helper ───────────────────────────────────────────────────────

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: { 'Content-Type': 'application/json', ...init?.headers },
  })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error((body as { detail?: string }).detail ?? `API error ${res.status}`)
  }
  return res.json() as Promise<T>
}

// ── Catalog types ─────────────────────────────────────────────────────────────

export interface Subcategory {
  id: string
  slug: string
  name: string
  image_url: string | null
  sort_order: number
}

export interface Category {
  id: string
  slug: string
  name: string
  description: string | null
  image_url: string | null
  sort_order: number
  subcategories: Subcategory[]
}

export interface CatalogItem {
  id: string
  name: string
  image_url: string
  /** Top-level category slug, e.g. "uppers", "lowers", "shoes", "watches" */
  type: string | null
  /** Subcategory display name, e.g. "T-Shirts", "Jeans" */
  category: string | null
  material: string | null
  color: string | null
  brand: string | null
  tags: string[] | null
  is_catalog_item: boolean
  ai_description: string | null
  ai_category: string | null
  subcategory: Subcategory | null
}

// ── Catalog API ───────────────────────────────────────────────────────────────

/** Fetch the full category → subcategory tree. */
export async function fetchCategories(): Promise<Category[]> {
  const data = await apiFetch<{ categories: Category[] }>('/api/catalog/categories')
  return data.categories
}

/** Fetch catalog items, optionally filtered by category or subcategory slug. */
export async function fetchCatalogItems(opts?: {
  categorySlug?: string
  subcategorySlug?: string
}): Promise<CatalogItem[]> {
  const params = new URLSearchParams()
  if (opts?.categorySlug) params.set('category_slug', opts.categorySlug)
  if (opts?.subcategorySlug) params.set('subcategory_slug', opts.subcategorySlug)
  const qs = params.toString() ? `?${params}` : ''
  const data = await apiFetch<{ items: CatalogItem[]; total: number }>(
    `/api/catalog/items${qs}`
  )
  return data.items
}

// ── Recommendation types ──────────────────────────────────────────────────────

export interface OutfitItem {
  item_id: string
  item_name: string
  image_url: string
  category: string
  role_in_outfit: string
}

export interface OutfitCombination {
  outfit_name: string
  items: OutfitItem[]
  style_description: string
  occasion_fit: string[]
  confidence_score: number
}

export interface GenerateOutfitResponse {
  recommendation_id: string
  aesthetic: string
  description: string
  palette: string[]
  tags: string[]
  combinations: OutfitCombination[]
  styling_tips: string[]
  items_not_used: OutfitItem[]
  is_saved: boolean
  /** 'lowers' | 'uppers' | null — set when the AI auto-suggested complementary pieces */
  suggest_mode: 'lowers' | 'uppers' | null
}

// ── Saved looks (localStorage) ───────────────────────────────────────────────

export interface SavedLook {
  id: string
  savedAt: string           // ISO date string
  aesthetic: string
  description: string
  palette: string[]
  tags: string[]
  combinations: OutfitCombination[]
  styling_tips: string[]
  suggest_mode: 'lowers' | 'uppers' | null
  heroImage: string         // first item's image_url
}

const SAVED_KEY = 'stylobuddy_saved_looks'

export function getSavedLooks(): SavedLook[] {
  try {
    return JSON.parse(localStorage.getItem(SAVED_KEY) ?? '[]')
  } catch {
    return []
  }
}

export function saveLook(result: GenerateOutfitResponse): SavedLook {
  const existing = getSavedLooks()
  const heroImage =
    result.combinations[0]?.items[0]?.image_url ?? ''
  const look: SavedLook = {
    id: result.recommendation_id,
    savedAt: new Date().toISOString(),
    aesthetic: result.aesthetic,
    description: result.description,
    palette: result.palette,
    tags: result.tags,
    combinations: result.combinations,
    styling_tips: result.styling_tips,
    suggest_mode: result.suggest_mode ?? null,
    heroImage,
  }
  // Avoid duplicates
  const filtered = existing.filter((l) => l.id !== look.id)
  localStorage.setItem(SAVED_KEY, JSON.stringify([look, ...filtered]))
  return look
}

export function deleteSavedLook(id: string): void {
  const updated = getSavedLooks().filter((l) => l.id !== id)
  localStorage.setItem(SAVED_KEY, JSON.stringify(updated))
}

export function isLookSaved(id: string): boolean {
  return getSavedLooks().some((l) => l.id === id)
}

// ── Recommendation API ────────────────────────────────────────────────────────

/**
 * Generate an outfit recommendation from a list of selected item IDs.
 *
 * Works without a token (guest mode) — the recommendation is generated but
 * not saved to history.  Pass a JWT token to persist it for the logged-in user.
 */
export async function generateOutfit(
  itemIds: string[],
  opts?: { occasion?: string; preferences?: string; token?: string; photoType?: 'uppers' | 'lowers' }
): Promise<GenerateOutfitResponse> {
  const headers: Record<string, string> = {}
  if (opts?.token) headers['Authorization'] = `Bearer ${opts.token}`
  return apiFetch<GenerateOutfitResponse>('/api/recommendations/outfit', {
    method: 'POST',
    headers,
    body: JSON.stringify({
      item_ids: itemIds,
      occasion: opts?.occasion,
      preferences: opts?.preferences,
      photo_type: opts?.photoType ?? null,
    }),
  })
}
