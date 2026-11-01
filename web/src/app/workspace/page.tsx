'use client'

import { useState, useRef, useCallback, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  fetchCategories,
  fetchCatalogItems,
  generateOutfit,
  saveLook,
  isLookSaved,
  type CatalogItem,
  type GenerateOutfitResponse,
} from '@/lib/api'

// ── ClothingCard ──────────────────────────────────────────────────────────────

interface ClothingCardProps {
  item: CatalogItem
  isSelected: boolean
  onToggle: () => void
}

function ClothingCard({ item, isSelected, onToggle }: ClothingCardProps) {
  return (
    <div
      onClick={onToggle}
      className={`group relative aspect-[3/4] rounded-xl overflow-hidden cursor-pointer transition-all duration-[400ms] ease-editorial bg-surface-container-lowest ${
        isSelected
          ? 'glow-pulse scale-[0.97] ring-2 ring-secondary/40'
          : 'hover:shadow-xl hover:scale-[0.985]'
      }`}
    >
      <img
        alt={item.name}
        src={item.image_url}
        className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
      />
      <div
        className={`absolute inset-0 bg-gradient-to-t from-on-surface/65 via-transparent to-transparent transition-opacity duration-[400ms] ${
          isSelected ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
        }`}
      />
      <div
        className={`absolute bottom-0 left-0 right-0 p-3 transition-all duration-[400ms] ${
          isSelected
            ? 'translate-y-0 opacity-100'
            : 'translate-y-2 opacity-0 group-hover:translate-y-0 group-hover:opacity-100'
        }`}
      >
        <p className="font-headline font-semibold text-white text-[0.75rem] leading-tight">
          {item.name}
        </p>
        <p className="font-label text-white/65 text-[0.625rem] uppercase tracking-wide mt-0.5">
          {item.material}
        </p>
      </div>
      {isSelected && (
        <div className="absolute top-3 right-3 w-6 h-6 bg-secondary text-on-secondary rounded-full flex items-center justify-center shadow-lg">
          <span className="material-symbols-outlined text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>
            check
          </span>
        </div>
      )}
    </div>
  )
}

// ── Grid skeleton ─────────────────────────────────────────────────────────────

function GridSkeleton() {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-5">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="aspect-[3/4] skeleton rounded-xl" />
      ))}
    </div>
  )
}

// ── Main component ─────────────────────────────────────────────────────────────

