'use client'

import { useState, useEffect, useCallback, useRef } from 'react'

interface UseQueryOptions<T> {
  enabled?: boolean
  refetchInterval?: number
  onSuccess?: (data: T) => void
  onError?: (error: Error) => void
  initialData?: T
}

interface UseQueryReturn<T> {
  data: T | undefined
  loading: boolean
  error: Error | null
  refetch: () => Promise<void>
  isRefetching: boolean
}

// Simple in-memory cache
const cache = new Map<string, { data: unknown; timestamp: number }>()
const CACHE_TTL = 30000 // 30 seconds

export function useQuery<T>(
  key: string | string[],
  queryFn: () => Promise<T>,
  options: UseQueryOptions<T> = {}
): UseQueryReturn<T> {
  const { enabled = true, refetchInterval, onSuccess, onError, initialData } = options
  const cacheKey = Array.isArray(key) ? key.join(':') : key

  const [data, setData] = useState<T | undefined>(() => {
    // Check cache on init
    const cached = cache.get(cacheKey)
    if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
      return cached.data as T
    }
    return initialData
  })
  const [loading, setLoading] = useState(!data && enabled)
  const [isRefetching, setIsRefetching] = useState(false)
  const [error, setError] = useState<Error | null>(null)

  const queryFnRef = useRef(queryFn)
  queryFnRef.current = queryFn

  const fetchData = useCallback(
    async (isRefetch = false) => {
      if (isRefetch) {
        setIsRefetching(true)
      } else {
        setLoading(true)
      }
      setError(null)

      try {
        const result = await queryFnRef.current()
        setData(result)
        cache.set(cacheKey, { data: result, timestamp: Date.now() })
        onSuccess?.(result)
      } catch (err) {
        const error = err instanceof Error ? err : new Error(String(err))
        setError(error)
        onError?.(error)
      } finally {
        setLoading(false)
        setIsRefetching(false)
      }
    },
    [cacheKey, onSuccess, onError]
  )

  // Initial fetch
  useEffect(() => {
    if (enabled) {
      // Check if we have fresh cache
      const cached = cache.get(cacheKey)
      if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
        setData(cached.data as T)
        setLoading(false)
      } else {
        fetchData()
      }
    }
  }, [enabled, cacheKey, fetchData])

  // Refetch interval
  useEffect(() => {
    if (!refetchInterval || !enabled) return

    const interval = setInterval(() => {
      fetchData(true)
    }, refetchInterval)

    return () => clearInterval(interval)
  }, [refetchInterval, enabled, fetchData])

  const refetch = useCallback(async () => {
    await fetchData(true)
  }, [fetchData])

  return { data, loading, error, refetch, isRefetching }
}

// Helper to invalidate cache
export function invalidateQuery(key: string | string[]) {
  const cacheKey = Array.isArray(key) ? key.join(':') : key
  cache.delete(cacheKey)
}

// Helper to invalidate all queries matching a prefix
export function invalidateQueries(prefix: string) {
  for (const key of cache.keys()) {
    if (key.startsWith(prefix)) {
      cache.delete(key)
    }
  }
}
