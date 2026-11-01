'use client'

import { useState, useEffect } from 'react'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

interface ExploreItem {
  id: string
  title: string
  category: string
  gender: string
  image_url: string
  source_url: string
  hashtags: string[]
  saves: number
}

interface ExploreListResponse {
  items: ExploreItem[]
  total: number
  cached: boolean
}

const STYLE_FILTERS = ['All Styles', 'Casual', 'Formal', 'Minimalist', 'Smart Casual', 'Streetwear']
const GENDER_TABS = [
  { key: 'all',   label: 'All' },
  { key: 'men',   label: 'Men' },
  { key: 'women', label: 'Women' },
] as const

function PinSkeleton() {
  const heights = ['aspect-[3/4]', 'aspect-square', 'aspect-[4/5]', 'aspect-[3/4]', 'aspect-[4/5]', 'aspect-square']
  return (
    <div className="columns-2 sm:columns-3 lg:columns-4 gap-4">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className={`${heights[i % heights.length]} skeleton rounded-xl mb-4`} />
      ))}
    </div>
  )
}

function PinCard({ item }: { item: ExploreItem }) {
  const [imgError, setImgError] = useState(false)

  if (imgError) return null

  return (
    <div className="group relative break-inside-avoid mb-4 rounded-xl overflow-hidden bg-surface-container-low cursor-pointer">
      <img
        src={item.image_url}
        alt={item.title}
        className="w-full object-cover transition-transform duration-700 group-hover:scale-105"
        onError={() => setImgError(true)}
      />
      {/* Overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-[400ms]" />

      {/* Category pill — top left */}
      <div className="absolute top-3 left-3 opacity-0 group-hover:opacity-100 transition-opacity duration-[400ms]">
        <span className="px-2.5 py-1 bg-white/80 backdrop-blur-md rounded-full font-label text-[0.5rem] uppercase tracking-widest text-on-surface">
          {item.category}
        </span>
      </div>

      {/* Bottom info */}
      <div className="absolute bottom-0 left-0 right-0 p-3 translate-y-2 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-[400ms]">
        <p className="font-headline font-semibold text-white text-[0.8125rem] leading-tight truncate">
          {item.title}
        </p>
        {item.hashtags.length > 0 && (
          <p className="font-label text-white/60 text-[0.5rem] uppercase tracking-widest mt-0.5 truncate">
            {item.hashtags.slice(0, 3).map(h => `#${h}`).join(' ')}
          </p>
        )}
      </div>

      {/* Pinterest source link */}
      {item.source_url && (
        <a
          href={item.source_url}
          target="_blank"
          rel="noopener noreferrer"
          onClick={(e) => e.stopPropagation()}
          className="absolute top-3 right-3 w-7 h-7 rounded-full bg-white/20 backdrop-blur-md flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-[400ms] hover:bg-white/40"
          title="View on Pinterest"
        >
          <span className="material-symbols-outlined text-white text-sm">open_in_new</span>
        </a>
      )}
    </div>
  )
}

export default function ExplorePage() {
  const [gender, setGender] = useState<'all' | 'men' | 'women'>('all')
  const [styleFilter, setStyleFilter] = useState('All Styles')
  const [items, setItems] = useState<ExploreItem[]>([])
  const [loading, setLoading] = useState(true)
  const [isCached, setIsCached] = useState(true)

  useEffect(() => {
    const controller = new AbortController()
    setLoading(true)

    const params = new URLSearchParams()
    if (gender !== 'all') params.set('gender', gender)
    if (styleFilter !== 'All Styles') params.set('category', styleFilter)

    fetch(`${API_URL}/api/explore/?${params}`, { signal: controller.signal })
      .then((r) => r.json())
      .then((data: ExploreListResponse) => {
        setItems(data.items)
        setIsCached(data.cached)
        setLoading(false)
      })
      .catch(() => setLoading(false))

    return () => controller.abort()
  }, [gender, styleFilter])

  return (
    <main className="pt-32 pb-24 px-6 md:px-12 max-w-[1440px] mx-auto">

      {/* Header */}
      <header className="mb-12 max-w-3xl">
        <h1 className="text-[3.5rem] font-extrabold font-headline leading-[1.1] tracking-tight mb-4 text-on-surface">
          Trending{' '}
          <span className="text-outline-variant font-light italic">Inspirations</span>
        </h1>
        <p className="text-on-surface-variant max-w-xl font-light leading-relaxed text-base">
          Real-time fashion trends from Pinterest — updated daily. Discover what the world is wearing.
        </p>
        {!isCached && (
          <p className="mt-3 font-label text-[0.625rem] text-outline uppercase tracking-widest flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-secondary animate-pulse inline-block" />
            Live data loading — showing seed looks while Pinterest syncs
          </p>
        )}
      </header>

      {/* Gender tabs */}
      <div className="flex items-center gap-1 p-1 bg-surface-container rounded-xl w-fit mb-8">
        {GENDER_TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setGender(tab.key)}
            className={`px-7 py-2 rounded-lg font-headline uppercase tracking-[0.12rem] text-[0.6875rem] transition-all duration-[400ms] ${
              gender === tab.key
                ? 'bg-surface text-on-surface shadow-sm'
                : 'text-outline hover:text-on-surface-variant'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Style filter chips */}
      <div className="flex flex-wrap gap-2.5 mb-12">
        {STYLE_FILTERS.map((filter) => (
          <button
            key={filter}
            onClick={() => setStyleFilter(filter)}
            className={`px-6 py-2 rounded-full text-[0.6875rem] uppercase tracking-[0.1rem] transition-all duration-[400ms] ${
              styleFilter === filter
                ? 'bg-on-surface text-surface font-bold'
                : 'bg-surface-container hover:bg-surface-container-high text-on-surface-variant'
            }`}
          >
            {filter}
          </button>
        ))}
      </div>

      {/* Content */}
      {loading ? (
        <PinSkeleton />
      ) : items.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-32 gap-4 text-center">
          <span className="material-symbols-outlined text-5xl text-outline-variant">image_not_supported</span>
          <p className="font-headline font-light text-lg text-on-surface">No looks found</p>
          <p className="font-label text-[0.75rem] text-outline max-w-xs leading-relaxed">
            Pinterest data is syncing in the background. Try again in a moment.
          </p>
        </div>
      ) : (
        <>
          <p className="font-label text-[0.625rem] text-outline uppercase tracking-widest mb-6">
            {items.length} {gender !== 'all' ? gender + "'s " : ''}looks
            {isCached ? ' · Updated daily from Pinterest' : ' · Seed data'}
          </p>

          {/* Pinterest-style masonry grid */}
          <div className="columns-2 sm:columns-3 lg:columns-4 gap-4">
            {items.map((item) => (
              <PinCard key={item.id} item={item} />
            ))}
          </div>
        </>
      )}
    </main>
  )
}
