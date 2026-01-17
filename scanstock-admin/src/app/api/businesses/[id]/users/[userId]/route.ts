import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import {
  verifySuperAdmin,
  isAuthError,
  authErrorResponse,
  validateBusinessExists,
  validateUserBelongsToBusiness,
} from '@/lib/auth'

// PATCH: Update user role
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; userId: string }> }
) {
  try {
    const auth = await verifySuperAdmin()
    if (isAuthError(auth)) return authErrorResponse(auth)

    const { id: businessId, userId } = await params

    // Validate business exists
    if (!await validateBusinessExists(businessId)) {
      return NextResponse.json({ error: 'Negocio no encontrado' }, { status: 404 })
    }

    // Validate user belongs to business
    if (!await validateUserBelongsToBusiness(userId, businessId)) {
      return NextResponse.json(
        { error: 'Usuario no pertenece a este negocio' },
        { status: 404 }
      )
    }

    const body = await request.json()
    const { role } = body

    // Validate role
    const validRoles = ['admin', 'user']
    if (!role || !validRoles.includes(role)) {
      return NextResponse.json({ error: 'Rol inválido' }, { status: 400 })
    }

    const supabase = await createClient()

    const { data, error } = await supabase
      .from('profiles')
      .update({ role })
      .eq('id', userId)
      .eq('business_id', businessId)
      .select()
      .single()

    if (error) {
      console.error('Error updating user role:', error)
      return NextResponse.json({ error: 'Error al actualizar rol' }, { status: 500 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error updating user role:', error)
    return NextResponse.json({ error: 'Error interno' }, { status: 500 })
  }
}

// DELETE: Remove user from business (sets business_id to null)
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; userId: string }> }
) {
  try {
    const auth = await verifySuperAdmin()
    if (isAuthError(auth)) return authErrorResponse(auth)

    const { id: businessId, userId } = await params

    // Validate business exists
    if (!await validateBusinessExists(businessId)) {
      return NextResponse.json({ error: 'Negocio no encontrado' }, { status: 404 })
    }

    // Validate user belongs to business
    if (!await validateUserBelongsToBusiness(userId, businessId)) {
      return NextResponse.json(
        { error: 'Usuario no pertenece a este negocio' },
        { status: 404 }
      )
    }

    const supabase = await createClient()

    // Remove user from business (don't delete the profile, just unlink)
    const { error } = await supabase
      .from('profiles')
      .update({ business_id: null })
      .eq('id', userId)
      .eq('business_id', businessId)

    if (error) {
      console.error('Error removing user:', error)
      return NextResponse.json({ error: 'Error al remover usuario' }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error removing user:', error)
    return NextResponse.json({ error: 'Error interno' }, { status: 500 })
  }
}
