import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      // Original Google-hosted catalog images
      { protocol: 'https', hostname: 'lh3.googleusercontent.com' },
      // Supabase Storage (clothing-catalog bucket)
      { protocol: 'https', hostname: '*.supabase.co' },
      // Unsplash stock photos used for dummy catalog data
      { protocol: 'https', hostname: 'images.unsplash.com' },
    ],
  },
}

export default nextConfig
