'use client'

import { useEffect, useRef, useState } from 'react'

const ITEMS = [
  {
    title: 'Midnight Minimalist',
    profile: 'Style Profile A2',
    src: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBebX5UKf45NqO4hLU-j7tttv0YJE8L9WrKy2keO81D3A1DEToFCskFp15m_H6LvIEE8DE5vEjd00X6XnlK36Db3uIx2WFCP1FKZbkocjenDdme22y4wOBk371Ye2UJpXBiO2cUB-8FOC3avAxJsY1ZiEmPSIgBL3wI6vqmfEWqSVBN2btJo5XT8I1CgvGiwtITR7aM7jkOIzIs91pQYNqx8K0EpeTAyBEfc4O6fNzaIJLCxE448x4I9EISX6D58mzWe12YmLDZk2X3',
    featured: false,
  },
  {
    title: 'The Sculpted Form',
    profile: 'Style Profile C4',
    src: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCTYDFcN7qEvGAdseABds5QaHcf9WAU_WDzH1wj_lei3_fCcmU-mSnVA0ZQCp-4j7SduX3JPFmu_tqov1mmmIqmTj6t8_udpWDPEjy7eNQKtqmv94ew2bIbFFiy5SIxx2Tx0U9VEhLmPsY9EKTmipg9XSNSiJqOgFR9s4f3pEWF3SJnmb3Tdtt3X7bHYdVdg30v5YtI4kgJpYSrU1w6ooBU_KpH2ObFrugyAX2WWArmCR-TTaxu-FSPYxYZIDKj432LkPB_G3WyQ_vF',
    featured: true,
  },
  {
    title: 'Textural Elements',
    profile: 'Style Profile B1',
    src: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAezT9SAhAqORZclHWkGDkL3mhn82XdRDoGMEoiTk2O7amkGxWNhth9rrM2twPmZtekJ2H65GgluDqwOniA9BeiI9UvXln4Dcn2m9zSieni5VcJICck7oWQ1Ucjj9sPgVVncWshzECyOyoqV_tz_tY8NGgj9Bk5qiQWSbxoGw1eG--NItS6KoNfW8Fxh5fF0vg6HnBtesZ61g0U-5MEbX7w20xoc62L73afxaZt4-xWO6v89m3JRq9DgiNxS_HQkgqdGQJzEep8kile',
    featured: false,
  },
]

export default function LookbookCarousel() {
  const [active, setActive] = useState(1)
  const containerRef = useRef<HTMLDivElement>(null)

  const scrollToIndex = (index: number) => {
    const container = containerRef.current
    if (!container) return
    const child = container.children[index] as HTMLElement
    const target = child.offsetLeft - (container.clientWidth / 2) + (child.offsetWidth / 2)
    container.scrollTo({ left: Math.max(0, target), behavior: 'smooth' })
    setActive(index)
  }

  /* Sync dot indicator with free-scroll */
  useEffect(() => {
    const container = containerRef.current
    if (!container) return
    const handler = () => {
      const center = container.scrollLeft + container.clientWidth / 2
      let closest = 0
      let closestDist = Infinity
      Array.from(container.children).forEach((child, i) => {
        const el = child as HTMLElement
        const childCenter = el.offsetLeft + el.offsetWidth / 2
        const dist = Math.abs(center - childCenter)
        if (dist < closestDist) { closestDist = dist; closest = i }
      })
      setActive(closest)
    }
    container.addEventListener('scroll', handler, { passive: true })
    return () => container.removeEventListener('scroll', handler)
  }, [])

  /* Initialise scrolled to featured (middle) item */
  useEffect(() => { scrollToIndex(1) }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <section className="py-32 bg-surface">
      <div className="max-w-[1440px] mx-auto px-6 md:px-12">
        {/* Section header */}
        <div className="flex items-center justify-between mb-16">
          <div className="flex items-center gap-4">
            <div className="h-[1px] w-12 bg-on-surface" />
            <span className="font-label uppercase tracking-[0.3rem] text-xs">
              Curated Edit
            </span>
          </div>

          {/* Arrow controls */}
          <div className="flex gap-3">
            <button
              onClick={() => scrollToIndex(Math.max(0, active - 1))}
              disabled={active === 0}
              aria-label="Previous"
              className="w-10 h-10 rounded-full border border-[#ddd] flex items-center justify-center hover:border-[#1A1A1A] hover:bg-[#1A1A1A] hover:text-white disabled:opacity-25 disabled:cursor-not-allowed transition-all duration-[400ms]"
            >
              <span className="material-symbols-outlined text-[1.1rem]">arrow_back</span>
            </button>
            <button
              onClick={() => scrollToIndex(Math.min(ITEMS.length - 1, active + 1))}
              disabled={active === ITEMS.length - 1}
              aria-label="Next"
              className="w-10 h-10 rounded-full border border-[#ddd] flex items-center justify-center hover:border-[#1A1A1A] hover:bg-[#1A1A1A] hover:text-white disabled:opacity-25 disabled:cursor-not-allowed transition-all duration-[400ms]"
            >
              <span className="material-symbols-outlined text-[1.1rem]">arrow_forward</span>
            </button>
          </div>
        </div>

        {/* Scrollable carousel */}
        <div
          ref={containerRef}
          className="flex overflow-x-auto gap-8 pb-12 no-scrollbar scroll-smooth"
        >
          {ITEMS.map((item, i) => (
            <div
              key={item.title}
              onClick={() => scrollToIndex(i)}
              className={`flex-none cursor-pointer transition-all duration-500 ${
                item.featured ? 'w-[350px] md:w-[500px]' : 'w-[300px] md:w-[450px]'
              } ${active !== i ? 'opacity-60 scale-[0.97]' : 'opacity-100 scale-100'}`}
            >
              <div
                className={`aspect-[3/4] rounded-xl overflow-hidden mb-6 relative group ${
                  item.featured ? 'shadow-2xl' : ''
                }`}
              >
                <img
                  alt={item.title}
                  className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                  src={item.src}
                />
                <div
                  className={`absolute bottom-6 left-6 right-6 p-4 glass-nav rounded-xl transition-opacity duration-[400ms] ${
                    item.featured ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
                  }`}
                >
                  <p className="font-headline font-bold text-on-surface">{item.title}</p>
                  <p className="text-xs font-label text-on-surface-variant uppercase">
                    {item.profile}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Dot indicators */}
        <div className="flex justify-center gap-3 mt-4">
          {ITEMS.map((_, i) => (
            <button
              key={i}
              onClick={() => scrollToIndex(i)}
              aria-label={`Go to slide ${i + 1}`}
              className={`rounded-full transition-all duration-[400ms] ${
                active === i
                  ? 'w-8 h-2 bg-[#1A1A1A]'
                  : 'w-2 h-2 bg-[#1A1A1A]/20 hover:bg-[#1A1A1A]/50'
              }`}
            />
          ))}
        </div>
      </div>
    </section>
  )
}
