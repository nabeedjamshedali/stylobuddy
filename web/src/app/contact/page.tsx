export const metadata = {
  title: 'Contact — Stylo Buddy',
  description: 'Get in touch with the Stylo Buddy team.',
}

export default function ContactPage() {
  return (
    <main className="pt-32 pb-24 px-6 md:px-12">
      <div className="max-w-[860px] mx-auto">

        {/* Header */}
        <div className="mb-20">
          <span className="font-label uppercase tracking-[0.2rem] text-[0.6875rem] text-secondary mb-4 block">
            Contact
          </span>
          <h1 className="font-headline text-5xl md:text-[4rem] font-extrabold tracking-tighter text-[#1A1A1A] leading-[1.1] mb-8">
            Let&apos;s talk.
          </h1>
          <div className="h-[1px] w-full bg-[#e8e6e3]" />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-16">

          {/* Contact details */}
          <div className="flex flex-col gap-10">
            <p className="font-body text-lg text-[#5f5e5e] font-light leading-relaxed">
              Have a question, a bug report, or just want to say hello?
              Reach out — we read every message.
            </p>

            <div className="flex flex-col gap-8">
              {/* Email */}
              <div className="flex items-start gap-5">
                <div className="w-10 h-10 rounded-full bg-[#f4f3f0] flex items-center justify-center flex-shrink-0">
                  <span className="material-symbols-outlined text-[1.1rem] text-[#1A1A1A]">
                    mail
                  </span>
                </div>
                <div>
                  <p className="font-headline uppercase tracking-[0.1rem] text-[0.6rem] text-[#aaa] mb-1">
                    Email
                  </p>
                  <a
                    href="mailto:nabeedjamshed@gmail.com"
                    className="font-body text-[#1A1A1A] hover:text-secondary transition-colors duration-[400ms] underline underline-offset-4 decoration-[#ddd] hover:decoration-secondary"
                  >
                    nabeedjamshed@gmail.com
                  </a>
                </div>
              </div>

              {/* Phone */}
              <div className="flex items-start gap-5">
                <div className="w-10 h-10 rounded-full bg-[#f4f3f0] flex items-center justify-center flex-shrink-0">
                  <span className="material-symbols-outlined text-[1.1rem] text-[#1A1A1A]">
                    phone
                  </span>
                </div>
                <div>
                  <p className="font-headline uppercase tracking-[0.1rem] text-[0.6rem] text-[#aaa] mb-1">
                    Phone / WhatsApp
                  </p>
                  <a
                    href="tel:+923102155596"
                    className="font-body text-[#1A1A1A] hover:text-secondary transition-colors duration-[400ms] underline underline-offset-4 decoration-[#ddd] hover:decoration-secondary"
                  >
                    +92 310 2155596
                  </a>
                </div>
              </div>

              {/* Response time note */}
              <div className="flex items-start gap-5">
                <div className="w-10 h-10 rounded-full bg-[#f4f3f0] flex items-center justify-center flex-shrink-0">
                  <span className="material-symbols-outlined text-[1.1rem] text-[#1A1A1A]">
                    schedule
                  </span>
                </div>
                <div>
                  <p className="font-headline uppercase tracking-[0.1rem] text-[0.6rem] text-[#aaa] mb-1">
                    Response Time
                  </p>
                  <p className="font-body text-[#5f5e5e] text-sm font-light">
                    We typically respond within 24 hours on business days.
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Quick-contact card */}
          <div className="bg-[#1A1A1A] rounded-xl p-10 flex flex-col justify-between">
            <div>
              <h2 className="font-headline text-2xl font-bold text-white tracking-tight mb-4">
                Send a message
              </h2>
              <p className="font-body text-sm text-white/50 font-light mb-8">
                Fill in your details and we&apos;ll get back to you as soon as possible.
              </p>
            </div>

            <form className="flex flex-col gap-4">
              <input
                type="text"
                placeholder="Your name"
                className="w-full bg-white/10 border border-white/10 rounded-lg px-4 py-3.5 font-body text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-white/40 transition-colors duration-300"
              />
              <input
                type="email"
                placeholder="your@email.com"
                className="w-full bg-white/10 border border-white/10 rounded-lg px-4 py-3.5 font-body text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-white/40 transition-colors duration-300"
              />
              <textarea
                rows={4}
                placeholder="How can we help?"
                className="w-full bg-white/10 border border-white/10 rounded-lg px-4 py-3.5 font-body text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-white/40 transition-colors duration-300 resize-none"
              />
              <button
                type="button"
                className="w-full py-4 bg-white text-[#1A1A1A] rounded-full font-headline tracking-wide text-sm hover:bg-white/90 active:scale-[0.98] transition-all duration-[400ms] mt-2"
              >
                Send Message
              </button>
            </form>
          </div>

        </div>
      </div>
    </main>
  )
}
