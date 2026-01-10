import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const badgeVariants = cva(
  'inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium transition-colors',
  {
    variants: {
      variant: {
        default:
          'bg-primary/20 text-primary border border-primary/30',
        secondary:
          'bg-secondary/20 text-secondary border border-secondary/30',
        destructive:
          'bg-destructive/20 text-destructive border border-destructive/30',
        outline:
          'border border-border text-muted-foreground',
        success:
          'bg-emerald-500/20 text-emerald-500 border border-emerald-500/30',
        warning:
          'bg-amber-500/20 text-amber-500 border border-amber-500/30',
      },
    },
    defaultVariants: {
      variant: 'default',
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {
  dot?: boolean
}

function Badge({ className, variant, dot, children, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props}>
      {dot && (
        <span
          className={cn(
            'w-1.5 h-1.5 rounded-full',
            variant === 'success' && 'bg-emerald-500',
            variant === 'destructive' && 'bg-destructive',
            variant === 'warning' && 'bg-amber-500',
            variant === 'default' && 'bg-primary',
            variant === 'secondary' && 'bg-secondary',
            !variant && 'bg-primary'
          )}
        />
      )}
      {children}
    </div>
  )
}

export { Badge, badgeVariants }
