'use client'

import { LucideIcon } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { cn } from '@/lib/utils'

interface StatCardProps {
  icon: LucideIcon
  label: string
  value: number | string
  iconColor?: string
  valueColor?: string
  className?: string
}

export function StatCard({
  icon: Icon,
  label,
  value,
  iconColor = 'text-muted-foreground',
  valueColor,
  className,
}: StatCardProps) {
  return (
    <Card className={cn(className)}>
      <CardContent className="p-3 sm:p-4 text-center">
        <Icon className={cn('h-4 w-4 sm:h-5 sm:w-5 mx-auto mb-1 sm:mb-2', iconColor)} />
        <p className={cn('text-xl sm:text-2xl font-bold', valueColor)}>
          {typeof value === 'number' ? value.toLocaleString() : value}
        </p>
        <p className="text-xs sm:text-sm text-muted-foreground">{label}</p>
      </CardContent>
    </Card>
  )
}

interface StatsGridProps {
  children: React.ReactNode
  columns?: 2 | 3 | 4
  className?: string
}

export function StatsGrid({ children, columns = 2, className }: StatsGridProps) {
  const gridCols = {
    2: 'grid-cols-2',
    3: 'grid-cols-2 sm:grid-cols-3',
    4: 'grid-cols-2 sm:grid-cols-4',
  }

  return (
    <div className={cn('grid gap-3 sm:gap-4', gridCols[columns], className)}>
      {children}
    </div>
  )
}
