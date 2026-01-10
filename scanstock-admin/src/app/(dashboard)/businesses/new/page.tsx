'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ArrowLeft, Loader2 } from 'lucide-react'
import type { Module } from '@/lib/types'

export default function NewBusinessPage() {
  const router = useRouter()
  const supabase = createClient()

  const [name, setName] = useState('')
  const [slug, setSlug] = useState('')
  const [logoUrl, setLogoUrl] = useState('')
  const [modules, setModules] = useState<Module[]>([])
  const [selectedModules, setSelectedModules] = useState<string[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function loadModules() {
      const { data } = await supabase.from('modules').select('*').order('name')
      setModules(data ?? [])
      // Seleccionar módulos por defecto
      setSelectedModules((data ?? []).filter((m) => m.is_default).map((m) => m.id))
    }
    loadModules()
  }, [])

  // Auto-generar slug desde el nombre
  useEffect(() => {
    if (name) {
      setSlug(
        name
          .toLowerCase()
          .normalize('NFD')
          .replace(/[\u0300-\u036f]/g, '')
          .replace(/[^a-z0-9]+/g, '-')
          .replace(/^-|-$/g, '')
      )
    }
  }, [name])

  function toggleModule(moduleId: string, isDefault: boolean) {
    if (isDefault) return
    setSelectedModules((prev) =>
      prev.includes(moduleId)
        ? prev.filter((m) => m !== moduleId)
        : [...prev, moduleId]
    )
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)

    if (!name.trim()) {
      setError('El nombre es requerido')
      setLoading(false)
      return
    }

    // Verificar slug único
    const { data: existing } = await supabase
      .from('businesses')
      .select('id')
      .eq('slug', slug)
      .maybeSingle()

    if (existing) {
      setError('Este slug ya está en uso')
      setLoading(false)
      return
    }

    // Crear negocio
    const { data: newBusiness, error: createError } = await supabase
      .from('businesses')
      .insert({
        name: name.trim(),
        slug: slug.trim(),
        logo_url: logoUrl.trim() || null,
      })
      .select()
      .single()

    if (createError) {
      setError(createError.message)
      setLoading(false)
      return
    }

    // Agregar módulos
    if (selectedModules.length > 0) {
      await supabase.from('business_modules').insert(
        selectedModules.map((moduleId) => ({
          business_id: newBusiness.id,
          module_id: moduleId,
        }))
      )
    }

    router.push(`/businesses/${newBusiness.id}`)
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/businesses">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold">Nuevo Negocio</h1>
          <p className="text-muted-foreground">
            Crea un nuevo negocio en la plataforma
          </p>
        </div>
      </div>

      <form onSubmit={handleSubmit}>
        <Card>
          <CardHeader>
            <CardTitle>Información básica</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {error && (
              <Alert variant="destructive">
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}

            <div className="space-y-2">
              <label htmlFor="name" className="text-sm font-medium">
                Nombre del negocio
              </label>
              <Input
                id="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Mi Tienda"
                required
              />
            </div>

            <div className="space-y-2">
              <label htmlFor="slug" className="text-sm font-medium">
                Slug (URL amigable)
              </label>
              <div className="flex">
                <span className="inline-flex items-center px-3 rounded-l-md border border-r-0 bg-muted text-muted-foreground text-sm">
                  /
                </span>
                <Input
                  id="slug"
                  value={slug}
                  onChange={(e) => setSlug(e.target.value)}
                  placeholder="mi-tienda"
                  className="rounded-l-none"
                  required
                />
              </div>
              <p className="text-xs text-muted-foreground">
                Solo letras minúsculas, números y guiones
              </p>
            </div>

            <div className="space-y-2">
              <label htmlFor="logo" className="text-sm font-medium">
                URL del logo (opcional)
              </label>
              <Input
                id="logo"
                type="url"
                value={logoUrl}
                onChange={(e) => setLogoUrl(e.target.value)}
                placeholder="https://ejemplo.com/logo.png"
              />
            </div>
          </CardContent>
        </Card>

        <Card className="mt-6">
          <CardHeader>
            <CardTitle>Módulos habilitados</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {modules.map((module) => (
              <label
                key={module.id}
                className={`flex items-center gap-4 p-3 rounded-lg border cursor-pointer transition-colors ${
                  selectedModules.includes(module.id)
                    ? 'bg-primary/10 border-primary/30'
                    : 'hover:bg-accent'
                } ${module.is_default ? 'cursor-not-allowed opacity-70' : ''}`}
              >
                <input
                  type="checkbox"
                  checked={selectedModules.includes(module.id)}
                  disabled={module.is_default}
                  onChange={() => toggleModule(module.id, module.is_default)}
                  className="rounded"
                />
                <div className="flex-1">
                  <p className="font-medium">{module.name}</p>
                  <p className="text-sm text-muted-foreground">{module.description}</p>
                </div>
                {module.is_default && (
                  <span className="text-xs bg-secondary px-2 py-1 rounded">
                    Obligatorio
                  </span>
                )}
              </label>
            ))}
          </CardContent>
        </Card>

        <div className="flex gap-3 mt-6">
          <Link href="/businesses" className="flex-1">
            <Button variant="outline" className="w-full">
              Cancelar
            </Button>
          </Link>
          <Button type="submit" className="flex-1" disabled={loading}>
            {loading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Creando...
              </>
            ) : (
              'Crear negocio'
            )}
          </Button>
        </div>
      </form>
    </div>
  )
}
