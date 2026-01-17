import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, waitFor, act } from '@testing-library/react'
import { ReactNode } from 'react'
import { useMutation } from '../../hooks/use-mutation'
import { ToastProvider } from '../../components/ui/toast'

// Wrapper with ToastProvider
const wrapper = ({ children }: { children: ReactNode }) => (
  <ToastProvider>{children}</ToastProvider>
)

describe('useMutation', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  it('inicia en estado idle', () => {
    const mutationFn = vi.fn()

    const { result } = renderHook(() => useMutation(mutationFn), { wrapper })

    expect(result.current.loading).toBe(false)
    expect(result.current.data).toBeNull()
    expect(result.current.error).toBeNull()
  })

  it('mutate ejecuta la función y actualiza estado', async () => {
    const mockData = { id: 1, created: true }
    const mutationFn = vi.fn().mockResolvedValue(mockData)

    const { result } = renderHook(() => useMutation(mutationFn), { wrapper })

    await act(async () => {
      await result.current.mutate({ name: 'Test' })
    })

    expect(mutationFn).toHaveBeenCalledWith({ name: 'Test' })
    expect(result.current.data).toEqual(mockData)
    expect(result.current.loading).toBe(false)
  })

  it('mutate retorna null en error', async () => {
    const error = new Error('Mutation failed')
    const mutationFn = vi.fn().mockRejectedValue(error)

    const { result } = renderHook(() => useMutation(mutationFn), { wrapper })

    let returnValue: unknown
    await act(async () => {
      returnValue = await result.current.mutate({})
    })

    expect(returnValue).toBeNull()
    expect(result.current.error).toEqual(error)
  })

  it('mutateAsync lanza error', async () => {
    const error = new Error('Mutation failed')
    const mutationFn = vi.fn().mockRejectedValue(error)

    const { result } = renderHook(() => useMutation(mutationFn), { wrapper })

    await expect(async () => {
      await act(async () => {
        await result.current.mutateAsync({})
      })
    }).rejects.toThrow('Mutation failed')
  })

  it('llama onSuccess cuando mutation es exitosa', async () => {
    const mockData = { success: true }
    const mutationFn = vi.fn().mockResolvedValue(mockData)
    const onSuccess = vi.fn()

    const { result } = renderHook(
      () => useMutation(mutationFn, { onSuccess }),
      { wrapper }
    )

    await act(async () => {
      await result.current.mutate({ input: 'test' })
    })

    expect(onSuccess).toHaveBeenCalledWith(mockData, { input: 'test' })
  })

  it('llama onError cuando mutation falla', async () => {
    const error = new Error('Failed')
    const mutationFn = vi.fn().mockRejectedValue(error)
    const onError = vi.fn()

    const { result } = renderHook(
      () => useMutation(mutationFn, { onError }),
      { wrapper }
    )

    await act(async () => {
      await result.current.mutate({ input: 'test' })
    })

    expect(onError).toHaveBeenCalledWith(error, { input: 'test' })
  })

  it('llama onSettled siempre', async () => {
    const mockData = { done: true }
    const mutationFn = vi.fn().mockResolvedValue(mockData)
    const onSettled = vi.fn()

    const { result } = renderHook(
      () => useMutation(mutationFn, { onSettled }),
      { wrapper }
    )

    await act(async () => {
      await result.current.mutate({})
    })

    expect(onSettled).toHaveBeenCalledWith(mockData, null, {})
  })

  it('llama onSettled con error cuando falla', async () => {
    const error = new Error('Failed')
    const mutationFn = vi.fn().mockRejectedValue(error)
    const onSettled = vi.fn()

    const { result } = renderHook(
      () => useMutation(mutationFn, { onSettled }),
      { wrapper }
    )

    await act(async () => {
      await result.current.mutate({})
    })

    expect(onSettled).toHaveBeenCalledWith(null, error, {})
  })

  it('reset limpia el estado', async () => {
    const mockData = { id: 1 }
    const mutationFn = vi.fn().mockResolvedValue(mockData)

    const { result } = renderHook(() => useMutation(mutationFn), { wrapper })

    await act(async () => {
      await result.current.mutate({})
    })

    expect(result.current.data).toEqual(mockData)

    act(() => {
      result.current.reset()
    })

    expect(result.current.data).toBeNull()
    expect(result.current.error).toBeNull()
    expect(result.current.loading).toBe(false)
  })

  it('loading es true durante la mutación', async () => {
    let resolvePromise: (value: unknown) => void
    const mutationFn = vi.fn().mockImplementation(
      () => new Promise((resolve) => { resolvePromise = resolve })
    )

    const { result } = renderHook(() => useMutation(mutationFn), { wrapper })

    act(() => {
      result.current.mutate({})
    })

    expect(result.current.loading).toBe(true)

    await act(async () => {
      resolvePromise!({ done: true })
    })

    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })
  })
})