export default function WorkspacePage() {
  // ── Catalog data — cached for 1 hour, no refetch on tab switch or remount ────
  const { data: uppers = [], isLoading: uppersLoading, isError: uppersError } =
    useQuery({
      queryKey: ['catalog', 'uppers'],
      queryFn: () => fetchCatalogItems({ categorySlug: 'uppers' }),
    })

  const { data: lowers = [], isLoading: lowersLoading, isError: lowersError } =
    useQuery({
      queryKey: ['catalog', 'lowers'],
      queryFn: () => fetchCatalogItems({ categorySlug: 'lowers' }),
    })

  const { data: categories = [] } =
    useQuery({
      queryKey: ['catalog', 'categories'],
      queryFn: fetchCategories,
    })

  const catalogLoading = uppersLoading || lowersLoading
  const catalogError = uppersError || lowersError

  const upperFilters = ['All', ...(categories.find((c) => c.slug === 'uppers')?.subcategories.map((s) => s.name) ?? [])]
  const lowerFilters = ['All', ...(categories.find((c) => c.slug === 'lowers')?.subcategories.map((s) => s.name) ?? [])]

  // ── Selection ─────────────────────────────────────────────────────────────────
  const [selectedUppers, setSelectedUppers] = useState<Set<string>>(new Set())
  const [selectedLowers, setSelectedLowers] = useState<Set<string>>(new Set())

  // ── UI navigation ─────────────────────────────────────────────────────────────
  const [activeTab, setActiveTab] = useState<'uppers' | 'lowers'>('uppers')
  const [upperFilter, setUpperFilter] = useState('All')
  const [lowerFilter, setLowerFilter] = useState('All')

  // ── Photo upload ──────────────────────────────────────────────────────────────
  const [photoPreview, setPhotoPreview] = useState<string | null>(null)
  const [photoType, setPhotoType] = useState<'uppers' | 'lowers' | null>(null)
  const [showPhotoTypeModal, setShowPhotoTypeModal] = useState(false)
  const [isDragging, setIsDragging] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  // ── Generation ────────────────────────────────────────────────────────────────
  const [isGenerating, setIsGenerating] = useState(false)
  const [result, setResult] = useState<GenerateOutfitResponse | null>(() => {
    if (typeof window === 'undefined') return null
    try {
      const cached = sessionStorage.getItem('workspace_result')
      return cached ? JSON.parse(cached) : null
    } catch { return null }
  })
  const [generateError, setGenerateError] = useState<string | null>(null)
  const [isSaved, setIsSaved] = useState<boolean>(() => {
    if (typeof window === 'undefined') return false
    try {
      const cached = sessionStorage.getItem('workspace_result')
      if (!cached) return false
      const r: GenerateOutfitResponse = JSON.parse(cached)
      return isLookSaved(r.recommendation_id)
    } catch { return false }
  })
  const [toast, setToast] = useState<string | null>(null)

  // ── Computed ──────────────────────────────────────────────────────────────────
  const totalSelected = selectedUppers.size + selectedLowers.size

  useEffect(() => {
    window.dispatchEvent(
      new CustomEvent('workspace-selection-change', { detail: { count: totalSelected } })
    )
  }, [totalSelected])

  // Can generate if: catalog items selected, OR photo uploaded with type chosen
  const photoOnlyMode = photoPreview !== null && totalSelected === 0 && photoType !== null
  const canGenerate = (totalSelected > 0 || photoOnlyMode) && !isGenerating

  const filteredUppers =
    upperFilter === 'All' ? uppers : uppers.filter((i) => i.category === upperFilter)
  const filteredLowers =
    lowerFilter === 'All' ? lowers : lowers.filter((i) => i.category === lowerFilter)

  // ── Handlers ──────────────────────────────────────────────────────────────────
  const toggleUpper = (id: string) =>
    setSelectedUppers((prev) => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })

  const toggleLower = (id: string) =>
    setSelectedLowers((prev) => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })

  const handlePhotoFile = useCallback((file: File) => {
    if (!file.type.startsWith('image/')) return
    setPhotoPreview(URL.createObjectURL(file))
  }, [])

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) handlePhotoFile(file)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
    const file = e.dataTransfer.files?.[0]
    if (file) handlePhotoFile(file)
  }

  const removePhoto = (e: React.MouseEvent) => {
    e.stopPropagation()
    setPhotoPreview(null)
    setPhotoType(null)
    if (fileInputRef.current) fileInputRef.current.value = ''
  }

  const handlePhotoTypeSelect = (type: 'uppers' | 'lowers') => {
    setPhotoType(type)
    setShowPhotoTypeModal(false)
    fileInputRef.current?.click()
  }

  // ── Toast helper ──────────────────────────────────────────────────────────────
  const showToast = (msg: string) => {
    setToast(msg)
    setTimeout(() => setToast(null), 2500)
  }

  // ── Core generation (accepts explicit IDs so Redo can bypass selection state) ─
  const _doGenerate = async (ids: string[], pt?: 'uppers' | 'lowers') => {
    setIsGenerating(true)
    setResult(null)
    setGenerateError(null)
    try {
      const data = await generateOutfit(ids, { photoType: pt })
      setResult(data)
      setIsSaved(isLookSaved(data.recommendation_id))
      sessionStorage.setItem('workspace_result', JSON.stringify(data))
      sessionStorage.setItem('workspace_last_ids', JSON.stringify(ids))
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Something went wrong'
      setGenerateError(msg)
      console.error('[generate]', err)
    } finally {
      setIsGenerating(false)
    }
  }

  const handleGenerate = () => {
    if (!canGenerate) return
    const ids = [...Array.from(selectedUppers), ...Array.from(selectedLowers)]
    _doGenerate(ids, photoOnlyMode ? photoType! : undefined)
  }

  const handleRedo = () => {
    if (canGenerate) {
      handleGenerate()
      return
    }
    // No items selected (e.g. navigated back) — re-use last generation's IDs
    try {
      const stored = sessionStorage.getItem('workspace_last_ids')
      if (stored) {
        const ids: string[] = JSON.parse(stored)
        _doGenerate(ids)
      }
    } catch { /* ignore */ }
  }

  const handleShare = async () => {
    if (!result) return
    const shareText = `${result.aesthetic}\n\n${result.description}\n\nStyled by StyLoBuddy`
    const shareData = {
      title: `${result.aesthetic} — StyLoBuddy`,
      text: result.description,
      url: window.location.href,
    }
    try {
      if (typeof navigator.share === 'function' && navigator.canShare?.(shareData)) {
        await navigator.share(shareData)
      } else {
        await navigator.clipboard.writeText(shareText)
        showToast('Copied to clipboard')
      }
    } catch {
      // User cancelled native share — fall back to clipboard
      try {
        await navigator.clipboard.writeText(shareText)
        showToast('Copied to clipboard')
      } catch {
        showToast('Could not share — try copying manually')
      }
    }
  }

  // ── First outfit combination (used in result panel) ───────────────────────────
  const firstCombo = result?.combinations?.[0]

  // ── Auto-suggest heading helpers ──────────────────────────────────────────────
  const suggestLabel =
    result?.suggest_mode === 'lowers'
      ? 'Best Matching Bottoms'
      : result?.suggest_mode === 'uppers'
      ? 'Best Matching Tops'
      : null

  // ── Render ────────────────────────────────────────────────────────────────────
  return (
    <main className="h-screen overflow-hidden flex flex-col bg-surface-container-low pt-[72px]">

      {/* ── Action bar ──────────────────────────────────────────────────────── */}
      <div className="flex-none bg-surface/80 backdrop-blur-xl border-b border-outline-variant/10 z-40">
        <div className="max-w-[1440px] mx-auto px-8 md:px-12 h-14 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <h1 className="font-headline font-light text-sm tracking-[0.08rem] text-on-surface">
              Workspace
            </h1>
            <div className="h-3.5 w-px bg-outline-variant/40" />
            <span className="font-label text-[0.625rem] uppercase tracking-widest text-outline">
              Outfit Studio
            </span>
            {totalSelected > 0 && (
              <div className="flex items-center gap-1.5 px-3 py-1 bg-secondary-container rounded-full">
                <span className="w-1.5 h-1.5 bg-secondary rounded-full animate-pulse" />
                <span className="font-label text-[0.625rem] text-on-secondary-container uppercase tracking-widest">
                  {totalSelected} {totalSelected === 1 ? 'piece' : 'pieces'} selected
                </span>
              </div>
            )}
          </div>

          <button
            onClick={handleGenerate}
            disabled={!canGenerate}
            className={`flex items-center gap-2.5 px-8 py-2.5 rounded-full font-headline uppercase tracking-[0.15rem] text-[0.6875rem] transition-all duration-[400ms] ease-editorial ${
              canGenerate
                ? 'bg-on-surface text-surface shadow-lg hover:bg-primary hover:shadow-xl hover:scale-[1.02] cursor-pointer'
                : 'bg-surface-container text-outline cursor-not-allowed'
            }`}
          >
            {isGenerating ? (
              <>
                <span className="w-3.5 h-3.5 border-2 border-current/30 border-t-current rounded-full animate-spin" />
                <span>Generating</span>
              </>
            ) : (
              <>
                <span>Generate Outfit</span>
                <span className="material-symbols-outlined text-[0.875rem]">magic_button</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* ── Two-panel content ────────────────────────────────────────────────── */}
      <div className="flex-1 flex overflow-hidden max-w-[1440px] mx-auto w-full">

        {/* ── LEFT: Selection panel ─────────────────────────────────────────── */}
        <div className="flex-1 min-w-0 flex flex-col overflow-y-auto editorial-scrollbar border-r border-outline-variant/10 bg-surface">

          {/* Photo upload */}
          <div className="px-8 md:px-12 pt-8 pb-5 flex-none">
            <div
              onDragOver={(e) => { e.preventDefault(); setIsDragging(true) }}
              onDragLeave={() => setIsDragging(false)}
              onDrop={handleDrop}
              onClick={() => { if (!photoPreview) setShowPhotoTypeModal(true) }}
              className={`relative rounded-2xl border-2 border-dashed transition-all duration-[400ms] ease-editorial overflow-hidden ${
                photoPreview
                  ? 'border-secondary/25 bg-surface-container h-[108px]'
                  : isDragging
                  ? 'border-secondary bg-secondary-container/25 h-[128px] cursor-copy'
                  : 'border-outline-variant/40 bg-surface-container-low h-[128px] cursor-pointer hover:border-on-surface-variant hover:bg-surface-container'
              }`}
            >
              {photoPreview ? (
                <div className="flex items-center gap-5 h-full px-6">
                  <div className="relative flex-none">
                    <img src={photoPreview} alt="Your photo" className="w-16 h-16 object-cover rounded-full ring-2 ring-secondary/30" />
                    <div className="absolute -bottom-0.5 -right-0.5 w-5 h-5 bg-secondary rounded-full flex items-center justify-center">
                      <span className="material-symbols-outlined text-on-secondary" style={{ fontSize: '0.65rem', fontVariationSettings: "'FILL' 1" }}>check</span>
                    </div>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-headline font-semibold text-on-surface text-sm">Photo ready</p>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="px-2.5 py-0.5 bg-secondary/15 text-secondary rounded-full font-label text-[0.5625rem] uppercase tracking-widest">
                        {photoType === 'uppers' ? 'Top' : 'Bottom'}
                      </span>
                      <span className="font-label text-outline text-[0.625rem]">Outfit will be tailored to your silhouette</span>
                    </div>
                  </div>
                  <button onClick={removePhoto} className="flex-none w-8 h-8 rounded-full flex items-center justify-center text-outline hover:text-on-surface hover:bg-surface-container-high transition-all duration-[400ms]">
                    <span className="material-symbols-outlined text-[1rem]">close</span>
                  </button>
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center h-full gap-2 pointer-events-none">
                  <div className={`w-9 h-9 rounded-full flex items-center justify-center transition-all duration-[400ms] ${isDragging ? 'bg-secondary text-on-secondary scale-110' : 'bg-surface-container text-on-surface-variant'}`}>
                    <span className="material-symbols-outlined text-[1.1rem]">{isDragging ? 'file_download' : 'person_add'}</span>
                  </div>
                  <p className="font-label text-[0.6875rem] text-on-surface uppercase tracking-widest">{isDragging ? 'Drop to upload' : 'Upload your photo'}</p>
                  {!isDragging && <p className="font-label text-[0.625rem] text-outline">Drag & drop or click · JPG, PNG, WEBP</p>}
                </div>
              )}
            </div>
            <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={handleFileInput} />
          </div>

          {/* Tabs */}
          <div className="px-8 md:px-12 pb-4 flex-none">
            <div className="flex items-center gap-1 p-1 bg-surface-container rounded-xl w-fit mb-5">
              {(['uppers', 'lowers'] as const).map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`relative px-7 py-2 rounded-lg font-headline uppercase tracking-[0.12rem] text-[0.6875rem] transition-all duration-[400ms] ease-editorial ${
                    activeTab === tab ? 'bg-surface text-on-surface shadow-sm' : 'text-outline hover:text-on-surface-variant'
                  }`}
                >
                  {tab}
                  {tab === 'uppers' && selectedUppers.size > 0 && (
                    <span className="absolute -top-1.5 -right-1.5 w-4 h-4 bg-secondary text-on-secondary rounded-full text-[0.5rem] flex items-center justify-center font-bold">{selectedUppers.size}</span>
                  )}
                  {tab === 'lowers' && selectedLowers.size > 0 && (
                    <span className="absolute -top-1.5 -right-1.5 w-4 h-4 bg-secondary text-on-secondary rounded-full text-[0.5rem] flex items-center justify-center font-bold">{selectedLowers.size}</span>
                  )}
                </button>
              ))}
            </div>

            {/* Filter chips — dynamic from API */}
            <div className="flex gap-2 flex-wrap">
              {(activeTab === 'uppers' ? upperFilters : lowerFilters).map((filter) => {
                const isActive = activeTab === 'uppers' ? upperFilter === filter : lowerFilter === filter
                return (
                  <button
                    key={filter}
                    onClick={() => activeTab === 'uppers' ? setUpperFilter(filter) : setLowerFilter(filter)}
                    className={`px-4 py-1.5 rounded-full font-label text-[0.6875rem] uppercase tracking-widest transition-all duration-[400ms] ease-editorial ${
                      isActive ? 'bg-on-surface text-surface' : 'bg-surface-container text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface'
                    }`}
                  >
                    {filter}
                  </button>
                )
              })}
            </div>
          </div>

          {/* Section header */}
          <div className="px-8 md:px-12 pb-6 flex-none flex items-end justify-between">
            <div>
              <div className="flex items-center gap-3 mb-1.5">
                <div className="h-px w-8 bg-on-surface" />
                <span className="font-label text-[0.625rem] uppercase tracking-[0.25rem] text-outline">
                  {activeTab === 'uppers' ? 'Top pieces' : 'Bottom pieces'}
                </span>
              </div>
              <h2 className="font-headline text-[2rem] font-light tracking-tight text-on-surface">
                {activeTab === 'uppers' ? 'Uppers' : 'Lowers'}
              </h2>
            </div>
            {!catalogLoading && (
              <span className="font-label text-[0.625rem] uppercase tracking-widest text-outline pb-1">
                {(activeTab === 'uppers' ? filteredUppers : filteredLowers).length} pieces
              </span>
            )}
          </div>

          {/* Clothing grid */}
          <div className="px-8 md:px-12 pb-12">
            {catalogLoading ? (
              <GridSkeleton />
            ) : catalogError ? (
              <div className="py-20 flex flex-col items-center gap-3 text-center">
                <span className="material-symbols-outlined text-4xl text-outline-variant">cloud_off</span>
                <p className="font-label text-[0.75rem] text-outline uppercase tracking-widest">Could not load catalog. Make sure the backend is running.</p>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-5">
                {(activeTab === 'uppers' ? filteredUppers : filteredLowers).map((item) => (
                  <ClothingCard
                    key={item.id}
                    item={item}
                    isSelected={activeTab === 'uppers' ? selectedUppers.has(item.id) : selectedLowers.has(item.id)}
                    onToggle={() => activeTab === 'uppers' ? toggleUpper(item.id) : toggleLower(item.id)}
                  />
                ))}
                {(activeTab === 'uppers' ? filteredUppers : filteredLowers).length === 0 && (
                  <div className="col-span-full py-20 flex flex-col items-center gap-3 text-center">
                    <span className="material-symbols-outlined text-4xl text-outline-variant">search_off</span>
                    <p className="font-label text-[0.75rem] text-outline uppercase tracking-widest">No pieces in this category yet</p>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

        {/* ── RIGHT: Output panel ───────────────────────────────────────────── */}
        <div className="w-[340px] flex-none flex flex-col overflow-y-auto editorial-scrollbar bg-surface">

          {/* ── State: placeholder ── */}
          {!result && !isGenerating && (
            <div className="flex-1 flex flex-col items-center justify-center px-8 py-10 text-center gap-6">
              <div className="relative">
                <div className="w-20 h-20 rounded-full bg-surface-container flex items-center justify-center">
                  <span className="material-symbols-outlined text-3xl text-outline-variant">auto_awesome</span>
                </div>
                {totalSelected > 0 && (
                  <div className="absolute -top-1 -right-1 w-6 h-6 bg-secondary rounded-full flex items-center justify-center shadow">
                    <span className="text-[0.5625rem] font-bold text-on-secondary">{totalSelected}</span>
                  </div>
                )}
              </div>
              <div className="space-y-2">
                <p className="font-headline font-light text-base text-on-surface tracking-tight">
                  {totalSelected === 0 ? 'Select pieces to begin' : `${totalSelected} ${totalSelected === 1 ? 'piece' : 'pieces'} chosen`}
                </p>
                <p className="font-label text-[0.75rem] text-outline leading-relaxed">
                  {totalSelected === 0
                    ? 'Pick items from the grid. Upload your photo for a personalised result.'
                    : 'Hit Generate Outfit when ready to see how your selection comes together.'}
                </p>
              </div>

              {/* Selected items summary chips */}
              {totalSelected > 0 && (
                <div className="w-full space-y-2">
                  {Array.from(selectedUppers).map((id) => {
                    const item = uppers.find((u) => u.id === id)
                    if (!item) return null
                    return (
                      <div key={`u-${id}`} className="flex items-center gap-3 px-3 py-2.5 bg-surface-container rounded-xl">
                        <img src={item.image_url} alt={item.name} className="w-9 h-9 object-cover rounded-lg flex-none" />
                        <div className="flex-1 min-w-0">
                          <p className="font-label text-[0.5625rem] uppercase tracking-widest text-outline">Upper</p>
                          <p className="font-headline text-[0.75rem] text-on-surface font-semibold truncate">{item.name}</p>
                        </div>
                        <button onClick={() => toggleUpper(id)} className="flex-none text-outline hover:text-on-surface transition-colors duration-[400ms]">
                          <span className="material-symbols-outlined text-sm">close</span>
                        </button>
                      </div>
                    )
                  })}
                  {Array.from(selectedLowers).map((id) => {
                    const item = lowers.find((l) => l.id === id)
                    if (!item) return null
                    return (
                      <div key={`l-${id}`} className="flex items-center gap-3 px-3 py-2.5 bg-surface-container rounded-xl">
                        <img src={item.image_url} alt={item.name} className="w-9 h-9 object-cover rounded-lg flex-none" />
                        <div className="flex-1 min-w-0">
                          <p className="font-label text-[0.5625rem] uppercase tracking-widest text-outline">Lower</p>
                          <p className="font-headline text-[0.75rem] text-on-surface font-semibold truncate">{item.name}</p>
                        </div>
                        <button onClick={() => toggleLower(id)} className="flex-none text-outline hover:text-on-surface transition-colors duration-[400ms]">
                          <span className="material-symbols-outlined text-sm">close</span>
                        </button>
                      </div>
                    )
                  })}
                </div>
              )}

              {/* Error state */}
              {generateError && (
                <div className="w-full px-4 py-3 bg-error/10 rounded-xl flex items-start gap-2.5">
                  <span className="material-symbols-outlined text-error text-base mt-0.5">error</span>
                  <p className="font-label text-[0.6875rem] text-error leading-relaxed">{generateError}</p>
                </div>
              )}
            </div>
          )}

          {/* ── State: generating ── */}
          {isGenerating && (
            <div className="flex-1 flex flex-col items-center justify-center px-8 gap-7">
              <div className="relative w-20 h-20">
                <div className="absolute inset-0 rounded-full border border-outline-variant/20" />
                <div className="absolute inset-0 rounded-full border-2 border-transparent border-t-secondary animate-spin" />
                <div className="absolute inset-2.5 rounded-full border-2 border-transparent border-t-secondary/40 animate-spin" style={{ animationDuration: '1.5s', animationDirection: 'reverse' }} />
                <div className="absolute inset-0 flex items-center justify-center">
                  <span className="material-symbols-outlined text-xl text-secondary" style={{ fontVariationSettings: "'FILL' 1" }}>auto_awesome</span>
                </div>
              </div>
              <div className="text-center space-y-1.5">
                <p className="font-headline font-light text-base text-on-surface">Curating your look</p>
                <p className="font-label text-[0.6875rem] text-outline">Analysing silhouette & tonal harmony</p>
              </div>
              <div className="w-full space-y-3">
                <div className="w-full h-44 skeleton" />
                <div className="h-4 w-1/2 skeleton" />
                <div className="h-3 w-full skeleton" />
                <div className="h-3 w-5/6 skeleton" />
                <div className="flex gap-2 mt-1">
                  {[1, 2, 3, 4].map((i) => <div key={i} className="w-9 h-9 skeleton rounded-lg" />)}
                </div>
              </div>
            </div>
          )}

          {/* ── State: result ── */}
          {result && !isGenerating && (
            <div className="flex-1 flex flex-col slide-in-right">

              {/* Outfit visual */}
              <div className="relative h-[220px] bg-surface-container-low flex-none overflow-hidden">
                {photoPreview ? (
                  <img src={photoPreview} alt="Your styled look" className="w-full h-full object-cover" />
                ) : firstCombo && firstCombo.items[0]?.image_url ? (
                  /* Show the hero item from the first combination */
                  <img src={firstCombo.items[0].image_url} alt={firstCombo.outfit_name} className="w-full h-full object-cover" />
                ) : (
                  <div className="flex flex-col items-center justify-center h-full gap-3 text-center px-8">
                    <span className="material-symbols-outlined text-5xl text-outline-variant" style={{ fontVariationSettings: "'FILL' 1" }}>checkroom</span>
                    <p className="font-label text-[0.6875rem] text-outline uppercase tracking-widest">Outfit composed</p>
                  </div>
                )}
                <div className="absolute top-4 left-4 px-3 py-1 glass-nav rounded-full">
                  <span className="font-label text-[0.625rem] uppercase tracking-widest text-on-surface">{result.aesthetic}</span>
                </div>
              </div>

              {/* Result content */}
              <div className="p-5 space-y-5">

                {/* Aesthetic */}
                <div>
                  <div className="flex items-center gap-2 mb-2">
                    <div className="h-px w-6 bg-on-surface" />
                    <span className="font-label text-[0.5625rem] uppercase tracking-[0.2rem] text-outline">Your Aesthetic</span>
                  </div>
                  <h3 className="font-headline text-xl font-light text-on-surface tracking-tight">{result.aesthetic}</h3>
                </div>

                {/* Description */}
                <p className="font-body text-[0.75rem] text-on-surface-variant leading-relaxed">{result.description}</p>

                {/* ── Outfit combinations ── */}
                {result.combinations.length > 0 && (
                  <div className="space-y-4">
                    <p className="font-label text-[0.5625rem] uppercase tracking-widest text-outline">
                      {suggestLabel ?? firstCombo?.outfit_name}
                    </p>

                    {suggestLabel ? (
                      /* Auto-suggest: show all matches as separate rows */
                      result.combinations.map((combo, idx) => {
                        /*
                         * Find the catalog-suggested item by role:
                         * - suggest_mode === 'lowers' → we suggested bottoms, so find role 'bottom'
                         * - suggest_mode === 'uppers' → we suggested tops, so find role 'top'
                         * Fall back to the last item if no role match.
                         * Never use selected-IDs check — those Sets are empty after navigation.
                         */
                        const suggestedRole = result.suggest_mode === 'lowers' ? 'bottom' : 'top'
                        const suggestedItem =
                          combo.items.find((oi) => oi.role_in_outfit === suggestedRole) ??
                          combo.items[combo.items.length - 1]
                        return (
                          <div
                            key={combo.outfit_name + idx}
                            className="flex items-center gap-3 p-2.5 bg-surface-container rounded-xl"
                          >
                            <div className="flex-none w-14 h-[4.5rem] rounded-lg overflow-hidden bg-surface-container-high">
                              <img
                                src={suggestedItem.image_url}
                                alt={suggestedItem.item_name}
                                className="w-full h-full object-cover"
                              />
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-1.5 mb-0.5">
                                <span className="w-4 h-4 rounded-full bg-secondary/20 text-secondary flex items-center justify-center font-bold text-[0.5rem]">
                                  {idx + 1}
                                </span>
                                <p className="font-headline text-[0.6875rem] text-on-surface font-semibold truncate">
                                  {suggestedItem.item_name}
                                </p>
                              </div>
                              <p className="font-label text-[0.5625rem] text-outline leading-relaxed line-clamp-2">
                                {combo.style_description}
                              </p>
                            </div>
                          </div>
                        )
                      })
                    ) : (
                      /* Normal mode: show ALL combinations, each as a labeled outfit card */
                      result.combinations.map((combo, idx) => (
                        <div key={combo.outfit_name + idx} className="space-y-2">
                          <div className="flex items-center gap-2">
                            <span className="w-5 h-5 rounded-full bg-primary/15 text-primary flex items-center justify-center font-bold text-[0.625rem]">
                              {idx + 1}
                            </span>
                            <p className="font-headline text-[0.75rem] text-on-surface font-semibold">
                              {combo.outfit_name}
                            </p>
                            <span className="ml-auto font-label text-[0.5625rem] text-outline">
                              {Math.round(combo.confidence_score * 100)}% match
                            </span>
                          </div>
                          <div className="grid grid-cols-3 gap-2">
                            {combo.items.map((oi) => (
                              <div key={oi.item_id} className="flex flex-col gap-1">
                                <div className="aspect-[3/4] rounded-lg overflow-hidden bg-surface-container">
                                  <img
                                    src={oi.image_url}
                                    alt={oi.item_name}
                                    className="w-full h-full object-cover"
                                  />
                                </div>
                                <p className="font-label text-[0.5rem] uppercase tracking-widest text-outline text-center truncate">
                                  {oi.role_in_outfit}
                                </p>
                              </div>
                            ))}
                          </div>
                          {combo.style_description && (
                            <p className="font-label text-[0.5625rem] text-outline/80 leading-relaxed">
                              {combo.style_description}
                            </p>
                          )}
                          {idx < result.combinations.length - 1 && (
                            <hr className="border-outline/10 my-3" />
                          )}
                        </div>
                      ))
                    )}
                  </div>
                )}

                {/* Colour palette */}
                <div>
                  <p className="font-label text-[0.5625rem] uppercase tracking-widest text-outline mb-2.5">Colour Palette</p>
                  <div className="flex gap-2">
                    {result.palette.map((color, i) => (
                      <div
                        key={i}
                        className="w-9 h-9 rounded-lg shadow-sm ring-1 ring-black/5 transition-transform duration-[400ms] hover:scale-110"
                        style={{ backgroundColor: color }}
                        title={color}
                      />
                    ))}
                  </div>
                </div>

                {/* Tags */}
                <div className="flex flex-wrap gap-1.5">
                  {result.tags.map((tag) => (
                    <span key={tag} className="px-3 py-1 bg-surface-container rounded-full font-label text-[0.5625rem] uppercase tracking-widest text-on-surface-variant">
                      {tag}
                    </span>
                  ))}
                </div>

                {/* Styling tips */}
                {result.styling_tips.length > 0 && (
                  <div>
                    <p className="font-label text-[0.5625rem] uppercase tracking-widest text-outline mb-2.5">Styling Tips</p>
                    <ul className="space-y-2">
                      {result.styling_tips.map((tip, i) => (
                        <li key={i} className="flex items-start gap-2">
                          <span className="mt-[3px] w-1 h-1 rounded-full bg-secondary flex-none" />
                          <p className="font-label text-[0.625rem] text-on-surface-variant leading-relaxed">{tip}</p>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {/* Actions */}
                <div className="space-y-2.5 pt-1">
                  <button
                    onClick={() => {
                      if (result && !isSaved) {
                        saveLook(result)
                        setIsSaved(true)
                      }
                    }}
                    disabled={isSaved}
                    className={`w-full flex items-center justify-center gap-2.5 py-3 rounded-full font-headline uppercase tracking-[0.15rem] text-[0.6875rem] transition-all duration-[400ms] ease-editorial ${
                      isSaved
                        ? 'bg-secondary/20 text-secondary cursor-default'
                        : 'bg-on-surface text-surface hover:bg-primary'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[0.875rem]" style={{ fontVariationSettings: isSaved ? "'FILL' 1" : "'FILL' 0" }}>bookmark</span>
                    {isSaved ? 'Saved' : 'Save Look'}
                  </button>
                  <div className="flex gap-2">
                    <button
                      onClick={handleShare}
                      className="flex-1 flex items-center justify-center gap-1.5 py-2.5 border border-outline-variant/40 rounded-full font-headline uppercase tracking-[0.1rem] text-[0.625rem] text-on-surface-variant hover:border-outline hover:text-on-surface transition-all duration-[400ms]"
                    >
                      <span className="material-symbols-outlined text-[0.875rem]">share</span>
                      Share
                    </button>
                    <button
                      onClick={handleRedo}
                      className="flex-1 flex items-center justify-center gap-1.5 py-2.5 border border-outline-variant/40 rounded-full font-headline uppercase tracking-[0.1rem] text-[0.625rem] text-on-surface-variant hover:border-outline hover:text-on-surface transition-all duration-[400ms]"
                    >
                      <span className="material-symbols-outlined text-[0.875rem]">refresh</span>
                      Redo
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ── Toast notification ──────────────────────────────────────────── */}
      {toast && (
        <div className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50 px-5 py-3 bg-on-surface text-surface rounded-full font-label text-[0.6875rem] uppercase tracking-widest shadow-xl flex items-center gap-2 pointer-events-none animate-fade-in">
          <span className="material-symbols-outlined text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>check_circle</span>
          {toast}
        </div>
      )}

      {/* ── Photo type modal ──────────────────────────────────────────────── */}
      {showPhotoTypeModal && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm"
          onClick={() => setShowPhotoTypeModal(false)}
        >
          <div
            className="bg-surface rounded-3xl shadow-2xl w-[340px] p-8 flex flex-col gap-6"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="text-center space-y-1.5">
              <div className="w-12 h-12 rounded-full bg-surface-container flex items-center justify-center mx-auto mb-3">
                <span className="material-symbols-outlined text-2xl text-on-surface-variant">upload</span>
              </div>
              <h3 className="font-headline text-lg font-light text-on-surface tracking-tight">
                What are you uploading?
              </h3>
              <p className="font-label text-[0.6875rem] text-outline leading-relaxed">
                We'll suggest the best matching pieces from the catalog.
              </p>
            </div>

            {/* Options */}
            <div className="flex flex-col gap-3">
              <button
                onClick={() => handlePhotoTypeSelect('uppers')}
                className="flex items-center gap-4 px-5 py-4 rounded-2xl border border-outline-variant/40 hover:border-on-surface hover:bg-surface-container transition-all duration-[400ms] ease-editorial group text-left"
              >
                <div className="w-10 h-10 rounded-xl bg-surface-container flex items-center justify-center flex-none group-hover:bg-surface-container-high transition-all duration-[400ms]">
                  <span className="material-symbols-outlined text-on-surface-variant text-xl">checkroom</span>
                </div>
                <div>
                  <p className="font-headline text-sm font-semibold text-on-surface">A Top</p>
                  <p className="font-label text-[0.625rem] text-outline uppercase tracking-widest mt-0.5">
                    Shirt · T-Shirt · Knitwear · Jacket
                  </p>
                </div>
              </button>

              <button
                onClick={() => handlePhotoTypeSelect('lowers')}
                className="flex items-center gap-4 px-5 py-4 rounded-2xl border border-outline-variant/40 hover:border-on-surface hover:bg-surface-container transition-all duration-[400ms] ease-editorial group text-left"
              >
                <div className="w-10 h-10 rounded-xl bg-surface-container flex items-center justify-center flex-none group-hover:bg-surface-container-high transition-all duration-[400ms]">
                  <span className="material-symbols-outlined text-on-surface-variant text-xl">airline_seat_legroom_normal</span>
                </div>
                <div>
                  <p className="font-headline text-sm font-semibold text-on-surface">A Bottom</p>
                  <p className="font-label text-[0.625rem] text-outline uppercase tracking-widest mt-0.5">
                    Jeans · Trousers · Chinos · Shorts
                  </p>
                </div>
              </button>
            </div>

            <button
              onClick={() => setShowPhotoTypeModal(false)}
              className="font-label text-[0.625rem] text-outline uppercase tracking-widest text-center hover:text-on-surface transition-colors duration-[400ms]"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </main>
  )
}
