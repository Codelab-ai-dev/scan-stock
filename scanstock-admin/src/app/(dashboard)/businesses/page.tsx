'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Building2, Plus, Search } from 'lucide-react'
import type { Business } from '@/lib/types'

export default function BusinessesPage() {
  const supabase = createClient()
  const [businesses, setBusinesses] = useState<Business[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')

  useEffect(() => {
    async function loadBusinesses() {
      const { data } = await supabase
        .from('businesses')
        .select('*')
        .order('created_at', { ascending: false })

      setBusinesses(data ?? [])
      setLoading(false)
    }

    loadBusinesses()
  }, [])

  const filteredBusinesses = businesses.filter(
    (b) =>
      b.name.toLowerCase().includes(search.toLowerCase()) ||
      b.slug.toLowerCase().includes(search.toLowerCase())
  )

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold">Negocios</h1>
          <p className="text-sm sm:text-base text-muted-foreground">
            Gestiona los negocios de la plataforma
          </p>
        </div>
        <Link href="/businesses/new" className="self-start sm:self-auto">
          <Button size="sm" className="sm:size-default">
            <Plus className="h-4 w-4 mr-2" />
            Nuevo negocio
          </Button>
        </Link>
      </div>

      {/* Search */}
      <div className="relative w-full sm:max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Buscar negocios..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="pl-10"
        />
      </div>

      {/* Businesses Grid */}
      {filteredBusinesses.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-12 sm:py-16 px-4">
            <Building2 className="h-10 w-10 sm:h-12 sm:w-12 text-muted-foreground mb-4" />
            <p className="text-sm sm:text-base text-muted-foreground mb-4 text-center">
              {search ? 'No se encontraron negocios' : 'No hay negocios registrados'}
            </p>
            {!search && (
              <Link href="/businesses/new">
                <Button size="sm" className="sm:size-default">
                  <Plus className="h-4 w-4 mr-2" />
                  Crear primer negocio
                </Button>
              </Link>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-3 sm:gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filteredBusinesses.map((business) => (
            <Link key={business.id} href={`/businesses/${business.id}`}>
              <Card className="hover:border-primary/50 transition-colors cursor-pointer h-full">
                <CardContent className="p-4 sm:p-6">
                  <div className="flex items-start gap-3 sm:gap-4">
                    <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-lg bg-primary/20 flex items-center justify-center shrink-0">
                      {business.logo_url ? (
                        <img
                          src={business.logo_url}
                          alt={business.name}
                          className="w-6 h-6 sm:w-8 sm:h-8 rounded object-cover"
                        />
                      ) : (
                        <Building2 className="h-5 w-5 sm:h-6 sm:w-6 text-primary" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex flex-wrap items-center gap-1 sm:gap-2 mb-1">
                        <h3 className="font-semibold text-sm sm:text-base truncate">{business.name}</h3>
                        <Badge
                          variant={business.is_active ? 'success' : 'destructive'}
                          className="shrink-0 text-[10px] sm:text-xs"
                        >
                          {business.is_active ? 'Activo' : 'Inactivo'}
                        </Badge>
                      </div>
                      <p className="text-xs sm:text-sm text-muted-foreground truncate">/{business.slug}</p>
                      <p className="text-[10px] sm:text-xs text-muted-foreground mt-1 sm:mt-2">
                        {new Date(business.created_at).toLocaleDateString('es-ES')}
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}
