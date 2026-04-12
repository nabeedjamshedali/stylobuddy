'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useEffect, useState } from 'react'

const navLinks = [
  { label: 'Workspace', href: '/workspace' },
  { label: 'Explore', href: '/explore' },
  { label: 'Saved', href: '/saved' },
]

/* Routes where the app nav (Workspace / Explore / Saved) should appear */
const APP_ROUTES = ['/workspace', '/explore', '/saved']

/* Routes where the Navbar should not render at all */
const HIDDEN_ROUTES = ['/login']

export default function Navbar() {
  const pathname = usePathname()
  const [workspaceSelectionCount, setWorkspaceSelectionCount] = useState(0)

  useEffect(() => {
    const handler = (e: Event) => {
      const count = (e as CustomEvent<{ count: number }>).detail.count
      setWorkspaceSelectionCount(count)
    }
    window.addEventListener('workspace-selection-change', handler)
    return () => window.removeEventListener('workspace-selection-change', handler)
  }, [])

  // Reset badge when leaving workspace
  useEffect(() => {
    if (pathname !== '/workspace') setWorkspaceSelectionCount(0)
  }, [pathname])

  if (HIDDEN_ROUTES.includes(pathname)) return null

  const isLanding = pathname === '/'
  const isAppPage = APP_ROUTES.includes(pathname)

  return (
    <nav className="fixed top-0 w-full z-50 glass-nav shadow-[0_20px_40px_rgba(47,51,49,0.06)]">
      <div className="flex justify-between items-center px-12 py-6 w-full max-w-[1440px] mx-auto">
        <Link
          href="/"
          className="text-xl font-bold tracking-tighter text-[#1A1A1A] font-headline"
        >
          Stylo Buddy
        </Link>

        {isLanding && (
          /* Landing page — show auth buttons only */
          <div className="flex items-center gap-4">
            <Link
              href="/login"
              className="font-headline uppercase tracking-[0.1rem] text-[0.6875rem] text-[#5f5e5e] hover:text-[#1A1A1A] transition-all duration-[400ms] ease-[cubic-bezier(0.2,0,0,1)]"
            >
              Log In
            </Link>
            <Link
              href="/login?mode=signup"
              className="px-6 py-2.5 bg-[#1A1A1A] text-white rounded-full font-headline uppercase tracking-[0.1rem] text-[0.6875rem] hover:bg-[#333] transition-all duration-[400ms] ease-[cubic-bezier(0.2,0,0,1)]"
            >
              Sign Up
            </Link>
          </div>
        )}

        {isAppPage && (
          /* App pages — show nav links + account icon */
          <>
            <div className="hidden md:flex gap-10 items-center">
              {navLinks.map((link) => {
                const isActive = pathname === link.href
                const showBadge = link.href === '/workspace' && workspaceSelectionCount > 0
                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    className={`relative font-headline uppercase tracking-[0.1rem] text-[0.6875rem] transition-all duration-[400ms] ease-[cubic-bezier(0.2,0,0,1)] ${
                      isActive
                        ? 'text-[#1A1A1A] border-b border-[#1A1A1A] pb-1'
                        : 'text-[#5f5e5e] hover:text-[#1A1A1A]'
                    }`}
                  >
                    {link.label}
                    {showBadge && (
                      <span className="absolute -top-2 -right-3.5 w-4 h-4 bg-secondary text-on-secondary rounded-full text-[0.5rem] flex items-center justify-center font-bold">
                        {workspaceSelectionCount}
                      </span>
                    )}
                  </Link>
                )
              })}
            </div>

            <div className="flex items-center gap-6">
              <button className="scale-95 transition-transform duration-[400ms]">
                <span className="material-symbols-outlined text-primary">
                  account_circle
                </span>
              </button>
            </div>
          </>
        )}
      </div>
    </nav>
  )
}
