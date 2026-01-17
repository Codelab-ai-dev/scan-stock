import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { verifySuperAdmin, isAuthError, authErrorResponse, validateBusinessExists } from '@/lib/auth'

// Password validation
function isValidPassword(password: string): { valid: boolean; error?: string } {
  if (password.length < 8) {
    return { valid: false, error: 'La contraseña debe tener al menos 8 caracteres' }
  }
  if (!/[A-Z]/.test(password)) {
    return { valid: false, error: 'La contraseña debe contener al menos una mayúscula' }
  }
  if (!/[a-z]/.test(password)) {
    return { valid: false, error: 'La contraseña debe contener al menos una minúscula' }
  }
  if (!/[0-9]/.test(password)) {
    return { valid: false, error: 'La contraseña debe contener al menos un número' }
  }
  return { valid: true }
}

// Email validation
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

// GET: List users of a business
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const auth = await verifySuperAdmin()
    if (isAuthError(auth)) return authErrorResponse(auth)

    const { id } = await params

    if (!await validateBusinessExists(id)) {
      return NextResponse.json({ error: 'Negocio no encontrado' }, { status: 404 })
    }

    const supabase = await createClient()

    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('business_id', id)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error fetching users:', error)
      return NextResponse.json({ error: 'Error al obtener usuarios' }, { status: 500 })
    }

    return NextResponse.json(data || [])
  } catch (error) {
    console.error('Error fetching users:', error)
    return NextResponse.json({ error: 'Error interno' }, { status: 500 })
  }
}

// POST: Create a new user for this business
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const auth = await verifySuperAdmin()
    if (isAuthError(auth)) return authErrorResponse(auth)

    const { id: businessId } = await params

    if (!await validateBusinessExists(businessId)) {
      return NextResponse.json({ error: 'Negocio no encontrado' }, { status: 404 })
    }

    const body = await request.json()
    const { email, password, full_name, role } = body

    // Validate required fields
    if (!email || !password) {
      return NextResponse.json(
        { error: 'Email y contraseña son requeridos' },
        { status: 400 }
      )
    }

    // Validate email
    if (!isValidEmail(email)) {
      return NextResponse.json(
        { error: 'Formato de email inválido' },
        { status: 400 }
      )
    }

    // Validate password
    const passwordValidation = isValidPassword(password)
    if (!passwordValidation.valid) {
      return NextResponse.json(
        { error: passwordValidation.error },
        { status: 400 }
      )
    }

    // Validate role
    const validRoles = ['admin', 'user']
    if (role && !validRoles.includes(role)) {
      return NextResponse.json(
        { error: 'Rol inválido' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // User metadata for the trigger
    const userMetadata = {
      full_name: full_name?.trim() || '',
      role: role || 'user',
      business_id: businessId,
      is_super_admin: false,
    }

    // Try admin API first, then signUp as fallback
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: email.trim(),
      password,
      email_confirm: true,
      user_metadata: userMetadata,
    })

    let userId: string | null = null

    if (authError) {
      // Fallback to signUp
      const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          data: userMetadata,
        },
      })

      if (signUpError) {
        return NextResponse.json(
          { error: signUpError.message },
          { status: 400 }
        )
      }

      userId = signUpData.user?.id || null
    } else {
      userId = authData.user?.id || null
    }

    // Ensure profile is updated with correct business_id
    if (userId) {
      await supabase
        .from('profiles')
        .update({
          business_id: businessId,
          role: role || 'user',
          full_name: full_name?.trim() || '',
        })
        .eq('id', userId)
    }

    return NextResponse.json({
      success: true,
      userId,
    })
  } catch (error) {
    console.error('Error creating user:', error)
    return NextResponse.json({ error: 'Error interno' }, { status: 500 })
  }
}
