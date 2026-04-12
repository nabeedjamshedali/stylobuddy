import Link from 'next/link'

export const metadata = {
  title: 'Terms of Service — Stylo Buddy',
  description: 'The terms and conditions governing your use of Stylo Buddy.',
}

const LAST_UPDATED = 'April 12, 2026'

export default function TermsPage() {
  return (
    <main className="pt-32 pb-24 px-6 md:px-12">
      <div className="max-w-[760px] mx-auto">

        {/* Header */}
        <div className="mb-16">
          <span className="font-label uppercase tracking-[0.2rem] text-[0.6875rem] text-secondary mb-4 block">
            Legal
          </span>
          <h1 className="font-headline text-4xl md:text-5xl font-extrabold tracking-tighter text-[#1A1A1A] mb-4">
            Terms of Service
          </h1>
          <p className="font-body text-sm text-[#aaa] font-light">
            Last updated: {LAST_UPDATED}
          </p>
          <div className="h-[1px] w-full bg-[#e8e6e3] mt-8" />
        </div>

        <div className="flex flex-col gap-14 font-body font-light text-[#3a3a3a] leading-relaxed">

          <Section title="1. Acceptance of Terms">
            <p>
              By accessing or using Stylo Buddy ("the Service"), you agree to
              be bound by these Terms of Service. If you do not agree, do not
              use the Service.
            </p>
          </Section>

          <Section title="2. Eligibility">
            <p>
              You must be at least 13 years of age to use Stylo Buddy. By
              creating an account you represent that you meet this requirement.
            </p>
          </Section>

          <Section title="3. Your Account">
            <p>
              You are responsible for maintaining the confidentiality of your
              login credentials and for all activity that occurs under your
              account. Notify us immediately at{' '}
              <a href="mailto:nabeedjamshed@gmail.com" className="text-[#1A1A1A] underline underline-offset-2">
                nabeedjamshed@gmail.com
              </a>{' '}
              if you suspect unauthorised access.
            </p>
          </Section>

          <Section title="4. Acceptable Use">
            <p>You agree not to:</p>
            <ul>
              <li>Upload content that is illegal, harmful, or infringes third-party rights</li>
              <li>Attempt to reverse-engineer, scrape, or misuse any part of the Service</li>
              <li>Use the Service to transmit spam, malware, or unsolicited communications</li>
              <li>Impersonate any person or entity</li>
            </ul>
          </Section>

          <Section title="5. Content You Upload">
            <p>
              You retain ownership of any photos or content you upload to Stylo
              Buddy. By uploading, you grant us a limited, non-exclusive licence
              to process and display that content solely for the purpose of
              providing the Service to you.
            </p>
            <p>
              We will never use your uploaded content for training third-party
              AI models or share it publicly without your explicit consent.
            </p>
          </Section>

          <Section title="6. Intellectual Property">
            <p>
              All product features, design, branding, and code of Stylo Buddy
              are the property of Stylo Buddy and are protected by applicable
              intellectual property laws. You may not copy, modify, or
              distribute any part of the Service without prior written
              permission.
            </p>
          </Section>

          <Section title="7. Disclaimer of Warranties">
            <p>
              The Service is provided "as is" without warranties of any kind,
              express or implied. We do not guarantee uninterrupted or
              error-free operation, or that AI-generated outfit recommendations
              will meet your expectations in every case.
            </p>
          </Section>

          <Section title="8. Limitation of Liability">
            <p>
              To the fullest extent permitted by law, Stylo Buddy shall not be
              liable for any indirect, incidental, or consequential damages
              arising from your use of, or inability to use, the Service.
            </p>
          </Section>

          <Section title="9. Termination">
            <p>
              We reserve the right to suspend or terminate your account if you
              violate these Terms. You may delete your account at any time from
              your profile settings. Upon termination, your data will be deleted
              in accordance with our{' '}
              <Link href="/privacy" className="text-[#1A1A1A] underline underline-offset-2">
                Privacy Policy
              </Link>
              .
            </p>
          </Section>

          <Section title="10. Changes to Terms">
            <p>
              We may revise these Terms at any time. Continued use of the
              Service after changes take effect constitutes acceptance of the
              new Terms. We will notify you of material changes via email.
            </p>
          </Section>

          <Section title="11. Contact">
            <p>
              Questions about these Terms? Contact us at{' '}
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
