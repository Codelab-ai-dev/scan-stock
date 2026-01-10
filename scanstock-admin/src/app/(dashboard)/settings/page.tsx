'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Loader2, Check } from 'lucide-react'
import type { Profile } from '@/lib/types'

export default function SettingsPage() {
  const supabase = createClient()

  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')

  useEffect(() => {
    async function loadProfile() {
      const { data: { user } } = await supabase.auth.getUser()

      if (user) {
        const { data: profileData } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single()

        if (profileData) {
          setProfile(profileData)
          setFullName(profileData.full_name ?? '')
          setEmail(profileData.email)
        }
      }

      setLoading(false)
    }

    loadProfile()
  }, [])

  async function handleSave() {
    if (!profile) return

    setSaving(true)
    setError(null)
    setSuccess(false)

    const { error: updateError } = await supabase
      .from('profiles')
      .update({
        full_name: fullName.trim(),
      })
      .eq('id', profile.id)

    if (updateError) {
      setError(updateError.message)
    } else {
      setSuccess(true)
      setProfile({ ...profile, full_name: fullName.trim() })
      setTimeout(() => setSuccess(false), 3000)
    }

    setSaving(false)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Configuración</h1>
        <p className="text-muted-foreground">
          Administra tu perfil y preferencias
        </p>
      </div>

      {error && (
        <Alert variant="destructive">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {success && (
        <Alert variant="success">
          <Check className="h-4 w-4" />
          <AlertDescription>Cambios guardados correctamente</AlertDescription>
        </Alert>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Perfil</CardTitle>
          <CardDescription>
            Información de tu cuenta de administrador
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <label className="text-sm font-medium">Nombre completo</label>
            <Input
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="Tu nombre"
            />
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium">Email</label>
            <Input value={email} disabled className="bg-muted" />
            <p className="text-xs text-muted-foreground">
              El email no se puede cambiar
            </p>
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium">Rol</label>
            <Input
              value={profile?.is_super_admin ? 'Super Administrador' : 'Usuario'}
              disabled
              className="bg-muted"
            />
          </div>

          <Button onClick={handleSave} disabled={saving}>
            {saving ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Guardando...
              </>
            ) : (
              'Guardar cambios'
            )}
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Información del sistema</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2 text-sm text-muted-foreground">
          <p>ScanStock Admin v1.0.0</p>
          <p>Next.js 15 + Supabase</p>
          <p>
            Cuenta creada:{' '}
            {profile?.created_at
              ? new Date(profile.created_at).toLocaleDateString('es-ES')
              : 'N/A'}
          </p>
        </CardContent>
      </Card>
    </div>
  )
}
