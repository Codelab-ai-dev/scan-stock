'use client'

import Link from 'next/link'
import Image from 'next/image'
import { usePathname, useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import {
  LayoutDashboard,
  Building2,
  Settings,
  LogOut,
  ChevronRight,
  Activity,
  Smartphone,
} from 'lucide-react'

const navigation = [
  {
    name: 'Dashboard',
    href: '/dashboard',
    icon: LayoutDashboard,
    description: 'Vista general',
  },
  {
    name: 'Negocios',
    href: '/businesses',
    icon: Building2,
    description: 'Gestionar negocios',
  },
  {
    name: 'Aplicación',
    href: '/app-settings',
    icon: Smartphone,
    description: 'Gestionar APK',
  },
  {
    name: 'Configuración',
    href: '/settings',
    icon: Settings,
    description: 'Preferencias',
  },
]

export function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()
  const supabase = createClient()

  async function handleSignOut() {
    await supabase.auth.signOut()
    router.push('/')
  }

  return (
    <aside className="fixed inset-y-0 left-0 z-50 w-72 bg-card border-r border-border flex flex-col">
      {/* Scanner effect line at top */}
      <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-primary/50 to-transparent" />

      {/* Logo Section */}
      <div className="p-6 border-b border-border">
        <Link href="/dashboard" className="flex items-center gap-3 group">
          <div className="relative">
            <Image
              src="/logo.png"
              alt="ScanStock"
              width={72}
              height={72}
              className="w-[72px] h-[72px] object-contain"
            />
            {/* Pulse indicator */}
            <div className="absolute -top-0.5 -right-0.5 w-2.5 h-2.5 rounded-full bg-primary animate-pulse" />
          </div>
          <div>
            <h1 className="font-bold text-xl tracking-tight">ScanStock</h1>
            <p className="text-[10px] text-muted-foreground font-mono tracking-widest">
              ADMIN CONSOLE
            </p>
          </div>
        </Link>
      </div>

      {/* Status Bar */}
      <div className="px-4 py-3 mx-4 mt-4 rounded-lg bg-background/50 border border-border">
        <div className="flex items-center gap-2">
          <Activity className="w-3.5 h-3.5 text-primary" />
          <span className="text-xs font-medium">Sistema Operativo</span>
          <span className="ml-auto flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse" />
            <span className="text-[10px] text-primary font-mono">ONLINE</span>
          </span>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4 space-y-1">
        <p className="px-3 mb-3 text-[10px] font-semibold text-muted-foreground uppercase tracking-widest">
          Navegación
        </p>
        {navigation.map((item) => {
          const isActive =
            pathname === item.href || pathname.startsWith(item.href + '/')
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                'group flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-all duration-200 relative overflow-hidden',
                isActive
                  ? 'bg-primary/10 text-primary border border-primary/20'
                  : 'text-muted-foreground hover:text-foreground hover:bg-accent'
              )}
            >
              {/* Active indicator line */}
              {isActive && (
                <div className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-8 bg-primary rounded-r-full" />
              )}

              <div
                className={cn(
                  'w-9 h-9 rounded-lg flex items-center justify-center transition-colors',
                  isActive
                    ? 'bg-primary/20'
                    : 'bg-muted group-hover:bg-accent'
                )}
              >
                <item.icon
                  className={cn(
                    'h-4 w-4 transition-colors',
                    isActive ? 'text-primary' : 'text-muted-foreground group-hover:text-foreground'
                  )}
                />
              </div>

              <div className="flex-1">
                <span className={cn('font-medium', isActive && 'text-primary')}>
                  {item.name}
                </span>
                <p className="text-[10px] text-muted-foreground">
                  {item.description}
                </p>
              </div>

              <ChevronRight
                className={cn(
                  'h-4 w-4 transition-all',
                  isActive
                    ? 'text-primary opacity-100'
                    : 'opacity-0 -translate-x-2 group-hover:opacity-50 group-hover:translate-x-0'
                )}
              />
            </Link>
          )
        })}
      </nav>

      {/* Decorative element */}
      <div className="mx-4 mb-4 p-4 rounded-lg bg-gradient-to-br from-primary/5 to-secondary/5 border border-border relative overflow-hidden">
        <div className="absolute inset-0 bg-barcode opacity-30" />
        <div className="relative">
          <p className="text-xs font-medium mb-1">Terminal Activa</p>
          <p className="text-[10px] text-muted-foreground font-mono">
            ID: ADMIN-001
          </p>
        </div>
      </div>

      {/* Sign out */}
      <div className="p-4 border-t border-border">
        <Button
          variant="ghost"
          className="w-full justify-start gap-3 text-muted-foreground hover:text-destructive hover:bg-destructive/10 transition-colors"
          onClick={handleSignOut}
        >
          <div className="w-9 h-9 rounded-lg bg-muted flex items-center justify-center">
            <LogOut className="h-4 w-4" />
          </div>
          <span className="font-medium">Cerrar sesión</span>
        </Button>
      </div>

      {/* Bottom line effect */}
      <div className="absolute bottom-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-primary/30 to-transparent" />
    </aside>
  )
}
