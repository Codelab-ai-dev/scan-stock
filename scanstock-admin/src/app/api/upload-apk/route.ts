import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

const BUNNY_STORAGE_ZONE = process.env.BUNNY_STORAGE_ZONE
const BUNNY_API_KEY = process.env.BUNNY_STORAGE_PASSWORD
const BUNNY_STORAGE_REGION = process.env.BUNNY_STORAGE_REGION || ''
const BUNNY_PULL_ZONE = process.env.BUNNY_PULL_ZONE

// Max file size: 200MB
const MAX_FILE_SIZE = 200 * 1024 * 1024

// Build storage URL based on region
const getStorageUrl = () => {
  const regionPrefix = BUNNY_STORAGE_REGION ? `${BUNNY_STORAGE_REGION}.` : ''
  return `https://${regionPrefix}storage.bunnycdn.com/${BUNNY_STORAGE_ZONE}`
}

// Build CDN URL
const getCdnUrl = () => {
  return `https://${BUNNY_PULL_ZONE}.b-cdn.net`
}

// Helper to verify super admin
async function verifySuperAdmin(supabase: Awaited<ReturnType<typeof createClient>>) {
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return { error: 'No autorizado', status: 401 }
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('is_super_admin')
    .eq('id', user.id)
    .single()

  if (!profile?.is_super_admin) {
    return { error: 'Acceso denegado', status: 403 }
  }

  return { user, profile }
}

// Validate version format (semver-like)
function isValidVersion(version: string): boolean {
  const versionRegex = /^\d+\.\d+(\.\d+)?$/
  return versionRegex.test(version)
}

// GET: Check configuration status (no sensitive data exposed)
export async function GET() {
  try {
    const supabase = await createClient()
    const auth = await verifySuperAdmin(supabase)

    if ('error' in auth) {
      return NextResponse.json({ error: auth.error }, { status: auth.status })
    }

    const isConfigured = !!(BUNNY_STORAGE_ZONE && BUNNY_API_KEY && BUNNY_PULL_ZONE)

    return NextResponse.json({
      configured: isConfigured,
      maxFileSize: MAX_FILE_SIZE,
    })
  } catch (error) {
    console.error('Error checking config:', error)
    return NextResponse.json(
      { error: 'Error interno del servidor' },
      { status: 500 }
    )
  }
}

// POST: Upload APK file to Bunny Storage (server-side)
export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()
    const auth = await verifySuperAdmin(supabase)

    if ('error' in auth) {
      return NextResponse.json({ error: auth.error }, { status: auth.status })
    }

    if (!BUNNY_STORAGE_ZONE || !BUNNY_API_KEY || !BUNNY_PULL_ZONE) {
      return NextResponse.json(
        { error: 'Bunny Storage no está configurado' },
        { status: 500 }
      )
    }

    // Parse form data
    const formData = await request.formData()
    const file = formData.get('file') as File | null
    const version = formData.get('version') as string | null

    // Validate inputs
    if (!file) {
      return NextResponse.json(
        { error: 'No se proporcionó archivo' },
        { status: 400 }
      )
    }

    if (!version || !version.trim()) {
      return NextResponse.json(
        { error: 'La versión es requerida' },
        { status: 400 }
      )
    }

    if (!isValidVersion(version.trim())) {
      return NextResponse.json(
        { error: 'Formato de versión inválido. Use formato: X.Y o X.Y.Z' },
        { status: 400 }
      )
    }

    // Validate file type
    if (!file.name.toLowerCase().endsWith('.apk')) {
      return NextResponse.json(
        { error: 'Solo se permiten archivos APK' },
        { status: 400 }
      )
    }

    // Validate file size
    if (file.size > MAX_FILE_SIZE) {
      return NextResponse.json(
        { error: `El archivo excede el tamaño máximo de ${MAX_FILE_SIZE / (1024 * 1024)}MB` },
        { status: 400 }
      )
    }

    // Validate content type
    const validContentTypes = [
      'application/vnd.android.package-archive',
      'application/octet-stream',
    ]
    if (!validContentTypes.includes(file.type) && file.type !== '') {
      return NextResponse.json(
        { error: 'Tipo de archivo no válido' },
        { status: 400 }
      )
    }

    const filename = `scanstock-v${version.trim()}.apk`
    const storageUrl = `${getStorageUrl()}/${filename}`

    // Get file buffer
    const arrayBuffer = await file.arrayBuffer()
    const buffer = Buffer.from(arrayBuffer)

    // Upload to Bunny Storage (server-side - API key never exposed to client)
    const uploadResponse = await fetch(storageUrl, {
      method: 'PUT',
      headers: {
        'AccessKey': BUNNY_API_KEY,
        'Content-Type': 'application/vnd.android.package-archive',
      },
      body: buffer,
    })

    if (!uploadResponse.ok) {
      const errorText = await uploadResponse.text()
      console.error('Bunny upload error:', errorText)
      return NextResponse.json(
        { error: 'Error al subir archivo a Bunny Storage' },
        { status: 500 }
      )
    }

    // Calculate file size string
    const fileSizeMB = (file.size / (1024 * 1024)).toFixed(1) + ' MB'
    const apkUrl = `${getCdnUrl()}/${filename}`

    // Update or insert app_settings
    const { data: existing } = await supabase
      .from('app_settings')
      .select('id')
      .single()

    const settingsData = {
      apk_url: apkUrl,
      apk_version: version.trim(),
      apk_size: fileSizeMB,
      apk_filename: filename,
      updated_at: new Date().toISOString(),
      updated_by: auth.user.id,
    }

    if (existing) {
      const { error: updateError } = await supabase
        .from('app_settings')
        .update(settingsData)
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
        .insert(settingsData)

      if (insertError) {
        console.error('Error inserting app_settings:', insertError)
        return NextResponse.json(
          { error: 'Error al guardar configuración' },
          { status: 500 }
        )
      }
    }

    return NextResponse.json({
      success: true,
      url: apkUrl,
      version: version.trim(),
      size: fileSizeMB,
    })
  } catch (error) {
    console.error('Upload error:', error)
    return NextResponse.json(
      { error: 'Error interno del servidor' },
      { status: 500 }
    )
  }
}

export async function DELETE() {
  try {
    const supabase = await createClient()
    const auth = await verifySuperAdmin(supabase)

    if ('error' in auth) {
      return NextResponse.json({ error: auth.error }, { status: auth.status })
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
        updated_by: auth.user.id,
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
