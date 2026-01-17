import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { verifySuperAdmin, isAuthError, authErrorResponse, validateBusinessExists } from '@/lib/auth'

// GET: Get business details
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const auth = await verifySuperAdmin()
    if (isAuthError(auth)) return authErrorResponse(auth)

    const { id } = await params
    const supabase = await createClient()

    const { data, error } = await supabase
      .from('businesses')
      .select('*')
      .eq('id', id)
      .single()

    if (error || !data) {
      return NextResponse.json({ error: 'Negocio no encontrado' }, { status: 404 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error getting business:', error)
    return NextResponse.json({ error: 'Error interno' }, { status: 500 })
  }
}

// PATCH: Update business
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const auth = await verifySuperAdmin()
    if (isAuthError(auth)) return authErrorResponse(auth)

    const { id } = await params

    // Validate business exists
    if (!await validateBusinessExists(id)) {
      return NextResponse.json({ error: 'Negocio no encontrado' }, { status: 404 })
    }

    const body = await request.json()
    const { name, slug, logo_url, is_active } = body

    // Validate inputs
    if (name !== undefined && (typeof name !== 'string' || name.trim().length === 0)) {
      return NextResponse.json({ error: 'Nombre inválido' }, { status: 400 })
    }

    if (slug !== undefined && (typeof slug !== 'string' || slug.trim().length === 0)) {
      return NextResponse.json({ error: 'Slug inválido' }, { status: 400 })
    }

    if (slug !== undefined && !/^[a-z0-9-]+$/.test(slug.trim())) {
      return NextResponse.json(
        { error: 'El slug solo puede contener letras minúsculas, números y guiones' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Check for duplicate slug
    if (slug) {
      const { data: existing } = await supabase
        .from('businesses')
        .select('id')
        .eq('slug', slug.trim())
        .neq('id', id)
        .single()

      if (existing) {
        return NextResponse.json({ error: 'El slug ya está en uso' }, { status: 400 })
      }
    }

    const updateData: Record<string, unknown> = {}
    if (name !== undefined) updateData.name = name.trim()
    if (slug !== undefined) updateData.slug = slug.trim()
    if (logo_url !== undefined) updateData.logo_url = logo_url?.trim() || null
    if (is_active !== undefined) updateData.is_active = Boolean(is_active)

    const { data, error } = await supabase
      .from('businesses')
      .update(updateData)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Error updating business:', error)
      return NextResponse.json({ error: 'Error al actualizar' }, { status: 500 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error updating business:', error)
    return NextResponse.json({ error: 'Error interno' }, { status: 500 })
  }
}

// DELETE: Delete business
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const auth = await verifySuperAdmin()
    if (isAuthError(auth)) return authErrorResponse(auth)

    const { id } = await params

    // Validate business exists
    if (!await validateBusinessExists(id)) {
      return NextResponse.json({ error: 'Negocio no encontrado' }, { status: 404 })
    }

    const supabase = await createClient()

    const { error } = await supabase
      .from('businesses')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Error deleting business:', error)
      return NextResponse.json({ error: 'Error al eliminar' }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error deleting business:', error)
    return NextResponse.json({ error: 'Error interno' }, { status: 500 })
  }
}
