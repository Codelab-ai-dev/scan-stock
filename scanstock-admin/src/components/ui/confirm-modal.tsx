'use client'

import { createContext, useContext, useState, useCallback, ReactNode } from 'react'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { AlertTriangle, Trash2, AlertCircle } from 'lucide-react'
import { cn } from '@/lib/utils'

type ConfirmVariant = 'danger' | 'warning' | 'default'

interface ConfirmOptions {
  title: string
  message: string
  confirmText?: string
  cancelText?: string
  variant?: ConfirmVariant
}

interface ConfirmContextType {
  confirm: (options: ConfirmOptions) => Promise<boolean>
}

const ConfirmContext = createContext<ConfirmContextType | null>(null)

export function useConfirm() {
  const context = useContext(ConfirmContext)
  if (!context) {
    throw new Error('useConfirm must be used within a ConfirmProvider')
  }
  return context
}

const variantStyles: Record<ConfirmVariant, { icon: typeof AlertTriangle; iconBg: string; iconColor: string; buttonVariant: 'destructive' | 'default' }> = {
  danger: {
    icon: Trash2,
    iconBg: 'bg-destructive/20',
    iconColor: 'text-destructive',
    buttonVariant: 'destructive',
  },
  warning: {
    icon: AlertTriangle,
    iconBg: 'bg-amber-500/20',
    iconColor: 'text-amber-500',
    buttonVariant: 'default',
  },
  default: {
    icon: AlertCircle,
    iconBg: 'bg-primary/20',
    iconColor: 'text-primary',
    buttonVariant: 'default',
  },
}

export function ConfirmProvider({ children }: { children: ReactNode }) {
  const [isOpen, setIsOpen] = useState(false)
  const [options, setOptions] = useState<ConfirmOptions | null>(null)
  const [resolveRef, setResolveRef] = useState<((value: boolean) => void) | null>(null)

  const confirm = useCallback((opts: ConfirmOptions): Promise<boolean> => {
    setOptions(opts)
    setIsOpen(true)

    return new Promise((resolve) => {
      setResolveRef(() => resolve)
    })
  }, [])

  const handleConfirm = () => {
    setIsOpen(false)
    resolveRef?.(true)
  }

  const handleCancel = () => {
    setIsOpen(false)
    resolveRef?.(false)
  }

  const variant = options?.variant || 'default'
  const style = variantStyles[variant]
  const Icon = style.icon

  return (
    <ConfirmContext.Provider value={{ confirm }}>
      {children}

      <Dialog open={isOpen} onOpenChange={(open) => !open && handleCancel()}>
        <DialogContent onClose={handleCancel} className="max-w-md">
          <DialogHeader>
            <div className="flex items-start gap-4">
              <div className={cn('w-12 h-12 rounded-xl flex items-center justify-center shrink-0', style.iconBg)}>
                <Icon className={cn('h-6 w-6', style.iconColor)} />
              </div>
              <div className="flex-1 pt-1">
                <DialogTitle className="text-lg">{options?.title}</DialogTitle>
                <p className="text-sm text-muted-foreground mt-2">{options?.message}</p>
              </div>
            </div>
          </DialogHeader>

          <DialogFooter className="mt-6">
            <Button variant="outline" onClick={handleCancel}>
              {options?.cancelText || 'Cancelar'}
            </Button>
            <Button variant={style.buttonVariant} onClick={handleConfirm}>
              {options?.confirmText || 'Confirmar'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </ConfirmContext.Provider>
  )
}
