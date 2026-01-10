'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Switch } from '@/components/ui/switch'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ArrowLeft, Package, ShoppingCart, Users, BarChart3, Info } from 'lucide-react'
import type { Business, Module } from '@/lib/types'

const iconMap: Record<string, React.ElementType> = {
  inventory_2: Package,
  point_of_sale: ShoppingCart,
  people: Users,
  analytics: BarChart3,
}

export default function ModulesPage() {
  const params = useParams()
  const supabase = createClient()
  const businessId = params.id as string

  const [business, setBusiness] = useState<Business | null>(null)
  const [modules, setModules] = useState<Module[]>([])
  const [enabledModules, setEnabledModules] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [togglingModule, setTogglingModule] = useState<string | null>(null)

  useEffect(() => {
    async function loadData() {
      // Cargar negocio
      const { data: businessData } = await supabase
        .from('businesses')
        .select('*')
        .eq('id', businessId)
        .single()

      setBusiness(businessData)

      // Cargar todos los módulos
      const { data: modulesData } = await supabase
        .from('modules')
        .select('*')
        .order('name')

      setModules(modulesData ?? [])

      // Cargar módulos habilitados para este negocio
      const { data: enabledData } = await supabase
        .from('business_modules')
        .select('module_id')
        .eq('business_id', businessId)

      setEnabledModules(enabledData?.map((m) => m.module_id) ?? [])
      setLoading(false)
    }

    loadData()
  }, [businessId])

  async function handleToggle(moduleId: string, enable: boolean) {
    setTogglingModule(moduleId)

    if (enable) {
      await supabase.from('business_modules').insert({
        business_id: businessId,
        module_id: moduleId,
      })
      setEnabledModules([...enabledModules, moduleId])
    } else {
      await supabase
        .from('business_modules')
        .delete()
        .eq('business_id', businessId)
        .eq('module_id', moduleId)
      setEnabledModules(enabledModules.filter((m) => m !== moduleId))
    }

    setTogglingModule(null)
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
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href={`/businesses/${businessId}`}>
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold">Módulos</h1>
          <p className="text-muted-foreground">{business?.name ?? 'Cargando...'}</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base font-normal text-muted-foreground">
            Selecciona los módulos que deseas habilitar para este negocio. Los
            módulos marcados como obligatorios no pueden desactivarse.
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {modules.map((module) => {
            const Icon = iconMap[module.icon ?? 'inventory_2'] ?? Package
            const enabled = enabledModules.includes(module.id)
            const isToggling = togglingModule === module.id

            return (
              <div
                key={module.id}
                className={`flex items-center justify-between p-4 rounded-xl border transition-colors ${
                  enabled ? 'border-primary/30 bg-primary/5' : ''
                }`}
              >
                <div className="flex items-center gap-4">
                  <div
                    className={`w-12 h-12 rounded-lg flex items-center justify-center transition-colors ${
                      enabled ? 'bg-primary/20' : 'bg-muted'
                    }`}
                  >
                    <Icon
                      className={`h-6 w-6 transition-colors ${
                        enabled ? 'text-primary' : 'text-muted-foreground'
                      }`}
                    />
                  </div>
                  <div>
                    <h4 className="font-medium">{module.name}</h4>
                    <p className="text-sm text-muted-foreground">
                      {module.description}
                    </p>
                    {module.is_default && (
                      <p className="text-xs text-muted-foreground mt-1">
                        Este módulo es obligatorio
                      </p>
                    )}
                  </div>
                </div>

                <Switch
                  checked={enabled}
                  onCheckedChange={(checked) => handleToggle(module.id, checked)}
                  disabled={isToggling || module.is_default}
                />
              </div>
            )
          })}
        </CardContent>
      </Card>

      <Alert>
        <Info className="h-4 w-4" />
        <AlertDescription>
          Los cambios en los módulos se reflejan inmediatamente en la aplicación
          móvil de los usuarios.
        </AlertDescription>
      </Alert>
    </div>
  )
}
