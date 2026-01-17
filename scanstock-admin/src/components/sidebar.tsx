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
  Menu,
  X,
} from 'lucide-react'
import { useState, useEffect } from 'react'

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

interface SidebarProps {
  isOpen?: boolean
  onClose?: () => void
}

export function Sidebar({ isOpen, onClose }: SidebarProps) {
  const pathname = usePathname()
  const router = useRouter()
  const supabase = createClient()

  async function handleSignOut() {
    await supabase.auth.signOut()
    router.push('/')
  }

  // Cerrar sidebar al navegar en móvil
  const handleNavClick = () => {
    if (onClose) {
      onClose()
    }
  }

  return (
    <>
      {/* Overlay para móvil */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/60 z-40 lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-50 w-72 bg-card border-r border-border flex flex-col transition-transform duration-300 ease-in-out',
          'lg:translate-x-0',
          isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        )}
      >
        {/* Botón cerrar en móvil */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-2 rounded-lg bg-muted hover:bg-accent lg:hidden"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Scanner effect line at top */}
        <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-primary/50 to-transparent" />

        {/* Logo Section */}
        <div className="p-4 sm:p-6 border-b border-border">
          <Link
            href="/dashboard"
            className="flex items-center gap-3 group"
            onClick={handleNavClick}
          >
            <div className="relative">
              <Image
                src="/logo.png"
                alt="ScanStock"
                width={56}
                height={56}
                className="w-12 h-12 sm:w-[72px] sm:h-[72px] object-contain"
              />
              {/* Pulse indicator */}
              <div className="absolute -top-0.5 -right-0.5 w-2 h-2 sm:w-2.5 sm:h-2.5 rounded-full bg-primary animate-pulse" />
            </div>
            <div>
              <h1 className="font-bold text-lg sm:text-xl tracking-tight">ScanStock</h1>
              <p className="text-[9px] sm:text-[10px] text-muted-foreground font-mono tracking-widest">
                ADMIN CONSOLE
              </p>
            </div>
          </Link>
        </div>

        {/* Status Bar */}
        <div className="px-3 sm:px-4 py-2 sm:py-3 mx-3 sm:mx-4 mt-3 sm:mt-4 rounded-lg bg-background/50 border border-border">
          <div className="flex items-center gap-2">
            <Activity className="w-3 h-3 sm:w-3.5 sm:h-3.5 text-primary" />
            <span className="text-[10px] sm:text-xs font-medium">Sistema</span>
            <span className="ml-auto flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse" />
              <span className="text-[9px] sm:text-[10px] text-primary font-mono">ONLINE</span>
            </span>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-3 sm:p-4 space-y-1 overflow-y-auto">
          <p className="px-3 mb-2 sm:mb-3 text-[9px] sm:text-[10px] font-semibold text-muted-foreground uppercase tracking-widest">
            Navegación
          </p>
          {navigation.map((item) => {
            const isActive =
              pathname === item.href || pathname.startsWith(item.href + '/')
            return (
              <Link
                key={item.name}
                href={item.href}
                onClick={handleNavClick}
                className={cn(
                  'group flex items-center gap-2 sm:gap-3 px-3 py-2 sm:py-2.5 rounded-lg text-sm transition-all duration-200 relative overflow-hidden',
                  isActive
                    ? 'bg-primary/10 text-primary border border-primary/20'
                    : 'text-muted-foreground hover:text-foreground hover:bg-accent'
                )}
              >
                {/* Active indicator line */}
                {isActive && (
                  <div className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-6 sm:h-8 bg-primary rounded-r-full" />
                )}

                <div
                  className={cn(
                    'w-8 h-8 sm:w-9 sm:h-9 rounded-lg flex items-center justify-center transition-colors shrink-0',
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

                <div className="flex-1 min-w-0">
                  <span className={cn('font-medium text-sm', isActive && 'text-primary')}>
                    {item.name}
                  </span>
                  <p className="text-[9px] sm:text-[10px] text-muted-foreground truncate">
                    {item.description}
                  </p>
                </div>

                <ChevronRight
                  className={cn(
                    'h-4 w-4 transition-all shrink-0 hidden sm:block',
                    isActive
                      ? 'text-primary opacity-100'
                      : 'opacity-0 -translate-x-2 group-hover:opacity-50 group-hover:translate-x-0'
                  )}
                />
              </Link>
            )
          })}
        </nav>

        {/* Decorative element - oculto en móvil pequeño */}
        <div className="hidden sm:block mx-4 mb-4 p-4 rounded-lg bg-gradient-to-br from-primary/5 to-secondary/5 border border-border relative overflow-hidden">
          <div className="absolute inset-0 bg-barcode opacity-30" />
          <div className="relative">
            <p className="text-xs font-medium mb-1">Terminal Activa</p>
            <p className="text-[10px] text-muted-foreground font-mono">
              ID: ADMIN-001
            </p>
          </div>
        </div>

        {/* Sign out */}
        <div className="p-3 sm:p-4 border-t border-border">
          <Button
            variant="ghost"
            className="w-full justify-start gap-2 sm:gap-3 text-muted-foreground hover:text-destructive hover:bg-destructive/10 transition-colors"
            onClick={handleSignOut}
          >
            <div className="w-8 h-8 sm:w-9 sm:h-9 rounded-lg bg-muted flex items-center justify-center">
              <LogOut className="h-4 w-4" />
            </div>
            <span className="font-medium text-sm">Cerrar sesión</span>
          </Button>
        </div>

        {/* Bottom line effect */}
        <div className="absolute bottom-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-primary/30 to-transparent" />
      </aside>
    </>
  )
}

// Componente para el header móvil
export function MobileHeader({ onMenuClick }: { onMenuClick: () => void }) {
  return (
    <header className="sticky top-0 z-30 bg-card/95 backdrop-blur border-b border-border lg:hidden">
      <div className="flex items-center justify-between px-4 py-3">
        <button
          onClick={onMenuClick}
          className="p-2 -ml-2 rounded-lg hover:bg-accent transition-colors"
        >
          <Menu className="w-6 h-6" />
        </button>

        <Link href="/dashboard" className="flex items-center gap-2">
          <Image
            src="/logo.png"
            alt="ScanStock"
            width={32}
            height={32}
            className="w-8 h-8 object-contain"
          />
          <span className="font-bold text-lg">ScanStock</span>
        </Link>

        <div className="w-10" /> {/* Spacer para centrar el logo */}
      </div>
    </header>
  )
}
