'use client'

import { useEffect, useState, useMemo } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent } from '@/components/ui/card'
import { Select } from '@/components/ui/select'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { useToast } from '@/components/ui/toast'
import { useConfirm } from '@/components/ui/confirm-modal'
import { ArrowLeft, Plus, Users, Loader2, Check, X } from 'lucide-react'
import type { Business, Profile } from '@/lib/types'

// Password validation
interface PasswordValidation {
  minLength: boolean
  hasUppercase: boolean
  hasLowercase: boolean
  hasNumber: boolean
}

function validatePassword(password: string): PasswordValidation {
  return {
    minLength: password.length >= 8,
    hasUppercase: /[A-Z]/.test(password),
    hasLowercase: /[a-z]/.test(password),
    hasNumber: /[0-9]/.test(password),
  }
}

function isPasswordValid(validation: PasswordValidation): boolean {
  return validation.minLength && validation.hasUppercase && validation.hasLowercase && validation.hasNumber
}

// Email validation
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

export default function UsersPage() {
  const params = useParams()
  const supabase = createClient()
  const toast = useToast()
  const { confirm } = useConfirm()
  const businessId = params.id as string

  const [business, setBusiness] = useState<Business | null>(null)
  const [users, setUsers] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [showAddModal, setShowAddModal] = useState(false)

  // New user form
  const [newEmail, setNewEmail] = useState('')
  const [newName, setNewName] = useState('')
  const [newRole, setNewRole] = useState<'admin' | 'user'>('user')
  const [newPassword, setNewPassword] = useState('')
  const [creating, setCreating] = useState(false)

  // Password validation
  const passwordValidation = useMemo(() => validatePassword(newPassword), [newPassword])
  const isFormValid = useMemo(() => {
    return newName.trim().length > 0 &&
           isValidEmail(newEmail) &&
           isPasswordValid(passwordValidation)
  }, [newName, newEmail, passwordValidation])

  useEffect(() => {
    loadData()
  }, [businessId])

  async function loadData() {
    setLoading(true)

    // Cargar negocio
    const { data: businessData } = await supabase
      .from('businesses')
      .select('*')
      .eq('id', businessId)
      .single()

    setBusiness(businessData)

    // Cargar usuarios de este negocio
    const { data: usersData } = await supabase
      .from('profiles')
      .select('*')
      .eq('business_id', businessId)
      .order('created_at', { ascending: false })

    setUsers(usersData ?? [])
    setLoading(false)
  }

  async function createUser() {
    // Validar antes de crear
    if (!newName.trim()) {
      toast.error('El nombre es requerido')
      return
    }
    if (!isValidEmail(newEmail)) {
      toast.error('El email no es válido')
      return
    }
    if (!isPasswordValid(passwordValidation)) {
      toast.error('La contraseña no cumple con los requisitos de seguridad')
      return
    }

    setCreating(true)

    // Metadata que incluye business_id y role para el trigger
    const userMetadata = {
      full_name: newName,
      role: newRole,
      business_id: businessId,
      is_super_admin: false,
    }

    // Crear usuario de auth (el trigger creará el perfil automáticamente)
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: newEmail,
      password: newPassword,
      email_confirm: true,
      user_metadata: userMetadata,
    })

    if (authError) {
      // Fallback: usar signUp si admin API no está disponible
      const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
        email: newEmail,
        password: newPassword,
        options: {
          data: userMetadata,
        },
      })

      if (signUpError) {
        toast.error(signUpError.message)
        setCreating(false)
        return
      }

      // Si el trigger no funcionó, actualizar el perfil manualmente
      if (signUpData.user) {
        await supabase
          .from('profiles')
          .update({
            business_id: businessId,
            role: newRole,
            full_name: newName,
          })
          .eq('id', signUpData.user.id)
      }
    } else if (authData.user) {
      // Si el trigger no funcionó, actualizar el perfil manualmente
      await supabase
        .from('profiles')
        .update({
          business_id: businessId,
          role: newRole,
          full_name: newName,
        })
        .eq('id', authData.user.id)
    }

    // Recargar usuarios
    await loadData()

    // Reset form
    setNewEmail('')
    setNewName('')
    setNewRole('user')
    setNewPassword('')
    setShowAddModal(false)
    setCreating(false)
    toast.success('Usuario creado correctamente')
  }

  async function removeUser(userId: string, userName: string) {
    const confirmed = await confirm({
      title: 'Remover usuario',
      message: `¿Estás seguro de remover a "${userName}" del negocio? El usuario no será eliminado, solo desvinculado.`,
      confirmText: 'Remover',
      cancelText: 'Cancelar',
      variant: 'warning',
    })

    if (!confirmed) return

    const { error } = await supabase.from('profiles').update({ business_id: null }).eq('id', userId)

    if (error) {
      toast.error('Error al remover usuario')
    } else {
      setUsers(users.filter((u) => u.id !== userId))
      toast.success('Usuario removido del negocio')
    }
  }

  async function updateRole(userId: string, role: 'admin' | 'user') {
    const { error } = await supabase.from('profiles').update({ role }).eq('id', userId)

    if (error) {
      toast.error('Error al cambiar rol')
    } else {
      setUsers(users.map((u) => (u.id === userId ? { ...u, role } : u)))
      toast.success('Rol actualizado')
    }
  }

  function formatDate(dateString: string): string {
    return new Date(dateString).toLocaleDateString('es-ES', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    })
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start gap-4">
        <Link href={`/businesses/${businessId}`}>
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div className="flex-1">
          <h1 className="text-2xl font-bold">Usuarios</h1>
          <p className="text-muted-foreground">{business?.name ?? 'Cargando...'}</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus className="h-4 w-4 mr-2" />
          Agregar usuario
        </Button>
      </div>

      {users.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-16">
            <Users className="h-12 w-12 text-muted-foreground mb-4" />
            <p className="text-muted-foreground mb-4">
              No hay usuarios en este negocio
            </p>
            <Button onClick={() => setShowAddModal(true)}>
              <Plus className="h-4 w-4 mr-2" />
              Agregar primer usuario
            </Button>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Usuario</TableHead>
                <TableHead>Rol</TableHead>
                <TableHead>Creado</TableHead>
                <TableHead></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {users.map((user) => (
                <TableRow key={user.id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <Avatar>
                        <AvatarFallback className="bg-primary/20 text-primary">
                          {user.full_name?.charAt(0) ?? user.email.charAt(0).toUpperCase()}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-medium">{user.full_name ?? 'Sin nombre'}</p>
                        <p className="text-sm text-muted-foreground">{user.email}</p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Select
                      value={user.role}
                      onChange={(e) =>
                        updateRole(user.id, e.target.value as 'admin' | 'user')
                      }
                    >
                      <option value="admin">Admin</option>
                      <option value="user">Usuario</option>
                    </Select>
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {formatDate(user.created_at)}
                  </TableCell>
                  <TableCell>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-destructive hover:text-destructive"
                      onClick={() => removeUser(user.id, user.full_name || user.email)}
                    >
                      Remover
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Card>
      )}

      {/* Add User Modal */}
      <Dialog open={showAddModal} onOpenChange={setShowAddModal}>
        <DialogContent onClose={() => setShowAddModal(false)}>
          <DialogHeader>
            <DialogTitle>Agregar usuario</DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Nombre completo</label>
              <Input
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                placeholder="Juan Pérez"
              />
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Email</label>
              <Input
                type="email"
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
                placeholder="juan@ejemplo.com"
                required
                className={newEmail.length > 0 && !isValidEmail(newEmail) ? 'border-destructive' : ''}
              />
              {newEmail.length > 0 && !isValidEmail(newEmail) && (
                <p className="text-xs text-destructive">Ingresa un email válido</p>
              )}
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Contraseña</label>
              <Input
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="••••••••"
                required
              />
              {newPassword.length > 0 && (
                <div className="space-y-1 text-xs">
                  <div className="flex items-center gap-2">
                    {passwordValidation.minLength ? (
                      <Check className="h-3 w-3 text-emerald-500" />
                    ) : (
                      <X className="h-3 w-3 text-destructive" />
                    )}
                    <span className={passwordValidation.minLength ? 'text-emerald-500' : 'text-muted-foreground'}>
                      Mínimo 8 caracteres
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    {passwordValidation.hasUppercase ? (
                      <Check className="h-3 w-3 text-emerald-500" />
                    ) : (
                      <X className="h-3 w-3 text-destructive" />
                    )}
                    <span className={passwordValidation.hasUppercase ? 'text-emerald-500' : 'text-muted-foreground'}>
                      Una letra mayúscula
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    {passwordValidation.hasLowercase ? (
                      <Check className="h-3 w-3 text-emerald-500" />
                    ) : (
                      <X className="h-3 w-3 text-destructive" />
                    )}
                    <span className={passwordValidation.hasLowercase ? 'text-emerald-500' : 'text-muted-foreground'}>
                      Una letra minúscula
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    {passwordValidation.hasNumber ? (
                      <Check className="h-3 w-3 text-emerald-500" />
                    ) : (
                      <X className="h-3 w-3 text-destructive" />
                    )}
                    <span className={passwordValidation.hasNumber ? 'text-emerald-500' : 'text-muted-foreground'}>
                      Un número
                    </span>
                  </div>
                </div>
              )}
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Rol</label>
              <Select
                value={newRole}
                onChange={(e) => setNewRole(e.target.value as 'admin' | 'user')}
              >
                <option value="user">Usuario</option>
                <option value="admin">Admin</option>
              </Select>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowAddModal(false)}>
              Cancelar
            </Button>
            <Button
              onClick={createUser}
              disabled={creating || !isFormValid}
            >
              {creating ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Creando...
                </>
              ) : (
                'Crear usuario'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
