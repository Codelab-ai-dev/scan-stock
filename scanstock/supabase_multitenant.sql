-- =============================================
-- MIGRACIÓN: Sistema Multi-Tenant ScanStock
-- Ejecutar en Supabase SQL Editor
-- =============================================

-- 1. Tabla de negocios/tenants
CREATE TABLE IF NOT EXISTS public.businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  logo_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Tabla de módulos disponibles
CREATE TABLE IF NOT EXISTS public.modules (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  is_default BOOLEAN DEFAULT false
);

-- 3. Tabla de módulos habilitados por negocio
CREATE TABLE IF NOT EXISTS public.business_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
  module_id TEXT REFERENCES modules(id) ON DELETE CASCADE,
  enabled_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(business_id, module_id)
);

-- 4. Modificar tabla profiles (agregar campos multi-tenant)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS business_id UUID REFERENCES businesses(id),
  ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN DEFAULT false;

-- 5. Modificar tabla productos (agregar business_id)
ALTER TABLE public.productos
  ADD COLUMN IF NOT EXISTS business_id UUID REFERENCES businesses(id);

-- 6. Modificar tabla ventas (agregar business_id)
ALTER TABLE public.ventas
  ADD COLUMN IF NOT EXISTS business_id UUID REFERENCES businesses(id);

-- 7. Insertar módulos base
INSERT INTO modules (id, name, description, icon, is_default) VALUES
  ('inventory', 'Inventario', 'Gestión de productos y stock', 'inventory_2', true),
  ('sales', 'Ventas (POS)', 'Punto de venta y transacciones', 'point_of_sale', false),
  ('users', 'Usuarios', 'Gestión de empleados del negocio', 'people', false)
ON CONFLICT (id) DO NOTHING;

-- 8. Índices para rendimiento
CREATE INDEX IF NOT EXISTS idx_profiles_business ON profiles(business_id);
CREATE INDEX IF NOT EXISTS idx_profiles_super_admin ON profiles(is_super_admin) WHERE is_super_admin = true;
CREATE INDEX IF NOT EXISTS idx_productos_business ON productos(business_id);
CREATE INDEX IF NOT EXISTS idx_ventas_business ON ventas(business_id);
CREATE INDEX IF NOT EXISTS idx_business_modules_business ON business_modules(business_id);

-- 9. Trigger para updated_at en businesses
CREATE OR REPLACE FUNCTION update_businesses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS businesses_updated_at ON businesses;
CREATE TRIGGER businesses_updated_at
  BEFORE UPDATE ON businesses
  FOR EACH ROW
  EXECUTE FUNCTION update_businesses_updated_at();

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

-- 10. RLS para businesses (solo super-admin puede ver/gestionar)
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "businesses_super_admin_select" ON businesses;
CREATE POLICY "businesses_super_admin_select" ON businesses
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

DROP POLICY IF EXISTS "businesses_super_admin_insert" ON businesses;
CREATE POLICY "businesses_super_admin_insert" ON businesses
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

DROP POLICY IF EXISTS "businesses_super_admin_update" ON businesses;
CREATE POLICY "businesses_super_admin_update" ON businesses
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

DROP POLICY IF EXISTS "businesses_super_admin_delete" ON businesses;
CREATE POLICY "businesses_super_admin_delete" ON businesses
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

-- 11. RLS para modules (todos pueden leer, solo super-admin modifica)
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "modules_select_all" ON modules;
CREATE POLICY "modules_select_all" ON modules
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "modules_super_admin_modify" ON modules;
CREATE POLICY "modules_super_admin_modify" ON modules
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

