'use client'

import { useEffect, useState } from 'react'
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
import { Alert, AlertDescription } from '@/components/ui/alert'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { ArrowLeft, Plus, Users, Loader2 } from 'lucide-react'
import type { Business, Profile } from '@/lib/types'

export default function UsersPage() {
  const params = useParams()
  const supabase = createClient()
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
  const [createError, setCreateError] = useState<string | null>(null)

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
    setCreating(true)
    setCreateError(null)

    // Crear usuario de auth
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: newEmail,
      password: newPassword,
      email_confirm: true,
      user_metadata: {
        full_name: newName,
      },
    })

    if (authError) {
      // Fallback: usar signUp si admin API no está disponible
      const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
        email: newEmail,
        password: newPassword,
        options: {
          data: {
            full_name: newName,
          },
        },
      })

      if (signUpError) {
        setCreateError(signUpError.message)
        setCreating(false)
        return
      }

      // Crear o actualizar perfil con business_id y role
      if (signUpData.user) {
        await supabase.from('profiles').upsert({
          id: signUpData.user.id,
          email: newEmail,
          business_id: businessId,
          role: newRole,
          full_name: newName,
          is_super_admin: false,
        })
      }
    } else if (authData.user) {
      // Crear o actualizar perfil con business_id y role
      await supabase.from('profiles').upsert({
        id: authData.user.id,
        email: newEmail,
        business_id: businessId,
        role: newRole,
        full_name: newName,
        is_super_admin: false,
      })
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
  }

  async function removeUser(userId: string) {
    if (!confirm('¿Estás seguro de remover este usuario del negocio?')) return

    await supabase.from('profiles').update({ business_id: null }).eq('id', userId)
    setUsers(users.filter((u) => u.id !== userId))
  }

  async function updateRole(userId: string, role: 'admin' | 'user') {
    await supabase.from('profiles').update({ role }).eq('id', userId)
    setUsers(users.map((u) => (u.id === userId ? { ...u, role } : u)))
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
                      onClick={() => removeUser(user.id)}
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

          {createError && (
            <Alert variant="destructive">
              <AlertDescription>{createError}</AlertDescription>
            </Alert>
          )}

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
              />
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
              disabled={creating || !newEmail || !newPassword}
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
