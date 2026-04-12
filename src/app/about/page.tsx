import Link from 'next/link'

export const metadata = {
  title: 'About — Stylo Buddy',
  description: 'Learn about Stylo Buddy and our mission to make personal styling accessible to everyone.',
}

export default function AboutPage() {
  return (
    <main className="pt-32 pb-24 px-6 md:px-12">
      <div className="max-w-[860px] mx-auto">

        {/* Header */}
        <div className="mb-20">
          <span className="font-label uppercase tracking-[0.2rem] text-[0.6875rem] text-secondary mb-4 block">
            About Us
          </span>
          <h1 className="font-headline text-5xl md:text-[4rem] font-extrabold tracking-tighter text-[#1A1A1A] leading-[1.1] mb-8">
            Dressing well <br />
            <em className="not-italic font-light text-[#5f5e5e]">shouldn't be complicated.</em>
          </h1>
          <div className="h-[1px] w-full bg-[#e8e6e3]" />
        </div>

        {/* Mission */}
        <section className="mb-20">
          <p className="font-body text-xl text-[#1A1A1A] font-light leading-relaxed mb-8">
            Stylo Buddy is a personal styling platform powered by AI. We built
            it on a simple belief: everyone deserves to look and feel their best
            — without needing a private stylist or an unlimited wardrobe budget.
          </p>
          <p className="font-body text-lg text-[#5f5e5e] font-light leading-relaxed">
            Our AI-curated engine analyses your body silhouette, colour palette,
            and style preferences to generate outfit combinations ranked by your
            personal aesthetic DNA. Whether you upload your own clothes or browse
            our in-app catalogue, every recommendation is built around <em>you</em>.
          </p>
        </section>

        {/* Values */}
        <section className="mb-20 grid grid-cols-1 md:grid-cols-3 gap-12">
          {[
            {
              icon: 'person',
              title: 'Personal-First',
              body: 'No generic trend lists. Every recommendation starts with your unique measurements, colours, and preferences.',
            },
            {
              icon: 'auto_awesome',
              title: 'AI-Powered',
              body: 'We combine computer vision and style-theory models to deliver editorial-grade outfit curation at scale.',
            },
            {
              icon: 'lock',
              title: 'Private by Design',
              body: 'Your wardrobe data is yours. We never sell personal style data to third parties — full stop.',
            },
          ].map(v => (
            <div key={v.title}>
              <span className="material-symbols-outlined text-secondary text-2xl mb-4 block">
                {v.icon}
              </span>
              <h3 className="font-headline text-lg font-bold mb-3">{v.title}</h3>
              <p className="font-body text-sm text-[#5f5e5e] font-light leading-relaxed">
                {v.body}
              </p>
            </div>
          ))}
        </section>

        {/* Team note */}
        <section className="bg-[#1A1A1A] text-white rounded-xl p-12 mb-20">
          <span className="font-label uppercase tracking-[0.2rem] text-[0.6875rem] text-white/40 mb-6 block">
            Built By
          </span>
          <p className="font-body text-lg font-light leading-relaxed text-white/80 max-w-xl">
            Stylo Buddy is an independent product built with passion for fashion
            and technology. We're a small team focused on shipping a genuinely
            useful tool — not another trend aggregator.
          </p>
        </section>

        {/* CTA */}
        <div className="flex gap-6 items-center">
          <Link href="/login">
            <button className="px-10 py-4 bg-[#1A1A1A] text-white rounded-full font-headline tracking-wide text-sm hover:bg-[#333] transition-colors duration-[400ms]">
              Start Styling
            </button>
          </Link>
          <Link
            href="/contact"
            className="font-headline uppercase tracking-[0.1rem] text-[0.6875rem] text-[#5f5e5e] hover:text-[#1A1A1A] transition-colors duration-[400ms]"
          >
            Get in Touch →
          </Link>
        </div>

      </div>
    </main>
  )
}
