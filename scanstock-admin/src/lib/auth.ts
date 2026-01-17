import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export interface AuthResult {
  user: {
    id: string
    email: string
  }
  profile: {
    is_super_admin: boolean
    business_id: string | null
    role: string
  }
}

export interface AuthError {
  error: string
  status: number
}

export async function verifySuperAdmin(): Promise<AuthResult | AuthError> {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return { error: 'No autorizado', status: 401 }
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('is_super_admin, business_id, role')
    .eq('id', user.id)
    .single()

  if (!profile?.is_super_admin) {
    return { error: 'Acceso denegado', status: 403 }
  }

  return {
    user: {
      id: user.id,
      email: user.email!,
    },
    profile: {
      is_super_admin: profile.is_super_admin,
      business_id: profile.business_id,
      role: profile.role,
    }
  }
}

export function isAuthError(result: AuthResult | AuthError): result is AuthError {
  return 'error' in result
}

export function authErrorResponse(error: AuthError): NextResponse {
  return NextResponse.json({ error: error.error }, { status: error.status })
}

// Validate that a business exists
export async function validateBusinessExists(businessId: string): Promise<boolean> {
  const supabase = await createClient()

  const { data } = await supabase
    .from('businesses')
    .select('id')
    .eq('id', businessId)
    .single()

  return !!data
}

// Validate that a user belongs to a business (for non-super-admin operations)
export async function validateUserBelongsToBusiness(
  userId: string,
  businessId: string
): Promise<boolean> {
  const supabase = await createClient()

  const { data } = await supabase
    .from('profiles')
    .select('id, business_id')
    .eq('id', userId)
    .eq('business_id', businessId)
    .single()

  return !!data
}
