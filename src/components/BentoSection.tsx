'use client'

import { useEffect, useRef, useState } from 'react'

export default function BentoSection() {
  const sectionRef = useRef<HTMLDivElement>(null)
  const [visible, setVisible] = useState([false, false, false])

  useEffect(() => {
    const section = sectionRef.current
    if (!section) return
    const cards = section.querySelectorAll<HTMLElement>('[data-bento-card]')
    const observers: IntersectionObserver[] = []

    cards.forEach((card, i) => {
      const observer = new IntersectionObserver(
        ([entry]) => {
          if (entry.isIntersecting) {
            /* stagger via timeout so each card triggers individually */
            setTimeout(() => {
              setVisible(prev => {
                const next = [...prev]
                next[i] = true
                return next
              })
            }, i * 120)
            observer.disconnect()
          }
        },
        { threshold: 0.1, rootMargin: '0px 0px -60px 0px' }
      )
      observer.observe(card)
      observers.push(observer)
    })

    return () => observers.forEach(o => o.disconnect())
  }, [])

  const cardCls = (i: number, base: string) =>
    `${base} transition-[opacity,transform] duration-700 ease-[cubic-bezier(0.2,0,0,1)] bento-glow ${
      visible[i] ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'
    }`

  return (
    <section className="py-32 px-6 md:px-12 bg-surface-container-low">
      <div className="max-w-[1440px] mx-auto" ref={sectionRef}>
        <div className="flex flex-col md:flex-row justify-between items-end mb-20 gap-8">
          <div className="max-w-2xl">
            <h2 className="font-headline text-4xl font-bold tracking-tight mb-6">
              The Curation Process
            </h2>
            <p className="text-on-surface-variant font-light text-lg">
              We blend advanced algorithms with high-fashion sensibilities to
              provide a seamless, editorial styling experience.
            </p>
          </div>
          <div className="hidden md:block">
            <span className="material-symbols-outlined text-4xl text-outline-variant font-light">
              auto_awesome
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-8 h-auto md:h-[800px]">
          {/* Large Feature Card */}
          <div
            data-bento-card="0"
            className={cardCls(
              0,
              'md:col-span-7 bg-surface-container-lowest rounded-xl p-12 flex flex-col justify-between editorial-shadow group overflow-hidden relative'
            )}
          >
            <div className="relative z-10">
              <span className="text-[0.6875rem] uppercase tracking-widest text-secondary font-semibold mb-4 block">
                01 / Intelligence
              </span>
              <h3 className="text-3xl font-headline font-bold mb-6">
                Semantic Silhouette Mapping
              </h3>
              <p className="text-on-surface-variant font-light max-w-md leading-relaxed">
                Our engine analyzes lines and proportions to recommend cuts
                that celebrate your individual form, moving beyond standard
                sizing.
              </p>
            </div>
            <div className="mt-12 h-64 w-full relative rounded-xl overflow-hidden">
              <img
                alt="Textured fabrics"
                className="w-full h-full object-cover grayscale opacity-80 group-hover:grayscale-0 group-hover:scale-105 transition-all duration-700"
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuBO6SyCWsImG51kztL2NmC-s0EtHehCfswGbO3_R6NUiX38EDV4i-IIrsNaF4kV8zoCYjfuDuWnoTla6kTbhb3ZEsxwbAduIUdwQaS9VsB4A7umBNIGnZrD4_1GloIT5yg6T6VzPq3SSordjb-4urSQHOOO7zVcDdD3jOuUHdtQPi4CEDBdckH05NqPKq64TtUyLe0qOBBqFwRFou7GqLcDA8v6CNPAhjegYz7YNEu9baKHCfEPvGDNrbvcFDuw4IoA4igDQlE0kqaW"
              />
            </div>
          </div>

          {/* Side Bento Column */}
          <div className="md:col-span-5 grid grid-rows-2 gap-8">
            <div
              data-bento-card="1"
              className={cardCls(
                1,
                'bg-surface rounded-xl p-10 editorial-shadow flex flex-col justify-center'
              )}
            >
              <span className="material-symbols-outlined text-secondary text-3xl mb-6">
                palette
              </span>
              <h3 className="text-2xl font-headline font-semibold mb-4">
                Tonal Harmony
              </h3>
              <p className="text-on-surface-variant font-light text-sm">
                Automated palette generation based on seasonal trends and your
                personal color theory profile.
              </p>
            </div>

            <div
              data-bento-card="2"
              className={cardCls(
                2,
                'bg-[#1A1A1A] text-white rounded-xl p-10 editorial-shadow flex flex-col justify-center relative overflow-hidden'
              )}
            >
              <div className="relative z-10">
                <h3 className="text-2xl font-headline font-semibold mb-4">
                  Exclusive Access
                </h3>
                <p className="opacity-70 font-light text-sm">
                  Join the atelier for early-access lookbooks and bespoke
                  digital styling consultations.
                </p>
              </div>
              <div className="absolute -right-10 -bottom-10 opacity-10">
                <span className="material-symbols-outlined text-[12rem]">
                  diamond
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
