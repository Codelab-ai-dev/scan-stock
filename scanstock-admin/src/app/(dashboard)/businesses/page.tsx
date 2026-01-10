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
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Negocios</h1>
          <p className="text-muted-foreground">
            Gestiona los negocios de la plataforma
          </p>
        </div>
        <Link href="/businesses/new">
          <Button>
            <Plus className="h-4 w-4 mr-2" />
            Nuevo negocio
          </Button>
        </Link>
      </div>

      {/* Search */}
      <div className="relative max-w-md">
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
          <CardContent className="flex flex-col items-center justify-center py-16">
            <Building2 className="h-12 w-12 text-muted-foreground mb-4" />
            <p className="text-muted-foreground mb-4">
              {search ? 'No se encontraron negocios' : 'No hay negocios registrados'}
            </p>
            {!search && (
              <Link href="/businesses/new">
                <Button>
                  <Plus className="h-4 w-4 mr-2" />
                  Crear primer negocio
                </Button>
              </Link>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {filteredBusinesses.map((business) => (
            <Link key={business.id} href={`/businesses/${business.id}`}>
              <Card className="hover:border-primary/50 transition-colors cursor-pointer h-full">
                <CardContent className="p-6">
                  <div className="flex items-start gap-4">
                    <div className="w-12 h-12 rounded-lg bg-primary/20 flex items-center justify-center shrink-0">
                      {business.logo_url ? (
                        <img
                          src={business.logo_url}
                          alt={business.name}
                          className="w-8 h-8 rounded object-cover"
                        />
                      ) : (
                        <Building2 className="h-6 w-6 text-primary" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold truncate">{business.name}</h3>
                        <Badge
                          variant={business.is_active ? 'success' : 'destructive'}
                          className="shrink-0"
                        >
                          {business.is_active ? 'Activo' : 'Inactivo'}
                        </Badge>
                      </div>
                      <p className="text-sm text-muted-foreground">/{business.slug}</p>
                      <p className="text-xs text-muted-foreground mt-2">
                        Creado: {new Date(business.created_at).toLocaleDateString('es-ES')}
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
