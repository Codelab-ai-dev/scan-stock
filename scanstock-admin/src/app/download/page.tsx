'use client'

import Link from 'next/link'
import Image from 'next/image'
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { AppSettings } from '@/lib/types'
import {
  ScanBarcode,
  Download,
  Smartphone,
  Check,
  ArrowLeft,
  Shield,
  Zap,
  Loader2,
  AlertCircle,
} from 'lucide-react'

export default function DownloadPage() {
  const [appSettings, setAppSettings] = useState<AppSettings | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function fetchAppSettings() {
      const supabase = createClient()
      const { data, error } = await supabase
        .from('app_settings')
        .select('*')
        .single()

      if (error) {
        console.error('Error fetching app settings:', error)
        setError('No se pudo cargar la información de descarga')
      } else {
        setAppSettings(data)
      }
      setLoading(false)
    }

    fetchAppSettings()
  }, [])

  const handleDownload = () => {
    if (appSettings?.apk_url) {
      window.open(appSettings.apk_url, '_blank')
    }
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Background effects */}
      <div className="fixed inset-0 bg-grid opacity-[0.02] pointer-events-none" />

      {/* Navigation */}
      <nav className="border-b border-border/50 bg-background/80 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-20">
            <Link href="/" className="flex items-center gap-2">
              <Image
                src="/logo.png"
                alt="ScanStock"
                width={72}
                height={72}
                className="w-[72px] h-[72px] object-contain"
              />
              <span className="font-bold text-2xl">ScanStock</span>
            </Link>

            <Link
              href="/"
              className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              Volver al inicio
            </Link>
          </div>
        </div>
      </nav>

      <main className="py-16 px-4 sm:px-6 lg:px-8">
        <div className="max-w-2xl mx-auto">
          {/* Header */}
          <div className="text-center mb-12">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20 mb-6">
              <Download className="w-4 h-4 text-primary" />
              <span className="text-sm font-medium text-primary">Descarga Gratuita</span>
            </div>

            <h1 className="text-4xl sm:text-5xl font-bold mb-4">
              Descarga ScanStock
            </h1>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Obtén la aplicación móvil y comienza a gestionar tu inventario de manera inteligente.
            </p>
          </div>

          {/* Download Card - Android Only */}
          <div className="mb-16">
            <div className="relative p-8 rounded-2xl border border-border bg-card overflow-hidden group hover:border-primary/30 transition-all">
              <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-primary/30 to-transparent" />

              <div className="flex items-start gap-4 mb-6">
                <div className="w-16 h-16 rounded-2xl bg-emerald-500/20 flex items-center justify-center shrink-0">
                  <Smartphone className="w-8 h-8 text-emerald-500" />
                </div>
                <div>
                  <h2 className="text-xl font-bold mb-1">Android</h2>
                  {loading ? (
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <Loader2 className="w-4 h-4 animate-spin" />
                      Cargando...
                    </div>
                  ) : appSettings?.apk_version ? (
                    <p className="text-sm text-muted-foreground">
                      APK v{appSettings.apk_version} {appSettings.apk_size && `• ${appSettings.apk_size}`}
                    </p>
                  ) : (
                    <p className="text-sm text-muted-foreground">Versión disponible</p>
                  )}
                </div>
              </div>

              <ul className="space-y-2 mb-6">
                {[
                  'Android 8.0 o superior',
                  'Cámara para escaneo',
                  'Conexión a internet',
                ].map((req) => (
                  <li key={req} className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Check className="w-4 h-4 text-primary" />
                    {req}
                  </li>
                ))}
              </ul>

              {error ? (
                <div className="w-full py-4 rounded-xl bg-destructive/10 border border-destructive/20 flex items-center justify-center gap-2 text-destructive">
                  <AlertCircle className="w-5 h-5" />
                  <span className="text-sm font-medium">{error}</span>
                </div>
              ) : loading ? (
                <button
                  disabled
                  className="w-full py-4 rounded-xl bg-primary/50 text-primary-foreground font-semibold flex items-center justify-center gap-2"
                >
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Cargando...
                </button>
              ) : appSettings?.apk_url ? (
                <button
                  onClick={handleDownload}
                  className="w-full py-4 rounded-xl bg-primary text-primary-foreground font-semibold flex items-center justify-center gap-2 hover:bg-primary/90 transition-all shadow-lg shadow-primary/20 group"
                >
                  <Download className="w-5 h-5" />
                  Descargar APK
                </button>
              ) : (
                <div className="w-full py-4 rounded-xl bg-muted border border-border flex items-center justify-center gap-2 text-muted-foreground">
                  <AlertCircle className="w-5 h-5" />
                  <span className="text-sm font-medium">APK no disponible aún</span>
                </div>
              )}
            </div>
          </div>

          {/* Features */}
          <div className="mb-16">
            <h3 className="text-xl font-bold text-center mb-8">¿Qué incluye la app?</h3>

            <div className="grid sm:grid-cols-3 gap-4">
              {[
                {
                  icon: ScanBarcode,
                  title: 'Escaneo Rápido',
                  description: 'Escanea productos en segundos',
                },
                {
                  icon: Shield,
                  title: 'Datos Seguros',
                  description: 'Encriptación de extremo a extremo',
                },
                {
                  icon: Zap,
                  title: 'Modo Offline',
                  description: 'Trabaja sin conexión',
                },
              ].map((feature) => (
                <div key={feature.title} className="p-4 rounded-xl border border-border bg-card text-center">
                  <div className="w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center mx-auto mb-3">
                    <feature.icon className="w-5 h-5 text-primary" />
                  </div>
                  <h4 className="font-medium mb-1">{feature.title}</h4>
                  <p className="text-xs text-muted-foreground">{feature.description}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Installation Guide */}
          <div className="p-6 rounded-2xl border border-border bg-card">
            <h3 className="font-bold mb-4">Cómo instalar en Android</h3>

            <ol className="space-y-4">
              {[
                'Descarga el archivo APK desde el botón de arriba',
                'Abre el archivo descargado',
                'Si es necesario, habilita "Instalar desde fuentes desconocidas" en la configuración',
                'Sigue las instrucciones de instalación',
                'Abre ScanStock e inicia sesión con tu cuenta',
              ].map((step, index) => (
                <li key={index} className="flex items-start gap-4">
                  <span className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center shrink-0 text-sm font-mono text-primary">
                    {index + 1}
                  </span>
                  <span className="text-sm text-muted-foreground pt-0.5">{step}</span>
                </li>
              ))}
            </ol>
          </div>

          {/* Support */}
          <div className="mt-12 text-center">
            <p className="text-sm text-muted-foreground mb-2">
              ¿Necesitas ayuda con la instalación?
            </p>
            <a href="#" className="text-sm text-primary hover:underline">
              Contactar soporte técnico
            </a>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-border py-8 px-4">
        <div className="max-w-4xl mx-auto flex items-center justify-between text-sm text-muted-foreground">
          <p>© 2024 ScanStock</p>
          <div className="flex items-center gap-4">
            <a href="#" className="hover:text-foreground transition-colors">Privacidad</a>
            <a href="#" className="hover:text-foreground transition-colors">Términos</a>
          </div>
        </div>
      </footer>
    </div>
  )
}
