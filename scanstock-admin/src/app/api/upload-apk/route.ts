import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

const BUNNY_STORAGE_ZONE = process.env.BUNNY_STORAGE_ZONE
const BUNNY_API_KEY = process.env.BUNNY_STORAGE_PASSWORD
const BUNNY_STORAGE_REGION = process.env.BUNNY_STORAGE_REGION || ''
const BUNNY_PULL_ZONE = process.env.BUNNY_PULL_ZONE

// Build storage URL based on region
const getStorageUrl = () => {
  const regionPrefix = BUNNY_STORAGE_REGION ? `${BUNNY_STORAGE_REGION}.` : ''
  return `https://${regionPrefix}storage.bunnycdn.com/${BUNNY_STORAGE_ZONE}`
}

// Build CDN URL
const getCdnUrl = () => {
  return `https://${BUNNY_PULL_ZONE}.b-cdn.net`
}

// GET: Return upload credentials for direct client upload
export async function GET() {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 401 })
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('is_super_admin')
      .eq('id', user.id)
      .single()

    if (!profile?.is_super_admin) {
      return NextResponse.json({ error: 'Acceso denegado' }, { status: 403 })
    }

    if (!BUNNY_STORAGE_ZONE || !BUNNY_API_KEY || !BUNNY_PULL_ZONE) {
      return NextResponse.json(
        { error: 'Bunny Storage no está configurado' },
        { status: 500 }
      )
    }

    return NextResponse.json({
      storageUrl: getStorageUrl(),
      cdnUrl: getCdnUrl(),
      apiKey: BUNNY_API_KEY,
    })
  } catch (error) {
    console.error('Error getting upload config:', error)
    return NextResponse.json(
      { error: 'Error interno del servidor' },
      { status: 500 }
    )
  }
}

// POST: Save APK info to database after client upload
export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 401 })
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('is_super_admin')
      .eq('id', user.id)
      .single()

    if (!profile?.is_super_admin) {
      return NextResponse.json({ error: 'Acceso denegado' }, { status: 403 })
    }

    const body = await request.json()
    const { version, filename, size, url } = body

    if (!version || !filename || !url) {
      return NextResponse.json(
        { error: 'Faltan datos requeridos' },
        { status: 400 }
      )
    }

    // Update or insert app_settings
    const { data: existing } = await supabase
      .from('app_settings')
      .select('id')
      .single()

    if (existing) {
      const { error: updateError } = await supabase
        .from('app_settings')
        .update({
          apk_url: url,
          apk_version: version,
          apk_size: size,
          apk_filename: filename,
          updated_at: new Date().toISOString(),
          updated_by: user.id,
        })
        .eq('id', existing.id)

      if (updateError) {
        console.error('Error updating app_settings:', updateError)
        return NextResponse.json(
          { error: 'Error al guardar configuración' },
          { status: 500 }
        )
      }
    } else {
      const { error: insertError } = await supabase
        .from('app_settings')
        .insert({
          apk_url: url,
          apk_version: version,
          apk_size: size,
          apk_filename: filename,
          updated_by: user.id,
        })

      if (insertError) {
        console.error('Error inserting app_settings:', insertError)
        return NextResponse.json(
          { error: 'Error al guardar configuración' },
          { status: 500 }
        )
      }
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Save error:', error)
    return NextResponse.json(
      { error: 'Error interno del servidor' },
      { status: 500 }
    )
  }
}

export async function DELETE() {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 401 })
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('is_super_admin')
      .eq('id', user.id)
      .single()

    if (!profile?.is_super_admin) {
      return NextResponse.json({ error: 'Acceso denegado' }, { status: 403 })
    }

    if (!BUNNY_STORAGE_ZONE || !BUNNY_API_KEY) {
      return NextResponse.json(
        { error: 'Bunny Storage no está configurado' },
        { status: 500 }
      )
    }

    const { data: settings } = await supabase
      .from('app_settings')
      .select('*')
      .single()

    if (!settings?.apk_filename) {
      return NextResponse.json({ error: 'No hay APK para eliminar' }, { status: 404 })
    }

    // Delete from Bunny Storage
    const storageUrl = `${getStorageUrl()}/${settings.apk_filename}`
    const bunnyResponse = await fetch(storageUrl, {
      method: 'DELETE',
      headers: {
        'AccessKey': BUNNY_API_KEY,
      },
    })

    if (!bunnyResponse.ok && bunnyResponse.status !== 404) {
      const errorText = await bunnyResponse.text()
      console.error('Bunny Storage delete error:', errorText)
      return NextResponse.json(
        { error: 'Error al eliminar de Bunny Storage' },
        { status: 500 }
      )
    }

    const { error: updateError } = await supabase
      .from('app_settings')
      .update({
        apk_url: null,
        apk_version: null,
        apk_size: null,
        apk_filename: null,
        updated_at: new Date().toISOString(),
        updated_by: user.id,
      })
      .eq('id', settings.id)

    if (updateError) {
      console.error('Error updating app_settings:', updateError)
      return NextResponse.json(
        { error: 'Error al actualizar configuración' },
        { status: 500 }
      )
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Delete error:', error)
    return NextResponse.json(
      { error: 'Error interno del servidor' },
      { status: 500 }
    )
  }
}
