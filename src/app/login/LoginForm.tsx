'use client'

import Link from 'next/link'
import { useSearchParams } from 'next/navigation'
import { useState } from 'react'

export default function LoginForm() {
  const searchParams = useSearchParams()
  const defaultMode = searchParams.get('mode') === 'signup' ? 'signup' : 'login'
  const [mode, setMode] = useState<'login' | 'signup'>(defaultMode)
  const [showPassword, setShowPassword] = useState(false)

  return (
    <main className="min-h-screen flex">
      {/* Left panel — decorative fashion image */}
      <div className="hidden lg:block lg:w-1/2 relative overflow-hidden">
        <img
          alt="Fashion editorial"
          className="w-full h-full object-cover object-top"
          src="https://lh3.googleusercontent.com/aida-public/AB6AXuAqA-2Okv5E7K3ha9yGo1aSYum6dIbptOisvwSL0vGTTXBxA7mUFZqE9cmn6aQ74IKCQVEI4G8Hnk6uXkBD4jh76siONrjpTUJDlMuvbV0WSJlTV09LtIUwDY29ZruRrkM1HZPDSm326g8urr-isNpAfG7qoMAcwXjtgNOD4IzfQDp-Dyw6MuXZwy0WAJQ46JaUuwQyxiTaFahlV0TQhTX5Y0vcs-bGoZbvYGQ8Wr4uYGI-McQLMdneoMkvU-HulLbN-AklA-eOASxZ"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
        <div className="absolute bottom-12 left-12 right-12">
          <p className="font-headline text-white text-3xl font-bold leading-tight mb-2">
            Your style, <br />
            <em className="not-italic font-light">elevated.</em>
          </p>
          <p className="text-white/60 font-body text-sm font-light">
            AI-curated outfits personalized to your silhouette.
          </p>
        </div>
      </div>

      {/* Right panel — auth form */}
      <div className="w-full lg:w-1/2 flex flex-col justify-center items-center bg-surface py-16 px-6">
        {/* Inner content — centered on mobile, left-aligned inside half-panel on lg */}
        <div className="w-full max-w-[400px]">

        {/* Logo */}
        <Link
          href="/"
          className="text-xl font-bold tracking-tighter text-[#1A1A1A] font-headline mb-14 block"
        >
          Stylo Buddy
        </Link>

        {/* Mode toggle */}
        <div className="mb-10">
          <h1 className="font-headline text-3xl font-bold tracking-tight text-[#1A1A1A] mb-2">
            {mode === 'login' ? 'Welcome back.' : 'Create your account.'}
          </h1>
          <p className="font-body text-sm text-[#5f5e5e] font-light">
            {mode === 'login' ? (
              <>
                New here?{' '}
                <button
                  onClick={() => setMode('signup')}
                  className="text-[#1A1A1A] font-medium underline underline-offset-2 hover:opacity-70 transition-opacity"
                >
                  Create an account
                </button>
              </>
            ) : (
              <>
                Already have an account?{' '}
                <button
                  onClick={() => setMode('login')}
                  className="text-[#1A1A1A] font-medium underline underline-offset-2 hover:opacity-70 transition-opacity"
                >
                  Log in
                </button>
              </>
            )}
          </p>
        </div>

        {/* Form */}
        <form className="flex flex-col gap-5 w-full">
          {mode === 'signup' && (
            <div className="flex flex-col gap-2">
              <label className="font-headline uppercase tracking-[0.1rem] text-[0.6rem] text-[#5f5e5e]">
                Full Name
              </label>
              <input
                type="text"
                placeholder="Alex Monroe"
                className="w-full border border-[#ddd] rounded-lg px-4 py-3.5 font-body text-sm text-[#1A1A1A] bg-white placeholder:text-[#bbb] focus:outline-none focus:border-[#1A1A1A] transition-colors duration-300"
              />
            </div>
          )}

          <div className="flex flex-col gap-2">
            <label className="font-headline uppercase tracking-[0.1rem] text-[0.6rem] text-[#5f5e5e]">
              Email
            </label>
            <input
              type="email"
              placeholder="you@example.com"
              className="w-full border border-[#ddd] rounded-lg px-4 py-3.5 font-body text-sm text-[#1A1A1A] bg-white placeholder:text-[#bbb] focus:outline-none focus:border-[#1A1A1A] transition-colors duration-300"
            />
          </div>

          <div className="flex flex-col gap-2">
            <label className="font-headline uppercase tracking-[0.1rem] text-[0.6rem] text-[#5f5e5e]">
              Password
            </label>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                placeholder="••••••••"
                className="w-full border border-[#ddd] rounded-lg px-4 py-3.5 pr-12 font-body text-sm text-[#1A1A1A] bg-white placeholder:text-[#bbb] focus:outline-none focus:border-[#1A1A1A] transition-colors duration-300"
              />
              <button
                type="button"
                onClick={() => setShowPassword(v => !v)}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#aaa] hover:text-[#1A1A1A] transition-colors duration-300"
                aria-label={showPassword ? 'Hide password' : 'Show password'}
              >
                <span className="material-symbols-outlined text-[1.2rem]">
                  {showPassword ? 'visibility_off' : 'visibility'}
                </span>
              </button>
            </div>
          </div>

          {mode === 'login' && (
            <div className="text-right -mt-2">
              <a
                href="#"
                className="font-body text-xs text-[#5f5e5e] hover:text-[#1A1A1A] transition-colors underline underline-offset-2"
              >
                Forgot password?
              </a>
            </div>
          )}

          {/* Submit — links to workspace after auth */}
          <Link href="/workspace" className="mt-2">
            <button
              type="button"
              className="w-full py-4 bg-[#1A1A1A] text-white rounded-full font-headline tracking-wide text-sm hover:bg-[#333] active:scale-[0.98] transition-all duration-[400ms]"
            >
              {mode === 'login' ? 'Log In' : 'Create Account'}
            </button>
          </Link>
        </form>

        <p className="mt-10 font-body text-[0.75rem] text-[#aaa]">
          By continuing you agree to our{' '}
          <Link href="/terms" className="underline underline-offset-2 hover:text-[#5f5e5e]">
            Terms of Service
          </Link>{' '}
          and{' '}
          <Link href="/privacy" className="underline underline-offset-2 hover:text-[#5f5e5e]">
            Privacy Policy
          </Link>
          .
        </p>

        </div>{/* end inner content wrapper */}
      </div>
    </main>
  )
}
