// Input validation and sanitization utilities

// Email validation
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email.trim())
}

// Password validation
export interface PasswordValidation {
  valid: boolean
  minLength: boolean
  hasUppercase: boolean
  hasLowercase: boolean
  hasNumber: boolean
  error?: string
}

export function validatePassword(password: string): PasswordValidation {
  const minLength = password.length >= 8
  const hasUppercase = /[A-Z]/.test(password)
  const hasLowercase = /[a-z]/.test(password)
  const hasNumber = /[0-9]/.test(password)
  const valid = minLength && hasUppercase && hasLowercase && hasNumber

  let error: string | undefined
  if (!valid) {
    if (!minLength) error = 'La contraseña debe tener al menos 8 caracteres'
    else if (!hasUppercase) error = 'La contraseña debe contener al menos una mayúscula'
    else if (!hasLowercase) error = 'La contraseña debe contener al menos una minúscula'
    else if (!hasNumber) error = 'La contraseña debe contener al menos un número'
  }

  return { valid, minLength, hasUppercase, hasLowercase, hasNumber, error }
}

// Slug validation
export function isValidSlug(slug: string): boolean {
  const slugRegex = /^[a-z0-9]+(?:-[a-z0-9]+)*$/
  return slugRegex.test(slug.trim())
}

// Sanitize string for display (prevent XSS)
export function sanitizeString(input: string): string {
  return input
    .trim()
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/\//g, '&#x2F;')
}

// Sanitize for database (basic cleanup without HTML encoding)
export function sanitizeForDb(input: string): string {
  return input.trim()
}

// UUID validation
export function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

// Version format validation (semver-like)
export function isValidVersion(version: string): boolean {
  const versionRegex = /^\d+\.\d+(\.\d+)?$/
  return versionRegex.test(version.trim())
}

// URL validation
export function isValidUrl(url: string): boolean {
  try {
    const parsed = new URL(url.trim())
    return parsed.protocol === 'http:' || parsed.protocol === 'https:'
  } catch {
    return false
  }
}

// Role validation
export const VALID_ROLES = ['admin', 'user'] as const
export type UserRole = typeof VALID_ROLES[number]

export function isValidRole(role: string): role is UserRole {
  return VALID_ROLES.includes(role as UserRole)
}

// Name validation (prevents empty or very long names)
export function isValidName(name: string, maxLength = 100): boolean {
  const trimmed = name.trim()
  return trimmed.length > 0 && trimmed.length <= maxLength
}

// Limit string length
export function limitLength(input: string, maxLength: number): string {
  const trimmed = input.trim()
  return trimmed.length > maxLength ? trimmed.slice(0, maxLength) : trimmed
}
