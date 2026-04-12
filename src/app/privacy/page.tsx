import Link from 'next/link'

export const metadata = {
  title: 'Privacy Policy — Stylo Buddy',
  description: 'How Stylo Buddy collects, uses, and protects your personal data.',
}

const LAST_UPDATED = 'April 12, 2026'

export default function PrivacyPage() {
  return (
    <main className="pt-32 pb-24 px-6 md:px-12">
      <div className="max-w-[760px] mx-auto">

        {/* Header */}
        <div className="mb-16">
          <span className="font-label uppercase tracking-[0.2rem] text-[0.6875rem] text-secondary mb-4 block">
            Legal
          </span>
          <h1 className="font-headline text-4xl md:text-5xl font-extrabold tracking-tighter text-[#1A1A1A] mb-4">
            Privacy Policy
          </h1>
          <p className="font-body text-sm text-[#aaa] font-light">
            Last updated: {LAST_UPDATED}
          </p>
          <div className="h-[1px] w-full bg-[#e8e6e3] mt-8" />
        </div>

        <div className="flex flex-col gap-14 font-body font-light text-[#3a3a3a] leading-relaxed">

          <Section title="1. Information We Collect">
            <p>We collect information you provide directly when you create an account, upload wardrobe items, or contact us. This includes:</p>
            <ul>
              <li>Name and email address</li>
              <li>Photos of clothing items you upload</li>
              <li>Style preferences and aesthetic choices you set within the app</li>
              <li>Usage data such as features accessed and outfit combinations saved</li>
            </ul>
          </Section>

          <Section title="2. How We Use Your Information">
            <p>We use your information solely to provide and improve the Stylo Buddy service:</p>
            <ul>
              <li>To generate personalised outfit recommendations</li>
              <li>To save your wardrobe and style history across sessions</li>
              <li>To send transactional emails (e.g. account confirmation)</li>
              <li>To diagnose technical issues and improve product quality</li>
            </ul>
            <p>We do <strong>not</strong> sell, rent, or trade your personal data to any third party for marketing purposes.</p>
          </Section>

          <Section title="3. Data Storage & Security">
            <p>
              Your data is stored on secure servers. We use industry-standard
              encryption (TLS in transit, AES-256 at rest) to protect your
              information. Access to personal data is restricted to authorised
              team members only.
            </p>
            <p>
              No system is 100% secure. If you believe your account has been
              compromised, contact us immediately at{' '}
              <a href="mailto:nabeedjamshed@gmail.com" className="text-[#1A1A1A] underline underline-offset-2">
                nabeedjamshed@gmail.com
              </a>
              .
            </p>
          </Section>

          <Section title="4. Cookies">
            <p>
              We use essential cookies to keep you logged in and maintain your
              session. We do not use advertising or cross-site tracking cookies.
              You can disable cookies in your browser settings, though this may
              affect app functionality.
            </p>
          </Section>

          <Section title="5. Your Rights">
            <p>You have the right to:</p>
            <ul>
              <li>Access the personal data we hold about you</li>
              <li>Request correction of inaccurate data</li>
              <li>Request deletion of your account and associated data</li>
              <li>Export your wardrobe data in a portable format</li>
            </ul>
            <p>
              To exercise any of these rights, email us at{' '}
              <a href="mailto:nabeedjamshed@gmail.com" className="text-[#1A1A1A] underline underline-offset-2">
                nabeedjamshed@gmail.com
              </a>
              .
            </p>
          </Section>

          <Section title="6. Third-Party Services">
            <p>
              We may use third-party services for infrastructure (hosting,
              analytics). These providers are contractually bound to process
              your data only on our behalf and in accordance with this policy.
            </p>
          </Section>

          <Section title="7. Changes to This Policy">
            <p>
              We may update this Privacy Policy from time to time. We will
              notify you of material changes by email or via an in-app notice.
              Continued use of Stylo Buddy after changes take effect constitutes
              your acceptance of the revised policy.
            </p>
          </Section>

          <Section title="8. Contact">
            <p>
              Questions about this policy? Reach us at{' '}
              <a href="mailto:nabeedjamshed@gmail.com" className="text-[#1A1A1A] underline underline-offset-2">
                nabeedjamshed@gmail.com
              </a>{' '}
              or visit our{' '}
              <Link href="/contact" className="text-[#1A1A1A] underline underline-offset-2">
                contact page
              </Link>
              .
            </p>
          </Section>

        </div>
      </div>
    </main>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <h2 className="font-headline text-xl font-bold tracking-tight text-[#1A1A1A] mb-5">
        {title}
      </h2>
      <div className="flex flex-col gap-4 text-[0.9375rem] [&_ul]:flex [&_ul]:flex-col [&_ul]:gap-2 [&_ul]:pl-5 [&_ul]:list-disc [&_ul]:marker:text-[#aaa] [&_strong]:font-semibold [&_strong]:text-[#1A1A1A]">
        {children}
      </div>
    </section>
  )
}
