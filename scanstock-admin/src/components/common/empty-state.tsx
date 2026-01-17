'use client'

import { ReactNode } from 'react'
import { LucideIcon } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { cn } from '@/lib/utils'

interface EmptyStateProps {
  icon: LucideIcon
  title: string
  description?: string
  action?: ReactNode
  className?: string
}

export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
  className,
}: EmptyStateProps) {
  return (
    <Card className={cn(className)}>
      <CardContent className="flex flex-col items-center justify-center py-12 sm:py-16 px-4">
        <div className="w-16 h-16 rounded-xl bg-muted flex items-center justify-center mb-4">
          <Icon className="h-8 w-8 text-muted-foreground" />
        </div>
        <p className="text-sm sm:text-base font-medium text-center mb-1">{title}</p>
        {description && (
          <p className="text-sm text-muted-foreground text-center mb-4">{description}</p>
        )}
        {action}
      </CardContent>
    </Card>
  )
}
