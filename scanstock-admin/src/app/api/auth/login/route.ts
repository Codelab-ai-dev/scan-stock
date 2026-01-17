import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// Simple in-memory rate limiter
// In production, use Redis or a similar solution for distributed systems
const loginAttempts = new Map<string, { count: number; lastAttempt: number; blockedUntil: number }>()

const RATE_LIMIT_WINDOW = 15 * 60 * 1000 // 15 minutes
const MAX_ATTEMPTS = 5 // Max attempts per window
const BLOCK_DURATION = 15 * 60 * 1000 // 15 minutes block

function getClientIdentifier(request: NextRequest, email: string): string {
  const forwarded = request.headers.get('x-forwarded-for')
  const ip = forwarded ? forwarded.split(',')[0].trim() : 'unknown'
  // Combine IP and email to prevent blocking all users from same IP
  return `${ip}:${email.toLowerCase()}`
}

function cleanupOldEntries() {
  const now = Date.now()
  for (const [key, data] of loginAttempts.entries()) {
    if (now - data.lastAttempt > RATE_LIMIT_WINDOW && now > data.blockedUntil) {
      loginAttempts.delete(key)
    }
  }
}

function checkRateLimit(identifier: string): { allowed: boolean; remainingAttempts: number; blockedUntil?: number } {
  cleanupOldEntries()

  const now = Date.now()
  const data = loginAttempts.get(identifier)

  if (!data) {
    return { allowed: true, remainingAttempts: MAX_ATTEMPTS - 1 }
  }

  // Check if blocked
  if (data.blockedUntil > now) {
    return {
      allowed: false,
      remainingAttempts: 0,
      blockedUntil: data.blockedUntil
    }
  }

  // Reset if window has passed
  if (now - data.lastAttempt > RATE_LIMIT_WINDOW) {
    loginAttempts.delete(identifier)
    return { allowed: true, remainingAttempts: MAX_ATTEMPTS - 1 }
  }

  // Check attempts
  if (data.count >= MAX_ATTEMPTS) {
    data.blockedUntil = now + BLOCK_DURATION
    return {
      allowed: false,
      remainingAttempts: 0,
      blockedUntil: data.blockedUntil
    }
  }

  return { allowed: true, remainingAttempts: MAX_ATTEMPTS - data.count - 1 }
}

function recordAttempt(identifier: string, success: boolean) {
  if (success) {
    // Reset on successful login
    loginAttempts.delete(identifier)
    return
  }

  const now = Date.now()
  const data = loginAttempts.get(identifier)

  if (!data || now - data.lastAttempt > RATE_LIMIT_WINDOW) {
    loginAttempts.set(identifier, { count: 1, lastAttempt: now, blockedUntil: 0 })
  } else {
    data.count++
    data.lastAttempt = now
    if (data.count >= MAX_ATTEMPTS) {
      data.blockedUntil = now + BLOCK_DURATION
    }
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { email, password } = body

    // Validate input
    if (!email || !password) {
      return NextResponse.json(
        { error: 'Email y contraseña son requeridos' },
        { status: 400 }
      )
    }

    // Check rate limit
    const identifier = getClientIdentifier(request, email)
    const rateLimit = checkRateLimit(identifier)

    if (!rateLimit.allowed) {
      const waitMinutes = Math.ceil((rateLimit.blockedUntil! - Date.now()) / 60000)
      return NextResponse.json(
        {
          error: `Demasiados intentos fallidos. Intenta de nuevo en ${waitMinutes} minutos.`,
          blocked: true,
          blockedUntil: rateLimit.blockedUntil
        },
        { status: 429 }
      )
    }

    // Attempt login
    const supabase = await createClient()
    const { data, error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (signInError) {
      recordAttempt(identifier, false)
      const updatedLimit = checkRateLimit(identifier)

      return NextResponse.json(
        {
          error: 'Credenciales inválidas',
          remainingAttempts: updatedLimit.remainingAttempts
        },
        { status: 401 }
      )
    }

    // Check if user is super admin
    const { data: profile } = await supabase
      .from('profiles')
      .select('is_super_admin')
      .eq('id', data.user.id)
      .single()

    if (!profile?.is_super_admin) {
      await supabase.auth.signOut()
      recordAttempt(identifier, false)

      return NextResponse.json(
        { error: 'Acceso restringido a administradores' },
        { status: 403 }
      )
    }

    // Success - reset rate limit
    recordAttempt(identifier, true)

    return NextResponse.json({
      success: true,
      user: {
        id: data.user.id,
        email: data.user.email,
      }
    })
  } catch (error) {
    console.error('Login error:', error)
    return NextResponse.json(
      { error: 'Error interno del servidor' },
      { status: 500 }
    )
  }
}
