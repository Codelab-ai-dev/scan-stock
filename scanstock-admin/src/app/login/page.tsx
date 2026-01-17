'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Loader2, Shield, Boxes, ChevronRight, AlertTriangle } from 'lucide-react'

export default function LoginPage() {
  const router = useRouter()
  const supabase = createClient()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isBlocked, setIsBlocked] = useState(false)
  const [remainingAttempts, setRemainingAttempts] = useState<number | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      // Use server-side API with rate limiting
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      })

      const result = await response.json()

      if (!response.ok) {
        setError(result.error)
        setIsBlocked(result.blocked || false)
        setRemainingAttempts(result.remainingAttempts ?? null)
        setLoading(false)
        return
      }

      // Login successful - refresh session on client
      await supabase.auth.refreshSession()
      router.push('/dashboard')
    } catch {
      setError('Error de conexión. Intenta de nuevo.')
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex">
      {/* Left Panel - Branding */}
      <div className="hidden lg:flex lg:w-1/2 relative bg-card overflow-hidden">
        {/* Animated grid background */}
        <div className="absolute inset-0 bg-grid-animated opacity-30" />

        {/* Gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-br from-primary/10 via-transparent to-secondary/5" />

        {/* Scan line effect */}
        <div className="absolute inset-0 scan-line" />

        {/* Content */}
        <div className="relative z-10 flex flex-col justify-between p-12 w-full">
          {/* Logo */}
          <div className="flex items-center gap-3">
            <Image
              src="/logo.png"
              alt="ScanStock"
              width={80}
              height={80}
              className="w-20 h-20 object-contain"
            />
            <div>
              <h1 className="text-2xl font-bold tracking-tight">ScanStock</h1>
              <p className="text-xs text-muted-foreground font-mono">ADMIN CONSOLE</p>
            </div>
          </div>

          {/* Center illustration */}
          <div className="flex-1 flex items-center justify-center">
            <div className="relative">
              {/* Decorative circles */}
              <div className="absolute -inset-20 rounded-full border border-primary/10" />
              <div className="absolute -inset-32 rounded-full border border-primary/5" />
              <div className="absolute -inset-44 rounded-full border border-primary/[0.02]" />

              {/* Main icon */}
              <div className="relative w-48 h-48 rounded-3xl bg-gradient-to-br from-card to-background border border-border flex items-center justify-center corner-accents">
                <div className="absolute inset-4 rounded-2xl bg-barcode opacity-50" />
                <Boxes className="w-24 h-24 text-primary/80" strokeWidth={1} />
              </div>
            </div>
          </div>

          {/* Features */}
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground uppercase tracking-widest font-mono">
              Control Total
            </p>
            <div className="grid grid-cols-2 gap-4">
              {[
                { label: 'Negocios', desc: 'Gestión centralizada' },
                { label: 'Módulos', desc: 'Control de acceso' },
                { label: 'Usuarios', desc: 'Administración' },
                { label: 'Analytics', desc: 'Métricas en tiempo real' },
              ].map((item, i) => (
                <div
                  key={item.label}
                  className="p-3 rounded-lg bg-background/50 border border-border/50 opacity-0 animate-fade-up"
                  style={{ animationDelay: `${i * 100}ms`, animationFillMode: 'forwards' }}
                >
                  <p className="font-medium text-sm">{item.label}</p>
                  <p className="text-xs text-muted-foreground">{item.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-transparent via-primary/50 to-transparent" />
      </div>

      {/* Right Panel - Login Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 relative">
        {/* Subtle grid */}
        <div className="absolute inset-0 bg-grid opacity-10" />

        <div className="w-full max-w-md relative z-10">
          {/* Mobile logo */}
          <div className="lg:hidden flex items-center justify-center gap-3 mb-12">
            <Image
              src="/logo.png"
              alt="ScanStock"
              width={80}
              height={80}
              className="w-20 h-20 object-contain"
            />
            <div>
              <h1 className="text-2xl font-bold tracking-tight">ScanStock</h1>
              <p className="text-xs text-muted-foreground font-mono">ADMIN</p>
            </div>
          </div>

          {/* Header */}
          <div className="mb-8">
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-primary/10 border border-primary/20 mb-4">
              <Shield className="w-3.5 h-3.5 text-primary" />
              <span className="text-xs font-medium text-primary">Acceso Seguro</span>
            </div>
            <h2 className="text-3xl font-bold tracking-tight mb-2">
              Bienvenido
            </h2>
            <p className="text-muted-foreground">
              Ingresa tus credenciales de super administrador
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            {error && (
              <Alert variant="destructive" className="border-destructive/50 bg-destructive/10">
                <div className="flex items-start gap-2">
                  {isBlocked && <AlertTriangle className="h-4 w-4 mt-0.5 shrink-0" />}
                  <div>
                    <AlertDescription>{error}</AlertDescription>
                    {remainingAttempts !== null && remainingAttempts > 0 && (
                      <p className="text-xs mt-1 opacity-80">
                        Intentos restantes: {remainingAttempts}
                      </p>
                    )}
                  </div>
                </div>
              </Alert>
            )}

            <div className="space-y-4">
              <div className="space-y-2">
                <label htmlFor="email" className="text-sm font-medium flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                  Email
                </label>
                <Input
                  id="email"
                  type="email"
                  placeholder="admin@scanstock.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="h-12 bg-card border-border focus:border-primary/50 focus:ring-primary/20 font-mono"
                  required
                />
              </div>

              <div className="space-y-2">
                <label htmlFor="password" className="text-sm font-medium flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                  Contraseña
                </label>
                <Input
                  id="password"
                  type="password"
                  placeholder="••••••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="h-12 bg-card border-border focus:border-primary/50 focus:ring-primary/20"
                  required
                />
              </div>
            </div>

            <Button
              type="submit"
              className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-semibold group"
              disabled={loading}
            >
              {loading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Verificando acceso...
                </>
              ) : (
                <>
                  Iniciar Sesión
                  <ChevronRight className="ml-2 h-4 w-4 transition-transform group-hover:translate-x-1" />
                </>
              )}
            </Button>
          </form>

          {/* Footer */}
          <div className="mt-12 pt-6 border-t border-border">
            <div className="flex items-center justify-between text-xs text-muted-foreground">
              <span className="font-mono">v1.0.0</span>
              <span>© 2024 ScanStock</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
