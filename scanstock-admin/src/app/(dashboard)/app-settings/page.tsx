'use client'

import { useState, useEffect, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { AppSettings } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Smartphone,
  Upload,
  Download,
  Loader2,
  Check,
  AlertCircle,
  FileArchive,
  Calendar,
  HardDrive,
  ExternalLink,
  Trash2,
} from 'lucide-react'

export default function AppSettingsPage() {
  const [appSettings, setAppSettings] = useState<AppSettings | null>(null)
  const [loading, setLoading] = useState(true)
  const [uploading, setUploading] = useState(false)
  const [uploadProgress, setUploadProgress] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [version, setVersion] = useState('')
  const fileInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    fetchAppSettings()
  }, [])

  async function fetchAppSettings() {
    const supabase = createClient()
    const { data, error } = await supabase
      .from('app_settings')
      .select('*')
      .single()

    if (error && error.code !== 'PGRST116') {
      console.error('Error fetching app settings:', error)
      setError('Error al cargar la configuración')
    } else {
      setAppSettings(data)
      if (data?.apk_version) {
        setVersion(data.apk_version)
      }
    }
    setLoading(false)
  }

  async function handleUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return

    if (!file.name.endsWith('.apk')) {
      setError('Solo se permiten archivos APK')
      return
    }

    if (!version.trim()) {
      setError('Por favor ingresa la versión del APK')
      return
    }

    setUploading(true)
    setUploadProgress(0)
    setError(null)
    setSuccess(null)

    try {
      // Get upload credentials from server
      const configResponse = await fetch('/api/upload-apk')
      const config = await configResponse.json()

      if (!configResponse.ok) {
        throw new Error(config.error || 'Error al obtener configuración')
      }

      const { storageUrl, cdnUrl, apiKey } = config
      const filename = `scanstock-v${version}.apk`

      // Upload directly to Bunny Storage using XMLHttpRequest for progress
      await new Promise<void>((resolve, reject) => {
        const xhr = new XMLHttpRequest()

        xhr.upload.addEventListener('progress', (event) => {
          if (event.lengthComputable) {
            const percent = Math.round((event.loaded / event.total) * 100)
            setUploadProgress(percent)
          }
        })

        xhr.addEventListener('load', () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve()
          } else {
            reject(new Error(`Error al subir: ${xhr.statusText}`))
          }
        })

        xhr.addEventListener('error', () => {
          reject(new Error('Error de red al subir el archivo'))
        })

        xhr.open('PUT', `${storageUrl}/${filename}`)
        xhr.setRequestHeader('AccessKey', apiKey)
        xhr.setRequestHeader('Content-Type', 'application/vnd.android.package-archive')
        xhr.send(file)
      })

      // Calculate file size
      const fileSizeMB = (file.size / (1024 * 1024)).toFixed(1) + ' MB'
      const apkUrl = `${cdnUrl}/${filename}`

      // Save to database
      const saveResponse = await fetch('/api/upload-apk', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          version,
          filename,
          size: fileSizeMB,
          url: apkUrl,
        }),
      })

      const saveResult = await saveResponse.json()

      if (!saveResponse.ok) {
        throw new Error(saveResult.error || 'Error al guardar configuración')
      }

      setSuccess('APK subido correctamente')
      await fetchAppSettings()
    } catch (err) {
      console.error('Upload error:', err)
      setError(err instanceof Error ? err.message : 'Error al subir el archivo')
    } finally {
      setUploading(false)
      setUploadProgress(0)
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
    }
  }

  async function handleDelete() {
    if (!confirm('¿Estás seguro de que quieres eliminar el APK actual?')) return

    setError(null)
    setSuccess(null)

    try {
      const response = await fetch('/api/upload-apk', {
        method: 'DELETE',
      })

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Error al eliminar el archivo')
      }

      setSuccess('APK eliminado correctamente')
      setVersion('')
      await fetchAppSettings()
    } catch (err) {
      console.error('Delete error:', err)
      setError(err instanceof Error ? err.message : 'Error al eliminar el archivo')
    }
  }

  function formatDate(dateString: string) {
    return new Date(dateString).toLocaleDateString('es-ES', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    )
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Aplicación</h1>
        <p className="text-muted-foreground mt-1">
          Gestiona la APK de ScanStock para Android
        </p>
      </div>

      {/* Alerts */}
      {error && (
        <div className="flex items-center gap-2 p-4 rounded-lg bg-destructive/10 border border-destructive/20 text-destructive">
          <AlertCircle className="w-5 h-5 shrink-0" />
          <p className="text-sm">{error}</p>
        </div>
      )}

      {success && (
        <div className="flex items-center gap-2 p-4 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-500">
          <Check className="w-5 h-5 shrink-0" />
          <p className="text-sm">{success}</p>
        </div>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Current APK Info */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Smartphone className="w-5 h-5 text-primary" />
              APK Actual
            </CardTitle>
            <CardDescription>
              Información del archivo APK disponible para descarga
            </CardDescription>
          </CardHeader>
          <CardContent>
            {appSettings?.apk_url ? (
              <div className="space-y-4">
                <div className="p-4 rounded-lg bg-muted/50 border border-border space-y-3">
                  <div className="flex items-center gap-3">
                    <FileArchive className="w-10 h-10 text-emerald-500" />
                    <div className="flex-1 min-w-0">
                      <p className="font-medium truncate">
                        {appSettings.apk_filename || 'scanstock.apk'}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        v{appSettings.apk_version || 'Sin versión'}
                      </p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4 pt-2 border-t border-border">
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <HardDrive className="w-4 h-4" />
                      <span>{appSettings.apk_size || 'Desconocido'}</span>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <Calendar className="w-4 h-4" />
                      <span>{formatDate(appSettings.updated_at)}</span>
                    </div>
                  </div>
                </div>

                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    className="flex-1"
                    onClick={() => window.open(appSettings.apk_url!, '_blank')}
                  >
                    <ExternalLink className="w-4 h-4 mr-2" />
                    Ver URL
                  </Button>
                  <Button
                    variant="outline"
                    className="text-destructive hover:bg-destructive/10"
                    onClick={handleDelete}
                  >
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </div>
              </div>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                <Smartphone className="w-12 h-12 mx-auto mb-3 opacity-50" />
                <p>No hay APK configurado</p>
                <p className="text-sm">Sube un archivo APK para habilitarlo</p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Upload New APK */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Upload className="w-5 h-5 text-primary" />
              Subir APK
            </CardTitle>
            <CardDescription>
              Sube una nueva versión del APK a Bunny Storage
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Versión</label>
              <Input
                placeholder="Ej: 2.0.1"
                value={version}
                onChange={(e) => setVersion(e.target.value)}
                disabled={uploading}
              />
              <p className="text-xs text-muted-foreground">
                Ingresa el número de versión del APK (ej: 2.0.1)
              </p>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Archivo APK</label>
              <div className="relative">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".apk"
                  onChange={handleUpload}
                  disabled={uploading || !version.trim()}
                  className="hidden"
                  id="apk-upload"
                />
                <label
                  htmlFor="apk-upload"
                  className={`flex flex-col items-center justify-center gap-2 w-full p-8 rounded-lg border-2 border-dashed transition-colors cursor-pointer ${
                    uploading || !version.trim()
                      ? 'border-border bg-muted/50 cursor-not-allowed opacity-50'
                      : 'border-primary/30 hover:border-primary/50 hover:bg-primary/5'
                  }`}
                >
                  {uploading ? (
                    <>
                      <Loader2 className="w-6 h-6 animate-spin text-primary" />
                      <span className="text-sm font-medium">Subiendo... {uploadProgress}%</span>
                      <div className="w-full max-w-xs bg-muted rounded-full h-2 mt-2">
                        <div
                          className="bg-primary h-2 rounded-full transition-all duration-300"
                          style={{ width: `${uploadProgress}%` }}
                        />
                      </div>
                    </>
                  ) : (
                    <>
                      <Upload className="w-6 h-6 text-primary" />
                      <span className="text-sm font-medium">
                        {version.trim() ? 'Haz clic para seleccionar el APK' : 'Ingresa la versión primero'}
                      </span>
                    </>
                  )}
                </label>
              </div>
              <p className="text-xs text-muted-foreground">
                Formatos aceptados: .apk (máximo 200MB)
              </p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Info Card */}
      <Card className="bg-primary/5 border-primary/20">
        <CardContent className="pt-6">
          <div className="flex items-start gap-4">
            <div className="w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center shrink-0">
              <Download className="w-5 h-5 text-primary" />
            </div>
            <div>
              <h3 className="font-semibold mb-1">Sobre la descarga de la app</h3>
              <p className="text-sm text-muted-foreground">
                El APK que subas aquí estará disponible en la página de descarga pública.
                Los usuarios podrán descargar la aplicación desde el botón &quot;Descargar App&quot;
                en la landing page y en la página /download.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
