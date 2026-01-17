'use client'

import { useState, useCallback } from 'react'
import { useToast } from '@/components/ui/toast'

interface UseMutationOptions<TData, TVariables> {
  onSuccess?: (data: TData, variables: TVariables) => void
  onError?: (error: Error, variables: TVariables) => void
  onSettled?: (data: TData | null, error: Error | null, variables: TVariables) => void
  successMessage?: string
  errorMessage?: string
}

interface UseMutationReturn<TData, TVariables> {
  mutate: (variables: TVariables) => Promise<TData | null>
  mutateAsync: (variables: TVariables) => Promise<TData>
  data: TData | null
  loading: boolean
  error: Error | null
  reset: () => void
}

export function useMutation<TData, TVariables = void>(
  mutationFn: (variables: TVariables) => Promise<TData>,
  options: UseMutationOptions<TData, TVariables> = {}
): UseMutationReturn<TData, TVariables> {
  const toast = useToast()
  const [data, setData] = useState<TData | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<Error | null>(null)

  const mutateAsync = useCallback(
    async (variables: TVariables): Promise<TData> => {
      setLoading(true)
      setError(null)

      try {
        const result = await mutationFn(variables)
        setData(result)

        if (options.successMessage) {
          toast.success(options.successMessage)
        }

        options.onSuccess?.(result, variables)
        options.onSettled?.(result, null, variables)

        return result
      } catch (err) {
        const error = err instanceof Error ? err : new Error(String(err))
        setError(error)

        toast.error(options.errorMessage || error.message)
        options.onError?.(error, variables)
        options.onSettled?.(null, error, variables)

        throw error
      } finally {
        setLoading(false)
      }
    },
    [mutationFn, options, toast]
  )

  const mutate = useCallback(
    async (variables: TVariables): Promise<TData | null> => {
      try {
        return await mutateAsync(variables)
      } catch {
        return null
      }
    },
    [mutateAsync]
  )

  const reset = useCallback(() => {
    setData(null)
    setError(null)
    setLoading(false)
  }, [])

  return { mutate, mutateAsync, data, loading, error, reset }
}
