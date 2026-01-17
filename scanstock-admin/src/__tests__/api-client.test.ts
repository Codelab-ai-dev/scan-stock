import { describe, it, expect, vi, beforeEach } from 'vitest'
import { api, ApiError, getErrorMessage, errorMessages } from '../lib/api-client'

describe('api client', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  describe('api.get', () => {
    it('retorna data en respuesta exitosa', async () => {
      const mockData = { id: 1, name: 'Test' }
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockData),
      })

      const { data, error } = await api.get('/test')

      expect(error).toBeNull()
      expect(data).toEqual(mockData)
    })

    it('retorna error en respuesta fallida', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: false,
        status: 404,
        json: () => Promise.resolve({ error: 'Not found' }),
      })

      const { data, error } = await api.get('/test')

      expect(data).toBeNull()
      expect(error).toBeInstanceOf(ApiError)
      expect(error?.status).toBe(404)
      expect(error?.message).toBe('Not found')
    })

    it('maneja errores de red', async () => {
      global.fetch = vi.fn().mockRejectedValue(new Error('Network error'))

      const { data, error } = await api.get('/test')

      expect(data).toBeNull()
      expect(error).toBeInstanceOf(ApiError)
      expect(error?.code).toBe('NETWORK_ERROR')
    })
  })

  describe('api.post', () => {
    it('envía body como JSON', async () => {
      const mockData = { success: true }
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockData),
      })

      const body = { name: 'Test', value: 123 }
      await api.post('/test', body)

      expect(fetch).toHaveBeenCalledWith('/test', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      })
    })
  })

  describe('api.patch', () => {
    it('usa método PATCH', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({}),
      })

      await api.patch('/test', { name: 'Updated' })

      expect(fetch).toHaveBeenCalledWith('/test', expect.objectContaining({
        method: 'PATCH',
      }))
    })
  })

  describe('api.delete', () => {
    it('usa método DELETE', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ success: true }),
      })

      const { data } = await api.delete('/test')

      expect(fetch).toHaveBeenCalledWith('/test', expect.objectContaining({
        method: 'DELETE',
      }))
      expect(data).toEqual({ success: true })
    })
  })
})

describe('ApiError', () => {
  it('tiene propiedades correctas', () => {
    const error = new ApiError('Test error', 400, 'VALIDATION_ERROR')

    expect(error.message).toBe('Test error')
    expect(error.status).toBe(400)
    expect(error.code).toBe('VALIDATION_ERROR')
    expect(error.name).toBe('ApiError')
  })
})

describe('getErrorMessage', () => {
  it('retorna mensaje para código conocido', () => {
    const error = new ApiError('Error', 0, 'NETWORK_ERROR')
    expect(getErrorMessage(error)).toBe(errorMessages.NETWORK_ERROR)
  })

  it('retorna mensaje original para código desconocido', () => {
    const error = new ApiError('Custom error message', 500, 'UNKNOWN')
    expect(getErrorMessage(error)).toBe('Custom error message')
  })

  it('retorna mensaje original si no hay código', () => {
    const error = new ApiError('No code error', 500)
    expect(getErrorMessage(error)).toBe('No code error')
  })
})
