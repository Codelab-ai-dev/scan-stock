'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { useToast } from '@/components/ui/toast'
import { useConfirm } from '@/components/ui/confirm-modal'
import {
  ArrowLeft,
  Users,
  Package,
  ShoppingCart,
  Grid3X3,
  Loader2,
  Pencil,
  Trash2,
} from 'lucide-react'
import type { Business, BusinessStats } from '@/lib/types'

export default function BusinessDetailPage() {
  const params = useParams()
  const router = useRouter()
  const supabase = createClient()
  const toast = useToast()
  const { confirm } = useConfirm()
  const businessId = params.id as string

  const [business, setBusiness] = useState<Business | null>(null)
  const [stats, setStats] = useState<BusinessStats>({
    total_products: 0,
    total_sales: 0,
    total_users: 0,
    sales_today: 0,
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [toggling, setToggling] = useState(false)
  const [editMode, setEditMode] = useState(false)
  const [editName, setEditName] = useState('')
  const [editSlug, setEditSlug] = useState('')
  const [editLogo, setEditLogo] = useState('')

  useEffect(() => {
    async function loadBusiness() {
      const { data, error: fetchError } = await supabase
        .from('businesses')
        .select('*')
        .eq('id', businessId)
        .single()

      if (fetchError || !data) {
        setError('Negocio no encontrado')
        setLoading(false)
        return
      }

      setBusiness(data)
      setEditName(data.name)
      setEditSlug(data.slug)
      setEditLogo(data.logo_url ?? '')

      // Cargar estadísticas
      const [productsRes, salesRes, usersRes, todayRes] = await Promise.all([
        supabase.from('productos').select('*', { count: 'exact', head: true }).eq('business_id', businessId),
        supabase.from('ventas').select('*', { count: 'exact', head: true }).eq('business_id', businessId),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('business_id', businessId),
        supabase
          .from('ventas')
          .select('*', { count: 'exact', head: true })
          .eq('business_id', businessId)
          .gte('created_at', new Date().toISOString().split('T')[0]),
      ])

      setStats({
        total_products: productsRes.count ?? 0,
        total_sales: salesRes.count ?? 0,
        total_users: usersRes.count ?? 0,
        sales_today: todayRes.count ?? 0,
      })

      setLoading(false)
    }

    loadBusiness()
  }, [businessId])

  async function toggleActive() {
    if (!business) return
    setToggling(true)

    const { error: updateError } = await supabase
      .from('businesses')
      .update({ is_active: !business.is_active })
      .eq('id', business.id)

    if (updateError) {
      toast.error('Error al cambiar estado del negocio')
    } else {
      setBusiness({ ...business, is_active: !business.is_active })
      toast.success(business.is_active ? 'Negocio desactivado' : 'Negocio activado')
    }
    setToggling(false)
  }

  async function saveBusiness() {
    if (!business) return
    setSaving(true)

    const { error: updateError } = await supabase
      .from('businesses')
      .update({
        name: editName.trim(),
        slug: editSlug.trim(),
        logo_url: editLogo.trim() || null,
      })
      .eq('id', business.id)

    if (updateError) {
      toast.error(updateError.message)
    } else {
      setBusiness({
        ...business,
        name: editName.trim(),
        slug: editSlug.trim(),
        logo_url: editLogo.trim() || null,
      })
      setEditMode(false)
      toast.success('Negocio actualizado correctamente')
    }

    setSaving(false)
  }

  async function deleteBusiness() {
    if (!business) return

    const confirmed = await confirm({
      title: 'Eliminar negocio',
      message: `¿Estás seguro de eliminar "${business.name}"? Esta acción eliminará todos los productos, ventas y usuarios asociados. No se puede deshacer.`,
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      variant: 'danger',
    })

    if (!confirmed) return

    setDeleting(true)

    const { error: deleteError } = await supabase
      .from('businesses')
      .delete()
      .eq('id', business.id)

    if (deleteError) {
      toast.error(deleteError.message)
      setDeleting(false)
    } else {
      toast.success('Negocio eliminado correctamente')
      router.push('/businesses')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (!business && !loading) {
    return (
      <div className="text-center py-20">
        <p className="text-destructive mb-4">Negocio no encontrado</p>
        <Link href="/businesses">
          <Button>Volver a negocios</Button>
        </Link>
      </div>
    )
  }

  if (!business) return null

  return (
    <div className="space-y-4 sm:space-y-6">
      {/* Header */}
      <div className="space-y-4">
        <div className="flex items-start gap-3 sm:gap-4">
          <Link href="/businesses">
            <Button variant="ghost" size="icon" className="shrink-0 h-9 w-9 sm:h-10 sm:w-10">
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </Link>
          <div className="flex-1 min-w-0">
            <div className="flex flex-wrap items-center gap-2 sm:gap-3">
              <h1 className="text-xl sm:text-2xl font-bold truncate">{business.name}</h1>
              <Badge variant={business.is_active ? 'success' : 'destructive'} className="shrink-0">
                {business.is_active ? 'Activo' : 'Inactivo'}
              </Badge>
            </div>
            <p className="text-sm sm:text-base text-muted-foreground truncate">/{business.slug}</p>
          </div>
        </div>

        {/* Action buttons - debajo en móvil */}
        <div className="flex gap-2 pl-0 sm:pl-14">
          <Button variant="outline" size="sm" onClick={() => setEditMode(!editMode)} className="flex-1 sm:flex-none">
            <Pencil className="h-4 w-4 mr-2" />
            Editar
          </Button>
          <Button
            variant={business.is_active ? 'outline' : 'default'}
            size="sm"
            onClick={toggleActive}
            disabled={toggling}
            className="flex-1 sm:flex-none"
          >
            {toggling ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : business.is_active ? (
              'Desactivar'
            ) : (
              'Activar'
            )}
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-3 sm:gap-4">
        <Card>
          <CardContent className="p-3 sm:p-4 text-center">
            <Package className="h-4 w-4 sm:h-5 sm:w-5 mx-auto mb-1 sm:mb-2 text-muted-foreground" />
            <p className="text-xl sm:text-2xl font-bold">{stats.total_products}</p>
            <p className="text-xs sm:text-sm text-muted-foreground">Productos</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-3 sm:p-4 text-center">
            <ShoppingCart className="h-4 w-4 sm:h-5 sm:w-5 mx-auto mb-1 sm:mb-2 text-muted-foreground" />
            <p className="text-xl sm:text-2xl font-bold">{stats.total_sales}</p>
            <p className="text-xs sm:text-sm text-muted-foreground">Ventas</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-3 sm:p-4 text-center">
            <Users className="h-4 w-4 sm:h-5 sm:w-5 mx-auto mb-1 sm:mb-2 text-muted-foreground" />
            <p className="text-xl sm:text-2xl font-bold">{stats.total_users}</p>
            <p className="text-xs sm:text-sm text-muted-foreground">Usuarios</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-3 sm:p-4 text-center">
            <ShoppingCart className="h-4 w-4 sm:h-5 sm:w-5 mx-auto mb-1 sm:mb-2 text-green-500" />
            <p className="text-xl sm:text-2xl font-bold text-green-500">{stats.sales_today}</p>
            <p className="text-xs sm:text-sm text-muted-foreground">Ventas hoy</p>
          </CardContent>
        </Card>
      </div>

      {/* Edit Form */}
      {editMode && (
        <Card>
          <CardHeader className="p-4 sm:p-6">
            <CardTitle className="text-base sm:text-lg">Editar negocio</CardTitle>
          </CardHeader>
          <CardContent className="p-4 sm:p-6 pt-0 sm:pt-0 space-y-4">
            <div className="space-y-2">
              <label className="text-xs sm:text-sm font-medium">Nombre</label>
              <Input value={editName} onChange={(e) => setEditName(e.target.value)} />
            </div>
            <div className="space-y-2">
              <label className="text-xs sm:text-sm font-medium">Slug</label>
              <Input value={editSlug} onChange={(e) => setEditSlug(e.target.value)} />
            </div>
            <div className="space-y-2">
              <label className="text-xs sm:text-sm font-medium">URL del logo</label>
              <Input
                type="url"
                value={editLogo}
                onChange={(e) => setEditLogo(e.target.value)}
              />
            </div>
            <div className="flex flex-col sm:flex-row gap-2 sm:gap-3">
              <Button variant="outline" onClick={() => setEditMode(false)} className="order-2 sm:order-1">
                Cancelar
              </Button>
              <Button onClick={saveBusiness} disabled={saving} className="order-1 sm:order-2">
                {saving ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Guardando...
                  </>
                ) : (
                  'Guardar'
                )}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Quick Actions */}
      <div className="grid gap-3 sm:gap-4 sm:grid-cols-2">
        <Link href={`/businesses/${business.id}/modules`}>
          <Card className="hover:border-primary/50 transition-colors cursor-pointer">
            <CardContent className="p-3 sm:p-4">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-xl bg-primary/20 flex items-center justify-center shrink-0">
                  <Grid3X3 className="h-5 w-5 sm:h-6 sm:w-6 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-medium text-sm sm:text-base">Módulos</h3>
                  <p className="text-xs sm:text-sm text-muted-foreground truncate">
                    Gestionar módulos habilitados
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </Link>

        <Link href={`/businesses/${business.id}/users`}>
          <Card className="hover:border-primary/50 transition-colors cursor-pointer">
            <CardContent className="p-3 sm:p-4">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-xl bg-blue-500/20 flex items-center justify-center shrink-0">
                  <Users className="h-5 w-5 sm:h-6 sm:w-6 text-blue-500" />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-medium text-sm sm:text-base">Usuarios</h3>
                  <p className="text-xs sm:text-sm text-muted-foreground truncate">
                    Gestionar usuarios del negocio
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </Link>
      </div>

      {/* Danger Zone */}
      <Card className="border-destructive/50">
        <CardContent className="p-3 sm:p-4">
          <h3 className="font-medium text-sm sm:text-base text-destructive mb-2">Zona de peligro</h3>
          <p className="text-xs sm:text-sm text-muted-foreground mb-3 sm:mb-4">
            Eliminar este negocio eliminará todos sus productos, ventas y usuarios asociados.
          </p>
          <Button variant="destructive" size="sm" onClick={deleteBusiness} disabled={deleting} className="w-full sm:w-auto">
            {deleting ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Eliminando...
              </>
            ) : (
              <>
                <Trash2 className="mr-2 h-4 w-4" />
                Eliminar negocio
              </>
            )}
          </Button>
        </CardContent>
      </Card>
    </div>
  )
}
