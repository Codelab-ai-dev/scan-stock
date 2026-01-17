'use client'

import { createClient } from '@/lib/supabase/client'
import { useQuery, invalidateQueries } from './use-query'
import type { Business, BusinessStats } from '@/lib/types'

export function useBusiness(businessId: string) {
  const supabase = createClient()

  return useQuery<Business | null>(
    ['business', businessId],
    async () => {
      const { data, error } = await supabase
        .from('businesses')
        .select('*')
        .eq('id', businessId)
        .single()

      if (error) throw error
      return data
    },
    { enabled: !!businessId }
  )
}

export function useBusinesses() {
  const supabase = createClient()

  return useQuery<Business[]>(
    ['businesses'],
    async () => {
      const { data, error } = await supabase
        .from('businesses')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      return data ?? []
    }
  )
}

export function useBusinessStats(businessId: string) {
  const supabase = createClient()

  return useQuery<BusinessStats>(
    ['business-stats', businessId],
    async () => {
      const [productsRes, salesRes, usersRes, todayRes] = await Promise.all([
        supabase
          .from('productos')
          .select('*', { count: 'exact', head: true })
          .eq('business_id', businessId),
        supabase
          .from('ventas')
          .select('*', { count: 'exact', head: true })
          .eq('business_id', businessId),
        supabase
          .from('profiles')
          .select('*', { count: 'exact', head: true })
          .eq('business_id', businessId),
        supabase
          .from('ventas')
          .select('*', { count: 'exact', head: true })
          .eq('business_id', businessId)
          .gte('created_at', new Date().toISOString().split('T')[0]),
      ])

      return {
        total_products: productsRes.count ?? 0,
        total_sales: salesRes.count ?? 0,
        total_users: usersRes.count ?? 0,
        sales_today: todayRes.count ?? 0,
      }
    },
    { enabled: !!businessId }
  )
}

export function useBusinessUsers(businessId: string) {
  const supabase = createClient()

  return useQuery(
    ['business-users', businessId],
    async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('business_id', businessId)
        .order('created_at', { ascending: false })

      if (error) throw error
      return data ?? []
    },
    { enabled: !!businessId }
  )
}

// Invalidation helpers
export function invalidateBusinessQueries(businessId?: string) {
  if (businessId) {
    invalidateQueries(`business:${businessId}`)
    invalidateQueries(`business-stats:${businessId}`)
    invalidateQueries(`business-users:${businessId}`)
  }
  invalidateQueries('businesses')
}
