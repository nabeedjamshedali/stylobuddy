'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { getSavedLooks, deleteSavedLook, type SavedLook } from '@/lib/api'

function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ago`
  const days = Math.floor(hrs / 24)
  return `${days}d ago`
}

function LookCard({ look, onDelete }: { look: SavedLook; onDelete: () => void }) {
  const [confirmDelete, setConfirmDelete] = useState(false)

  const isAutoSuggest = look.suggest_mode !== null
  // Which role did the user select, and which did the AI suggest?
  const heroRole    = look.suggest_mode === 'lowers' ? 'top'    : look.suggest_mode === 'uppers' ? 'bottom' : null
  const suggestRole = look.suggest_mode === 'lowers' ? 'bottom' : look.suggest_mode === 'uppers' ? 'top'    : null

  // Hero = the user's own piece (same across all combos)
  const heroItem = heroRole
    ? look.combinations[0]?.items.find((i) => i.role_in_outfit === heroRole) ?? look.combinations[0]?.items[0]
    : null

  // Suggested = one per combination (the catalog-matched piece)
  const suggestedItems = suggestRole
    ? look.combinations
        .map((c) => c.items.find((i) => i.role_in_outfit === suggestRole))
        .filter((i): i is NonNullable<typeof i> => !!i)
    : []

  // Normal mode: first combo items
  const firstComboItems = look.combinations[0]?.items ?? []

  return (
    <div className="group relative overflow-hidden rounded-2xl bg-surface-container-low border border-outline-variant/10">

      {/* ── Visual area ─────────────────────────────────────────────────── */}
      {isAutoSuggest ? (
        /* Auto-suggest layout: hero item on top, matched strip below */
        <div>
          {/* Hero */}
          <div className="relative aspect-square overflow-hidden bg-surface-container">
            {heroItem ? (
              <img
                src={heroItem.image_url}
                alt={heroItem.item_name}
                className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center">
                <span className="material-symbols-outlined text-4xl text-outline-variant">checkroom</span>
              </div>
            )}

            {/* Gradient + delete on hover */}
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
            <div className="absolute bottom-0 left-0 right-0 p-3 translate-y-1 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-500 flex items-center justify-between gap-2">
              <p className="font-label text-white/70 text-[0.5rem] uppercase tracking-widest">
                {look.combinations.length} match{look.combinations.length !== 1 ? 'es' : ''}
              </p>
              {!confirmDelete ? (
                <button
                  onClick={() => setConfirmDelete(true)}
                  className="w-7 h-7 rounded-full bg-white/20 backdrop-blur-md text-white flex items-center justify-center hover:bg-error/80 transition-all duration-[400ms]"
                >
                  <span className="material-symbols-outlined text-sm">delete</span>
                </button>
              ) : (
                <div className="flex gap-1">
                  <button onClick={() => setConfirmDelete(false)} className="px-2.5 py-1 rounded-full bg-white/20 backdrop-blur-md text-white font-label text-[0.5rem] uppercase tracking-widest hover:bg-white/30 transition-all">Cancel</button>
                  <button onClick={onDelete} className="px-2.5 py-1 rounded-full bg-error text-on-error font-label text-[0.5rem] uppercase tracking-widest hover:bg-error/80 transition-all">Delete</button>
                </div>
              )}
            </div>

            {/* Style tag */}
            {look.tags[0] && (
              <div className="absolute top-3 left-3">
                <span className="px-2.5 py-1 bg-white/80 backdrop-blur-md rounded-full font-label text-[0.5rem] uppercase tracking-widest text-on-surface">
                  {look.tags[0]}
                </span>
              </div>
            )}
          </div>

          {/* Matched items horizontal strip */}
          {suggestedItems.length > 0 && (
            <div className="flex gap-1.5 px-3 py-2.5 overflow-x-auto" style={{ scrollbarWidth: 'none' }}>
              {suggestedItems.map((item, i) => (
                <div key={item.item_id + i} className="flex-none w-12 aspect-[3/4] rounded-lg overflow-hidden bg-surface-container ring-1 ring-outline-variant/20">
                  <img src={item.image_url} alt={item.item_name} className="w-full h-full object-cover" />
                </div>
              ))}
            </div>
          )}
        </div>
      ) : (
        /* Normal mode layout: side-by-side collage from first combo */
        <div className="relative aspect-[3/4] overflow-hidden bg-surface-container">
          {firstComboItems.length === 0 ? (
            <div className="w-full h-full flex items-center justify-center">
              <span className="material-symbols-outlined text-5xl text-outline-variant">checkroom</span>
            </div>
          ) : firstComboItems.length === 1 ? (
            <img src={firstComboItems[0].image_url} alt={firstComboItems[0].item_name} className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" />
          ) : (
            <div className="flex w-full h-full gap-px transition-transform duration-700 group-hover:scale-105">
              {firstComboItems.slice(0, 2).map((item) => (
                <div key={item.item_id} className="flex-1 overflow-hidden">
                  <img src={item.image_url} alt={item.item_name} className="w-full h-full object-cover" />
                </div>
              ))}
            </div>
          )}

          {/* Gradient + delete on hover */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
          <div className="absolute bottom-0 left-0 right-0 p-4 translate-y-2 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-500">
            <div className="flex items-end justify-between gap-2">
              <div className="flex-1 min-w-0">
                <p className="font-headline font-semibold text-white text-sm leading-tight truncate">{look.aesthetic}</p>
                <p className="font-label text-white/60 text-[0.5rem] uppercase tracking-widest mt-0.5">{timeAgo(look.savedAt)}</p>
              </div>
              {!confirmDelete ? (
                <button onClick={() => setConfirmDelete(true)} className="flex-none w-8 h-8 rounded-full bg-white/20 backdrop-blur-md text-white flex items-center justify-center hover:bg-error/80 transition-all duration-[400ms]">
                  <span className="material-symbols-outlined text-sm">delete</span>
                </button>
              ) : (
                <div className="flex gap-1">
                  <button onClick={() => setConfirmDelete(false)} className="px-2.5 py-1 rounded-full bg-white/20 backdrop-blur-md text-white font-label text-[0.5rem] uppercase tracking-widest hover:bg-white/30 transition-all">Cancel</button>
                  <button onClick={onDelete} className="px-2.5 py-1 rounded-full bg-error text-on-error font-label text-[0.5rem] uppercase tracking-widest hover:bg-error/80 transition-all">Delete</button>
                </div>
              )}
            </div>
          </div>

          {look.tags[0] && (
            <div className="absolute top-3 left-3">
              <span className="px-2.5 py-1 bg-white/80 backdrop-blur-md rounded-full font-label text-[0.5rem] uppercase tracking-widest text-on-surface">
                {look.tags[0]}
              </span>
            </div>
          )}
        </div>
      )}

      {/* ── Card footer ─────────────────────────────────────────────────── */}
      <div className="px-4 pt-3 pb-4 space-y-2">
        <div className="flex items-center justify-between gap-2">
          <h3 className="font-headline font-semibold text-on-surface text-[0.8125rem] truncate">{look.aesthetic}</h3>
          <span className="font-label text-[0.5rem] text-outline uppercase tracking-widest flex-none">{timeAgo(look.savedAt)}</span>
        </div>
        {look.palette.length > 0 && (
          <div className="flex gap-1.5">
            {look.palette.slice(0, 5).map((hex, i) => (
              <div key={i} className="w-4 h-4 rounded-full ring-1 ring-black/10" style={{ backgroundColor: hex }} title={hex} />
            ))}
          </div>
        )}
        <div className="flex flex-wrap gap-1">
          {look.tags.slice(0, 3).map((tag) => (
            <span key={tag} className="px-2 py-0.5 bg-surface-container rounded-full font-label text-[0.5rem] uppercase tracking-widest text-on-surface-variant">
              {tag}
            </span>
          ))}
        </div>
      </div>
    </div>
  )
}

export default function SavedStylesPage() {
  const [looks, setLooks] = useState<SavedLook[]>([])

  useEffect(() => {
    setLooks(getSavedLooks())
  }, [])

  const handleDelete = (id: string) => {
    deleteSavedLook(id)
    setLooks((prev) => prev.filter((l) => l.id !== id))
  }

  return (
    <main className="pt-32 pb-24 px-6 md:px-12 max-w-[1440px] mx-auto">

      {/* Header */}
      <header className="mb-16 md:mb-24 flex flex-col md:flex-row md:items-end justify-between gap-8">
        <div className="max-w-2xl">
          <span className="font-label uppercase tracking-[0.2rem] text-[0.6875rem] text-secondary font-bold mb-4 block">
            Archive {new Date().getFullYear()}
          </span>
          <h1 className="font-headline font-extrabold text-5xl md:text-7xl tracking-tighter text-on-surface leading-none">
            Saved <br />
            <span className="text-outline-variant">Styles</span>
          </h1>
          <p className="mt-8 text-on-surface-variant font-light text-lg max-w-md">
            Your personal atelier of curated ensembles and AI-matched inspirations.
          </p>
        </div>
        <div className="flex gap-4">
          <Link
            href="/workspace"
            className="px-8 py-3 rounded-full bg-on-surface text-surface hover:bg-primary transition-all duration-[400ms] font-label text-xs uppercase tracking-widest flex items-center gap-2"
          >
            <span className="material-symbols-outlined text-sm">add</span>
            Create New
          </Link>
        </div>
      </header>

      {/* Empty state */}
      {looks.length === 0 && (
        <div className="flex flex-col items-center justify-center py-32 gap-6 text-center">
          <div className="w-20 h-20 rounded-full bg-surface-container flex items-center justify-center">
            <span className="material-symbols-outlined text-4xl text-outline-variant">bookmark</span>
          </div>
          <div className="space-y-2">
            <p className="font-headline font-light text-xl text-on-surface tracking-tight">No saved looks yet</p>
            <p className="font-label text-[0.75rem] text-outline leading-relaxed max-w-xs">
              Generate an outfit in the Workspace and hit "Save Look" to archive it here.
            </p>
          </div>
          <Link
            href="/workspace"
            className="mt-2 px-8 py-3 rounded-full bg-on-surface text-surface hover:bg-primary transition-all duration-[400ms] font-label text-xs uppercase tracking-widest"
          >
            Go to Workspace
          </Link>
        </div>
      )}

      {/* Grid */}
      {looks.length > 0 && (
        <>
          <p className="font-label text-[0.625rem] text-outline uppercase tracking-widest mb-8">
            {looks.length} saved {looks.length === 1 ? 'look' : 'looks'}
          </p>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-6">
            {looks.map((look) => (
              <LookCard
                key={look.id}
                look={look}
                onDelete={() => handleDelete(look.id)}
              />
            ))}
          </div>
        </>
      )}
    </main>
  )
}
