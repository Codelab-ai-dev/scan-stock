'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { cn } from '@/lib/utils'
import {
  Building2,
  Users,
  Package,
  ShoppingCart,
  ArrowRight,
  TrendingUp,
  Activity,
  Zap,
} from 'lucide-react'
import type { Business } from '@/lib/types'

interface DashboardStats {
  totalBusinesses: number
  activeBusinesses: number
  totalUsers: number
  totalProducts: number
}

export default function DashboardPage() {
  const supabase = createClient()
  const [stats, setStats] = useState<DashboardStats>({
    totalBusinesses: 0,
    activeBusinesses: 0,
    totalUsers: 0,
    totalProducts: 0,
  })
  const [recentBusinesses, setRecentBusinesses] = useState<Business[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function loadData() {
      const [businessesRes, activeRes, usersRes, productsRes] = await Promise.all([
        supabase.from('businesses').select('*', { count: 'exact', head: true }),
        supabase.from('businesses').select('*', { count: 'exact', head: true }).eq('is_active', true),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('is_super_admin', false),
        supabase.from('productos').select('*', { count: 'exact', head: true }),
      ])

      setStats({
        totalBusinesses: businessesRes.count ?? 0,
        activeBusinesses: activeRes.count ?? 0,
        totalUsers: usersRes.count ?? 0,
        totalProducts: productsRes.count ?? 0,
      })

      const { data: businesses } = await supabase
        .from('businesses')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(5)

      setRecentBusinesses(businesses ?? [])
      setLoading(false)
    }

    loadData()
  }, [])

  const statCards = [
    {
      title: 'Total Negocios',
      value: stats.totalBusinesses,
      icon: Building2,
      trend: '+12%',
      trendUp: true,
      gradient: 'from-primary/20 to-primary/5',
      iconBg: 'bg-primary/20',
      iconColor: 'text-primary',
      borderColor: 'border-primary/20',
    },
    {
      title: 'Activos',
      value: stats.activeBusinesses,
      icon: Zap,
      trend: '+8%',
      trendUp: true,
      gradient: 'from-emerald-500/20 to-emerald-500/5',
      iconBg: 'bg-emerald-500/20',
      iconColor: 'text-emerald-500',
      borderColor: 'border-emerald-500/20',
    },
    {
      title: 'Usuarios',
      value: stats.totalUsers,
      icon: Users,
      trend: '+24%',
      trendUp: true,
      gradient: 'from-amber-500/20 to-amber-500/5',
      iconBg: 'bg-amber-500/20',
      iconColor: 'text-amber-500',
      borderColor: 'border-amber-500/20',
    },
    {
      title: 'Productos',
      value: stats.totalProducts,
      icon: Package,
      trend: '+18%',
      trendUp: true,
      gradient: 'from-violet-500/20 to-violet-500/5',
      iconBg: 'bg-violet-500/20',
      iconColor: 'text-violet-500',
      borderColor: 'border-violet-500/20',
    },
  ]

  if (loading) {
    return (
      <div className="flex items-center justify-center h-[60vh]">
        <div className="text-center space-y-4">
          <div className="w-12 h-12 rounded-xl bg-primary/20 border border-primary/30 flex items-center justify-center mx-auto animate-pulse">
            <Activity className="w-6 h-6 text-primary" />
          </div>
          <p className="text-sm text-muted-foreground font-mono">Cargando datos...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6 sm:space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 sm:gap-3 mb-2">
            <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
            <span className="text-[10px] sm:text-xs font-mono text-muted-foreground uppercase tracking-widest">
              Panel de Control
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-sm sm:text-base text-muted-foreground mt-1">
            Resumen general de la plataforma
          </p>
        </div>

        <div className="flex items-center gap-2 px-3 sm:px-4 py-2 rounded-lg bg-card border border-border self-start">
          <span className="w-2 h-2 rounded-full bg-primary animate-pulse" />
          <span className="text-[10px] sm:text-xs font-mono text-muted-foreground">
            {new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })}
          </span>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
        {statCards.map((stat, index) => (
          <div
            key={stat.title}
            className={cn(
              'group relative overflow-hidden rounded-xl border bg-card p-4 sm:p-6 transition-all duration-300 hover:border-primary/30 hover:-translate-y-1',
              stat.borderColor,
              'opacity-0 animate-fade-up'
            )}
            style={{ animationDelay: `${index * 100}ms`, animationFillMode: 'forwards' }}
          >
            {/* Gradient background */}
            <div className={cn('absolute inset-0 bg-gradient-to-br opacity-50', stat.gradient)} />

            {/* Corner accent */}
            <div className="absolute top-0 right-0 w-16 h-16 opacity-0 group-hover:opacity-100 transition-opacity hidden sm:block">
              <div className={cn('absolute top-2 right-2 w-8 h-[1px]', stat.iconBg.replace('/20', ''))} />
              <div className={cn('absolute top-2 right-2 w-[1px] h-8', stat.iconBg.replace('/20', ''))} />
            </div>

            <div className="relative">
              <div className="flex items-start justify-between mb-3 sm:mb-4">
                <div className={cn('w-10 h-10 sm:w-12 sm:h-12 rounded-xl flex items-center justify-center', stat.iconBg)}>
                  <stat.icon className={cn('h-5 w-5 sm:h-6 sm:w-6', stat.iconColor)} />
                </div>
                <div className="flex items-center gap-1 text-[10px] sm:text-xs">
                  <TrendingUp className="w-3 h-3 text-emerald-500" />
                  <span className="text-emerald-500 font-mono">{stat.trend}</span>
                </div>
              </div>

              <div>
                <p className="text-xs sm:text-sm text-muted-foreground mb-1">{stat.title}</p>
                <p className="text-2xl sm:text-3xl font-bold font-mono tracking-tight">{stat.value.toLocaleString()}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Businesses */}
      <div className="rounded-xl border border-border bg-card overflow-hidden">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 sm:p-6 border-b border-border gap-3">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 sm:w-10 sm:h-10 rounded-lg bg-primary/20 flex items-center justify-center shrink-0">
              <Building2 className="w-4 h-4 sm:w-5 sm:h-5 text-primary" />
            </div>
            <div>
              <h2 className="font-semibold text-sm sm:text-base">Últimos Negocios</h2>
              <p className="text-[10px] sm:text-xs text-muted-foreground">Registrados recientemente</p>
            </div>
          </div>
          <Link
            href="/businesses"
            className="flex items-center gap-2 text-sm text-primary hover:underline group self-end sm:self-auto"
          >
            Ver todos
            <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
          </Link>
        </div>

        {/* Content */}
        <div className="p-4 sm:p-6">
          {recentBusinesses.length === 0 ? (
            <div className="text-center py-12">
              <div className="w-16 h-16 rounded-xl bg-muted flex items-center justify-center mx-auto mb-4">
                <Building2 className="h-8 w-8 text-muted-foreground" />
              </div>
              <p className="text-muted-foreground mb-4">No hay negocios registrados</p>
              <Link
                href="/businesses/new"
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90 transition-colors"
              >
                Crear primer negocio
                <ArrowRight className="h-4 w-4" />
              </Link>
            </div>
          ) : (
            <div className="space-y-2 sm:space-y-3">
              {recentBusinesses.map((business, index) => (
                <Link
                  key={business.id}
                  href={`/businesses/${business.id}`}
                  className={cn(
                    'group flex items-center gap-3 sm:gap-4 p-3 sm:p-4 rounded-xl border border-transparent bg-background/50 hover:border-primary/20 hover:bg-primary/5 transition-all duration-200',
                    'opacity-0 animate-fade-up'
                  )}
                  style={{ animationDelay: `${(index + 4) * 100}ms`, animationFillMode: 'forwards' }}
                >
                  <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-xl bg-muted flex items-center justify-center group-hover:bg-primary/20 transition-colors shrink-0">
                    {business.logo_url ? (
                      <img
                        src={business.logo_url}
                        alt={business.name}
                        className="w-6 h-6 sm:w-8 sm:h-8 rounded-lg object-cover"
                      />
                    ) : (
                      <Building2 className="h-4 w-4 sm:h-5 sm:w-5 text-muted-foreground group-hover:text-primary transition-colors" />
                    )}
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex flex-wrap items-center gap-1 sm:gap-2">
                      <p className="font-medium text-sm sm:text-base truncate group-hover:text-primary transition-colors">
                        {business.name}
                      </p>
                      <span
                        className={cn(
                          'inline-flex items-center gap-1 px-1.5 sm:px-2 py-0.5 rounded-full text-[9px] sm:text-[10px] font-medium',
                          business.is_active
                            ? 'bg-emerald-500/20 text-emerald-500'
                            : 'bg-red-500/20 text-red-500'
                        )}
                      >
                        <span className={cn(
                          'w-1 h-1 rounded-full',
                          business.is_active ? 'bg-emerald-500' : 'bg-red-500'
                        )} />
                        {business.is_active ? 'Activo' : 'Inactivo'}
                      </span>
                    </div>
                    <p className="text-xs sm:text-sm text-muted-foreground font-mono truncate">/{business.slug}</p>
                  </div>

                  <div className="text-right hidden sm:block">
                    <p className="text-xs text-muted-foreground">
                      {new Date(business.created_at).toLocaleDateString('es-ES', {
                        day: '2-digit',
                        month: 'short',
                      })}
                    </p>
                  </div>

                  <ArrowRight className="h-4 w-4 text-muted-foreground shrink-0 sm:opacity-0 sm:-translate-x-2 sm:group-hover:opacity-100 sm:group-hover:translate-x-0 transition-all" />
                </Link>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
