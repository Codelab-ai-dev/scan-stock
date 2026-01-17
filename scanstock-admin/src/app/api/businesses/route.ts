import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { verifySuperAdmin, isAuthError, authErrorResponse } from '@/lib/auth'
import { isValidSlug, isValidName, isValidUrl, sanitizeForDb, limitLength } from '@/lib/validation'

// GET: List all businesses
export async function GET() {
  try {
    const auth = await verifySuperAdmin()
    if (isAuthError(auth)) return authErrorResponse(auth)

    const supabase = await createClient()

    const { data, error } = await supabase
      .from('businesses')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error fetching businesses:', error)
      return NextResponse.json({ error: 'Error al obtener negocios' }, { status: 500 })
    }

    return NextResponse.json(data || [])
  } catch (error) {
    console.error('Error fetching businesses:', error)
    return NextResponse.json({ error: 'Error interno' }, { status: 500 })
  }
}

// POST: Create new business
export async function POST(request: NextRequest) {
  try {
    const auth = await verifySuperAdmin()
    if (isAuthError(auth)) return authErrorResponse(auth)

    const body = await request.json()
    const { name, slug, logo_url } = body

    // Validate name
    if (!name || !isValidName(name, 100)) {
      return NextResponse.json(
        { error: 'El nombre es requerido (máximo 100 caracteres)' },
        { status: 400 }
      )
    }

    // Validate slug
    if (!slug) {
      return NextResponse.json(
        { error: 'El slug es requerido' },
        { status: 400 }
      )
    }

    if (!isValidSlug(slug)) {
      return NextResponse.json(
        { error: 'El slug solo puede contener letras minúsculas, números y guiones' },
        { status: 400 }
      )
    }

    // Validate logo_url if provided
    if (logo_url && !isValidUrl(logo_url)) {
      return NextResponse.json(
        { error: 'URL del logo inválida' },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Check for duplicate slug
    const { data: existing } = await supabase
      .from('businesses')
      .select('id')
      .eq('slug', slug.trim().toLowerCase())
      .single()

    if (existing) {
      return NextResponse.json(
        { error: 'El slug ya está en uso' },
        { status: 400 }
      )
    }

    // Create business
    const { data, error } = await supabase
      .from('businesses')
      .insert({
        name: limitLength(sanitizeForDb(name), 100),
        slug: sanitizeForDb(slug).toLowerCase(),
        logo_url: logo_url ? sanitizeForDb(logo_url) : null,
        is_active: true,
      })
      .select()
      .single()

    if (error) {
      console.error('Error creating business:', error)
      return NextResponse.json(
        { error: 'Error al crear negocio' },
        { status: 500 }
      )
    }

    return NextResponse.json(data, { status: 201 })
  } catch (error) {
    console.error('Error creating business:', error)
    return NextResponse.json({ error: 'Error interno' }, { status: 500 })
  }
}
