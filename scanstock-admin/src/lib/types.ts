export interface Business {
  id: string
  name: string
  slug: string
  logo_url: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Module {
  id: string
  name: string
  description: string | null
  icon: string | null
  is_default: boolean
}

export interface BusinessModule {
  id: string
  business_id: string
  module_id: string
  enabled_at: string
}

export interface Profile {
  id: string
  email: string
  full_name: string | null
  role: 'admin' | 'user'
  business_id: string | null
  is_super_admin: boolean
  created_at: string
}

export interface BusinessWithModules extends Business {
  modules: Module[]
}

export interface BusinessStats {
  total_products: number
  total_sales: number
  total_users: number
  sales_today: number
}

export interface AppSettings {
  id: string
  apk_url: string | null
  apk_version: string | null
  apk_size: string | null
  apk_filename: string | null
  updated_at: string
  updated_by: string | null
}
