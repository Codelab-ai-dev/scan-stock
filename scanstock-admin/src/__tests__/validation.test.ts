import { describe, it, expect } from 'vitest'
import {
  isValidEmail,
  validatePassword,
  isValidSlug,
  isValidUUID,
  isValidVersion,
  isValidUrl,
  isValidRole,
  isValidName,
  limitLength,
  sanitizeForDb,
} from '../lib/validation'

describe('isValidEmail', () => {
  it('acepta emails válidos', () => {
    expect(isValidEmail('test@example.com')).toBe(true)
    expect(isValidEmail('user.name@domain.co')).toBe(true)
    expect(isValidEmail('user+tag@example.org')).toBe(true)
  })

  it('rechaza emails inválidos', () => {
    expect(isValidEmail('')).toBe(false)
    expect(isValidEmail('invalid')).toBe(false)
    expect(isValidEmail('no@')).toBe(false)
    expect(isValidEmail('@nodomain.com')).toBe(false)
    expect(isValidEmail('spaces in@email.com')).toBe(false)
  })
})

describe('validatePassword', () => {
  it('valida contraseña fuerte', () => {
    const result = validatePassword('Password1')
    expect(result.valid).toBe(true)
    expect(result.minLength).toBe(true)
    expect(result.hasUppercase).toBe(true)
    expect(result.hasLowercase).toBe(true)
    expect(result.hasNumber).toBe(true)
  })

  it('rechaza contraseña muy corta', () => {
    const result = validatePassword('Pass1')
    expect(result.valid).toBe(false)
    expect(result.minLength).toBe(false)
    expect(result.error).toContain('8 caracteres')
  })

  it('rechaza contraseña sin mayúscula', () => {
    const result = validatePassword('password1')
    expect(result.valid).toBe(false)
    expect(result.hasUppercase).toBe(false)
  })

  it('rechaza contraseña sin minúscula', () => {
    const result = validatePassword('PASSWORD1')
    expect(result.valid).toBe(false)
    expect(result.hasLowercase).toBe(false)
  })

  it('rechaza contraseña sin número', () => {
    const result = validatePassword('Password')
    expect(result.valid).toBe(false)
    expect(result.hasNumber).toBe(false)
  })
})

describe('isValidSlug', () => {
  it('acepta slugs válidos', () => {
    expect(isValidSlug('my-store')).toBe(true)
    expect(isValidSlug('store123')).toBe(true)
    expect(isValidSlug('a')).toBe(true)
    expect(isValidSlug('my-super-store-2024')).toBe(true)
  })

  it('rechaza slugs inválidos', () => {
    expect(isValidSlug('')).toBe(false)
    expect(isValidSlug('My-Store')).toBe(false) // uppercase
    expect(isValidSlug('my_store')).toBe(false) // underscore
    expect(isValidSlug('my store')).toBe(false) // space
    expect(isValidSlug('-start')).toBe(false) // starts with dash
    expect(isValidSlug('end-')).toBe(false) // ends with dash
  })
})

describe('isValidUUID', () => {
  it('acepta UUIDs válidos', () => {
    expect(isValidUUID('123e4567-e89b-12d3-a456-426614174000')).toBe(true)
    expect(isValidUUID('550e8400-e29b-41d4-a716-446655440000')).toBe(true)
  })

  it('rechaza UUIDs inválidos', () => {
    expect(isValidUUID('')).toBe(false)
    expect(isValidUUID('not-a-uuid')).toBe(false)
    expect(isValidUUID('123e4567-e89b-12d3-a456')).toBe(false) // too short
    expect(isValidUUID('123e4567-e89b-12d3-a456-426614174000-extra')).toBe(false)
  })
})

describe('isValidVersion', () => {
  it('acepta versiones válidas', () => {
    expect(isValidVersion('1.0')).toBe(true)
    expect(isValidVersion('2.0.1')).toBe(true)
    expect(isValidVersion('10.20.30')).toBe(true)
  })

  it('rechaza versiones inválidas', () => {
    expect(isValidVersion('')).toBe(false)
    expect(isValidVersion('1')).toBe(false)
    expect(isValidVersion('1.0.0.0')).toBe(false)
    expect(isValidVersion('v1.0')).toBe(false)
    expect(isValidVersion('1.0-beta')).toBe(false)
  })
})

describe('isValidUrl', () => {
  it('acepta URLs válidas', () => {
    expect(isValidUrl('https://example.com')).toBe(true)
    expect(isValidUrl('http://localhost:3000')).toBe(true)
    expect(isValidUrl('https://sub.domain.com/path?query=1')).toBe(true)
  })

  it('rechaza URLs inválidas', () => {
    expect(isValidUrl('')).toBe(false)
    expect(isValidUrl('not-a-url')).toBe(false)
    expect(isValidUrl('ftp://files.com')).toBe(false) // only http/https
    expect(isValidUrl('//no-protocol.com')).toBe(false)
  })
})

describe('isValidRole', () => {
  it('acepta roles válidos', () => {
    expect(isValidRole('admin')).toBe(true)
    expect(isValidRole('user')).toBe(true)
  })

  it('rechaza roles inválidos', () => {
    expect(isValidRole('superadmin')).toBe(false)
    expect(isValidRole('guest')).toBe(false)
    expect(isValidRole('')).toBe(false)
  })
})

describe('isValidName', () => {
  it('acepta nombres válidos', () => {
    expect(isValidName('Juan')).toBe(true)
    expect(isValidName('Mi Tienda')).toBe(true)
  })

  it('rechaza nombres vacíos', () => {
    expect(isValidName('')).toBe(false)
    expect(isValidName('   ')).toBe(false)
  })

  it('rechaza nombres muy largos', () => {
    const longName = 'a'.repeat(101)
    expect(isValidName(longName)).toBe(false)
    expect(isValidName(longName, 50)).toBe(false)
  })
})

describe('limitLength', () => {
  it('limita strings largos', () => {
    expect(limitLength('hello world', 5)).toBe('hello')
    expect(limitLength('short', 10)).toBe('short')
  })

  it('maneja espacios', () => {
    expect(limitLength('  hello  ', 5)).toBe('hello')
  })
})

describe('sanitizeForDb', () => {
  it('elimina espacios al inicio y final', () => {
    expect(sanitizeForDb('  hello  ')).toBe('hello')
    expect(sanitizeForDb('\n\ttest\n\t')).toBe('test')
  })
})
