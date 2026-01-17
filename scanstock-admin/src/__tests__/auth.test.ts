import { describe, it, expect, vi, beforeEach } from 'vitest'
import { isAuthError } from '../lib/auth'
import type { AuthResult, AuthError } from '../lib/auth'

describe('isAuthError', () => {
  it('retorna true para AuthError', () => {
    const error: AuthError = { error: 'No autorizado', status: 401 }
    expect(isAuthError(error)).toBe(true)
  })

  it('retorna false para AuthResult', () => {
    const result: AuthResult = {
      user: { id: '123', email: 'test@test.com' },
      profile: { is_super_admin: true, business_id: null, role: 'admin' },
    }
    expect(isAuthError(result)).toBe(false)
  })
})

// Note: verifySuperAdmin and other server-side functions
// would need integration tests with a real or mocked Supabase instance
