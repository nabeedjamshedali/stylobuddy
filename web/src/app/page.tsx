import Link from 'next/link'
import BentoSection from '@/components/BentoSection'
import LookbookCarousel from '@/components/LookbookCarousel'

/* ─── Hero headline words with staggered delays ───────────── */
const LINE_ONE = ['Find', 'Your', 'Perfect']
const LINE_TWO = ['Outfit', 'Instantly.']

export default function LandingPage() {
  return (
    <main className="pt-24">

      {/* ════════════════════════════════════════════════════
          HERO
      ════════════════════════════════════════════════════ */}
      <section className="relative min-h-[921px] flex items-center px-6 md:px-12 py-20 overflow-hidden">

        {/* Background image with Ken Burns motion */}
        <div className="absolute inset-0 z-0 overflow-hidden">
          <img
            alt="Cinematic high fashion"
            className="w-full h-full object-cover object-top ken-burns"
            src="https://lh3.googleusercontent.com/aida-public/AB6AXuAqA-2Okv5E7K3ha9yGo1aSYum6dIbptOisvwSL0vGTTXBxA7mUFZqE9cmn6aQ74IKCQVEI4G8Hnk6uXkBD4jh76siONrjpTUJDlMuvbV0WSJlTV09LtIUwDY29ZruRrkM1HZPDSm326g8urr-isNpAfG7qoMAcwXjtgNOD4IzfQDp-Dyw6MuXZwy0WAJQ46JaUuwQyxiTaFahlV0TQhTX5Y0vcs-bGoZbvYGQ8Wr4uYGI-McQLMdneoMkvU-HulLbN-AklA-eOASxZ"
          />
          {/* Multi-stop gradient: strong left fade + top vignette */}
          <div className="absolute inset-0 bg-gradient-to-r from-black/75 via-black/40 to-transparent" />
          <div className="absolute inset-0 bg-gradient-to-b from-black/20 via-transparent to-black/30" />
        </div>

        {/* Hero copy */}
        <div className="relative z-10 max-w-4xl">
          <span
            className="fade-up font-label uppercase tracking-[0.2rem] text-[0.6875rem] text-white/55 mb-4 block"
            style={{ animationDelay: '0.1s' }}
          >
            Personalized Atelier
          </span>

          <h1 className="font-headline text-5xl md:text-[5rem] leading-[1.1] font-extrabold tracking-tighter text-white mb-8">
            <span className="block">
              {LINE_ONE.map((word, i) => (
                <span
                  key={word}
                  className="word-rise"
                  style={{ animationDelay: `${0.25 + i * 0.11}s` }}
                >
                  {word}{' '}
                </span>
              ))}
            </span>
            <span className="block">
              {LINE_TWO.map((word, i) => (
                <span
                  key={word}
                  className="word-rise"
                  style={{ animationDelay: `${0.25 + (i + LINE_ONE.length) * 0.11}s` }}
                >
                  {word}{' '}
                </span>
              ))}
            </span>
          </h1>

          <p
            className="fade-up font-body text-lg md:text-xl text-white/75 max-w-xl mb-12 font-light leading-relaxed"
            style={{ animationDelay: '0.85s' }}
          >
            Experience the Digital Atelier. Our AI-curated styling engine
            understands your unique silhouette and aesthetic preferences to
            build a timeless wardrobe.
          </p>

          <div
            className="fade-up flex gap-6 items-center"
            style={{ animationDelay: '1.0s' }}
          >
            <Link href="/login">
              <button className="px-12 py-5 bg-white text-[#1A1A1A] rounded-full font-headline tracking-tight text-lg hover:shadow-xl hover:bg-white/90 transition-all duration-[400ms] scale-100 hover:scale-[1.02] active:scale-95">
                Start Styling
              </button>
            </Link>
            <Link
              href="#how-it-works"
              className="fade-up text-white/70 font-headline uppercase tracking-[0.1rem] text-xs hover:text-white transition-colors duration-[400ms] flex items-center gap-2"
            >
              <span className="material-symbols-outlined text-sm">south</span>
              How it works
            </Link>
          </div>
        </div>
      </section>

      {/* ════════════════════════════════════════════════════
          SOCIAL PROOF STRIP
      ════════════════════════════════════════════════════ */}
      <div className="bg-[#1A1A1A] py-10 px-6 md:px-12 overflow-hidden">
        <div className="max-w-[1440px] mx-auto flex flex-wrap justify-center md:justify-between items-center gap-10">
          {[
            { value: '10,000+', label: 'Styles Curated', delay: '0.1s' },
            { value: '500+',    label: 'Luxury Brands',  delay: '0.22s' },
            { value: '4.9★',   label: 'Average Rating', delay: '0.34s' },
            { value: '50K+',   label: 'Members',        delay: '0.46s' },
          ].map(({ value, label, delay }) => (
            <div
              key={label}
              className="stat-reveal flex flex-col items-center md:items-start gap-1"
              style={{ animationDelay: delay }}
            >
              <span className="font-headline text-3xl font-extrabold text-white tracking-tighter">
                {value}
              </span>
              <span className="font-label uppercase tracking-[0.15rem] text-[0.6rem] text-white/40">
                {label}
              </span>
            </div>
          ))}

          {/* Thin dividers between stats on md+ */}
          <div className="hidden md:block h-10 w-[1px] bg-white/10 absolute" aria-hidden />
        </div>
      </div>

      {/* ════════════════════════════════════════════════════
          BENTO GRID — scroll-in micro-interactions
      ════════════════════════════════════════════════════ */}
      <BentoSection />

      {/* ════════════════════════════════════════════════════
          HOW IT WORKS
      ════════════════════════════════════════════════════ */}
      <section id="how-it-works" className="py-32 px-6 md:px-12 bg-surface">
        <div className="max-w-[1440px] mx-auto">
          <div className="mb-20">
            <span className="font-label uppercase tracking-[0.2rem] text-[0.6875rem] text-secondary mb-4 block">
              The Process
            </span>
            <h2 className="font-headline text-4xl font-bold tracking-tight">
              Three steps to your perfect look.
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-0">
            {[
              {
                num: '01',
                icon: 'checkroom',
                title: 'Build Your Wardrobe',
                desc: 'Upload photos of your own clothes or browse and select items directly from our in-app catalogue — or do both.',
              },
              {
                num: '02',
                icon: 'smart_toy',
                title: 'AI Analyses Your Style',
                desc: 'Our model reads your colour palette, body profile, and style history to build your aesthetic DNA fingerprint.',
              },
              {
                num: '03',
                icon: 'style',
                title: 'Get Ranked Outfits',
                desc: 'Receive curated outfit combinations ranked by your personal aesthetic score, ready to wear or refine.',
              },
            ].map((step, i) => (
              <div
                key={step.num}
                className={`relative p-10 md:p-12 group ${
                  i < 2 ? 'md:border-r border-[#e8e6e3]' : ''
                }`}
              >
                {/* Connector line between steps */}
                {i < 2 && (
                  <div className="hidden md:block absolute right-0 top-1/2 -translate-y-1/2 translate-x-1/2 z-10 w-6 h-6 rounded-full border border-[#e8e6e3] bg-surface flex items-center justify-center">
                    <span className="material-symbols-outlined text-[0.9rem] text-outline-variant">
                      arrow_forward
                    </span>
                  </div>
                )}
                <span className="font-headline text-[0.6rem] uppercase tracking-widest text-secondary mb-8 block">
                  {step.num}
                </span>
                <span className="material-symbols-outlined text-3xl text-[#1A1A1A] mb-6 block group-hover:scale-110 transition-transform duration-[400ms]">
                  {step.icon}
                </span>
                <h3 className="font-headline text-xl font-bold mb-4 tracking-tight">
                  {step.title}
                </h3>
                <p className="font-body text-on-surface-variant font-light text-sm leading-relaxed">
                  {step.desc}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ════════════════════════════════════════════════════
          LOOKBOOK CAROUSEL — arrows + dots
      ════════════════════════════════════════════════════ */}
      <LookbookCarousel />

      {/* ════════════════════════════════════════════════════
          FINAL CTA
      ════════════════════════════════════════════════════ */}
      <section className="py-40 bg-surface-container-low text-center overflow-hidden">
        <div className="max-w-2xl mx-auto px-6 relative">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 opacity-5 pointer-events-none select-none">
            <span className="font-headline font-extrabold text-[20rem]">
              STYLO
            </span>
          </div>
          <h2 className="font-headline text-5xl font-bold tracking-tight mb-8">
            Refine Your Aesthetic.
          </h2>
          <p className="font-body text-on-surface-variant mb-12 text-lg">
            Step into a world of curated style tailored to your soul. Your
            digital stylist is ready.
          </p>
          <Link href="/login">
            <button className="px-16 py-6 bg-on-surface text-surface rounded-full font-headline font-bold hover:bg-primary-dim transition-colors duration-[400ms] tracking-wide shadow-xl">
              Begin Your Transformation
            </button>
          </Link>
        </div>
      </section>

      {/* ════════════════════════════════════════════════════
          STICKY MOBILE CTA  (hidden on md+)
      ════════════════════════════════════════════════════ */}
      <div className="fixed bottom-0 left-0 right-0 z-40 px-4 pb-4 pt-3 bg-surface/90 backdrop-blur-md border-t border-[#e8e6e3] md:hidden">
        <Link href="/login" className="block">
          <button className="w-full py-4 bg-[#1A1A1A] text-white rounded-full font-headline tracking-wide text-sm hover:bg-[#333] active:scale-[0.98] transition-all duration-[400ms]">
            Start Styling — It&apos;s Free
          </button>
        </Link>
      </div>

    </main>
  )
}
