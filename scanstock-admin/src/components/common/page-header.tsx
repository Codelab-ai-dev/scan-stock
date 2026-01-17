'use client'

import { ReactNode } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { ArrowLeft } from 'lucide-react'

interface PageHeaderProps {
  title: string
  description?: string
  backHref?: string
  actions?: ReactNode
  children?: ReactNode
}

export function PageHeader({
  title,
  description,
  backHref,
  actions,
  children,
}: PageHeaderProps) {
  return (
    <div className="space-y-4">
      <div className="flex items-start gap-3 sm:gap-4">
        {backHref && (
          <Link href={backHref}>
            <Button variant="ghost" size="icon" className="shrink-0 h-9 w-9 sm:h-10 sm:w-10">
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </Link>
        )}
        <div className="flex-1 min-w-0">
          <h1 className="text-xl sm:text-2xl font-bold truncate">{title}</h1>
          {description && (
            <p className="text-sm sm:text-base text-muted-foreground truncate">
              {description}
            </p>
          )}
          {children}
        </div>
        {actions && (
          <div className="shrink-0 hidden sm:block">{actions}</div>
        )}
      </div>
      {actions && (
        <div className="flex gap-2 sm:hidden">{actions}</div>
      )}
    </div>
  )
}
