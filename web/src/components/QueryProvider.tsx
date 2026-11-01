'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useRef } from 'react'

export default function QueryProvider({ children }: { children: React.ReactNode }) {
  // useRef so the QueryClient is created once per browser session, not on every render
  const clientRef = useRef<QueryClient | null>(null)
  if (!clientRef.current) {
    clientRef.current = new QueryClient({
      defaultOptions: {
        queries: {
          // Data is considered fresh for 1 hour — no refetch on window focus or remount
          staleTime: 60 * 60 * 1000,
          // Keep unused data in memory for 2 hours after all components unmount
          gcTime: 2 * 60 * 60 * 1000,
          // Don't hammer the server on transient failures
          retry: 1,
        },
      },
    })
  }

  return (
    <QueryClientProvider client={clientRef.current}>
      {children}
    </QueryClientProvider>
  )
}