-- 12. RLS para business_modules
ALTER TABLE business_modules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "business_modules_tenant_select" ON business_modules;
CREATE POLICY "business_modules_tenant_select" ON business_modules
  FOR SELECT USING (
    business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

DROP POLICY IF EXISTS "business_modules_super_admin_modify" ON business_modules;
CREATE POLICY "business_modules_super_admin_modify" ON business_modules
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

-- 13. Actualizar RLS de productos (aislamiento por negocio)
DROP POLICY IF EXISTS "Admins can do everything" ON productos;
DROP POLICY IF EXISTS "All authenticated users can read products" ON productos;
DROP POLICY IF EXISTS "productos_tenant" ON productos;

CREATE POLICY "productos_tenant_select" ON productos
  FOR SELECT USING (
    business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
    OR business_id IS NULL -- productos legacy sin negocio
  );

CREATE POLICY "productos_tenant_insert" ON productos
  FOR INSERT WITH CHECK (
    (
      business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
      AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    )
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

CREATE POLICY "productos_tenant_update" ON productos
  FOR UPDATE USING (
    (
      business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
      AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    )
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

CREATE POLICY "productos_tenant_delete" ON productos
  FOR DELETE USING (
    (
      business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
      AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    )
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

-- 14. Actualizar RLS de ventas (aislamiento por negocio)
DROP POLICY IF EXISTS "ventas_tenant" ON ventas;

CREATE POLICY "ventas_tenant_select" ON ventas
  FOR SELECT USING (
    business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
    OR business_id IS NULL -- ventas legacy
  );

CREATE POLICY "ventas_tenant_insert" ON ventas
  FOR INSERT WITH CHECK (
    business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

-- 15. Actualizar RLS de profiles (usuarios ven solo su negocio)
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile but not role" ON profiles;

CREATE POLICY "profiles_own_or_business" ON profiles
  FOR SELECT USING (
    id = auth.uid()
    OR business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND (
      -- usuarios normales no pueden cambiar su rol, business_id o is_super_admin
      (role = (SELECT role FROM profiles WHERE id = auth.uid()))
      OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
    )
  );

CREATE POLICY "profiles_super_admin_all" ON profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
  );

-- =============================================
-- FUNCIONES ÚTILES
-- =============================================

-- 16. Función para obtener módulos del usuario actual
CREATE OR REPLACE FUNCTION get_my_modules()
RETURNS TABLE(module_id TEXT, module_name TEXT, module_icon TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT m.id, m.name, m.icon
  FROM business_modules bm
  JOIN modules m ON m.id = bm.module_id
  JOIN profiles p ON p.business_id = bm.business_id
  WHERE p.id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 17. Función para verificar si el usuario tiene un módulo
CREATE OR REPLACE FUNCTION has_module(p_module_id TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM business_modules bm
    JOIN profiles p ON p.business_id = bm.business_id
    WHERE p.id = auth.uid()
    AND bm.module_id = p_module_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 18. Función para obtener info del negocio del usuario
CREATE OR REPLACE FUNCTION get_my_business()
RETURNS TABLE(
  business_id UUID,
  business_name TEXT,
  business_slug TEXT,
  business_logo TEXT,
  is_active BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT b.id, b.name, b.slug, b.logo_url, b.is_active
  FROM businesses b
  JOIN profiles p ON p.business_id = b.id
  WHERE p.id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 19. Función para crear un negocio con módulos por defecto
CREATE OR REPLACE FUNCTION create_business_with_defaults(
  p_name TEXT,
  p_slug TEXT,
  p_logo_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_business_id UUID;
BEGIN
  -- Crear negocio
  INSERT INTO businesses (name, slug, logo_url)
  VALUES (p_name, p_slug, p_logo_url)
  RETURNING id INTO v_business_id;

  -- Agregar módulos por defecto
  INSERT INTO business_modules (business_id, module_id)
  SELECT v_business_id, id FROM modules WHERE is_default = true;

  RETURN v_business_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- CREAR SUPER-ADMIN INICIAL (EJECUTAR UNA VEZ)
-- Reemplaza 'tu-email@ejemplo.com' con tu email real
-- =============================================

-- DESCOMENTAR Y EJECUTAR DESPUÉS DE CREAR TU USUARIO:
-- UPDATE profiles SET is_super_admin = true WHERE email = 'tu-email@ejemplo.com';

-- =============================================
-- EJEMPLO: Crear un negocio de prueba
-- =============================================

-- DESCOMENTAR PARA CREAR NEGOCIO DE PRUEBA:
-- SELECT create_business_with_defaults('Mi Tienda', 'mi-tienda', NULL);
