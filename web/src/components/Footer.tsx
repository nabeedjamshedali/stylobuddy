'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'

const HIDDEN_ROUTES = ['/login']

export default function Footer() {
  const pathname = usePathname()

  if (HIDDEN_ROUTES.includes(pathname)) return null

  return (
    <footer className="w-full mt-auto bg-[#edeeeb]">
      <div className="flex flex-col md:flex-row justify-between items-center px-12 py-12 w-full max-w-[1440px] mx-auto">
        <div className="mb-8 md:mb-0">
          <div className="font-headline font-bold text-[#1A1A1A] text-2xl mb-2">
            Stylo Buddy
          </div>
          <p className="font-body text-[0.875rem] font-light text-[#5f5e5e]">
            © 2024 Stylo Buddy Atelier. All rights reserved.
          </p>
        </div>

        <div className="flex gap-12">
          <div className="flex flex-col gap-3">
            <span className="font-headline uppercase text-[0.6rem] tracking-widest text-outline">
              Atelier
            </span>
            <Link
              href="/about"
              className="font-body text-[0.875rem] font-light text-[#5f5e5e] hover:text-[#1A1A1A] hover:underline transition-all duration-[400ms]"
            >
              About
            </Link>
            <Link
              href="/privacy"
              className="font-body text-[0.875rem] font-light text-[#5f5e5e] hover:text-[#1A1A1A] hover:underline transition-all duration-[400ms]"
            >
              Privacy
            </Link>
          </div>
          <div className="flex flex-col gap-3">
            <span className="font-headline uppercase text-[0.6rem] tracking-widest text-outline">
              Legal
            </span>
            <Link
              href="/terms"
              className="font-body text-[0.875rem] font-light text-[#5f5e5e] hover:text-[#1A1A1A] hover:underline transition-all duration-[400ms]"
            >
              Terms
            </Link>
            <Link
              href="/contact"
              className="font-body text-[0.875rem] font-light text-[#5f5e5e] hover:text-[#1A1A1A] hover:underline transition-all duration-[400ms]"
            >
              Contact
            </Link>
          </div>
        </div>
      </div>
    </footer>
  )
}
