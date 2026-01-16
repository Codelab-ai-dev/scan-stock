-- =============================================================================
-- SCANSTOCK - RLS para Ventas y Funcion decrementar_stock
-- Ejecutar en Supabase SQL Editor
-- =============================================================================

-- 1. Habilitar RLS en tablas de ventas (si no esta habilitado)
ALTER TABLE ventas ENABLE ROW LEVEL SECURITY;
ALTER TABLE venta_items ENABLE ROW LEVEL SECURITY;

-- 2. Eliminar politicas existentes (para evitar conflictos)
DROP POLICY IF EXISTS "ventas_tenant_select" ON ventas;
DROP POLICY IF EXISTS "ventas_tenant_insert" ON ventas;
DROP POLICY IF EXISTS "ventas_tenant_update" ON ventas;
DROP POLICY IF EXISTS "ventas_tenant_delete" ON ventas;
DROP POLICY IF EXISTS "venta_items_tenant_select" ON venta_items;
DROP POLICY IF EXISTS "venta_items_tenant_insert" ON venta_items;

-- =============================================================================
-- POLITICAS RLS PARA VENTAS
-- =============================================================================

-- SELECT: Usuario puede ver ventas de su negocio, super-admin ve todo
CREATE POLICY "ventas_tenant_select" ON ventas
FOR SELECT USING (
    -- Mismo negocio
    business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
    -- O es super admin
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
    -- O legacy (sin negocio asignado)
    OR business_id IS NULL
);

-- INSERT: Usuario puede crear ventas en su negocio
CREATE POLICY "ventas_tenant_insert" ON ventas
FOR INSERT WITH CHECK (
    -- Mismo negocio
    business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
    -- O es super admin
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
);

-- UPDATE: Solo admins pueden actualizar ventas de su negocio
CREATE POLICY "ventas_tenant_update" ON ventas
FOR UPDATE USING (
    (
        business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    )
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
);

-- DELETE: Solo admins pueden eliminar ventas de su negocio
CREATE POLICY "ventas_tenant_delete" ON ventas
FOR DELETE USING (
    (
        business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    )
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
);

-- =============================================================================
-- POLITICAS RLS PARA VENTA_ITEMS
-- =============================================================================

-- SELECT: Usuario puede ver items de ventas de su negocio
CREATE POLICY "venta_items_tenant_select" ON venta_items
FOR SELECT USING (
    venta_id IN (
        SELECT id FROM ventas WHERE
            business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
            OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
            OR business_id IS NULL
    )
);

-- INSERT: Usuario puede crear items para ventas de su negocio
CREATE POLICY "venta_items_tenant_insert" ON venta_items
FOR INSERT WITH CHECK (
    venta_id IN (
        SELECT id FROM ventas WHERE
            business_id = (SELECT business_id FROM profiles WHERE id = auth.uid())
            OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_super_admin = true)
    )
);

-- =============================================================================
-- FUNCION: decrementar_stock
-- =============================================================================

-- Eliminar funcion existente si existe
DROP FUNCTION IF EXISTS decrementar_stock(UUID, INTEGER);

-- Crear funcion para decrementar stock de forma segura
CREATE OR REPLACE FUNCTION decrementar_stock(p_producto_id UUID, p_cantidad INTEGER)
RETURNS VOID AS $$
DECLARE
    v_stock_actual INTEGER;
    v_producto_nombre TEXT;
BEGIN
    -- Obtener stock actual y nombre del producto
    SELECT stock_cantidad, nombre INTO v_stock_actual, v_producto_nombre
    FROM productos
    WHERE id = p_producto_id;

    -- Verificar que el producto existe
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Producto con ID % no encontrado', p_producto_id;
    END IF;

    -- Verificar stock suficiente
    IF v_stock_actual < p_cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente para "%". Disponible: %, Solicitado: %',
            v_producto_nombre, v_stock_actual, p_cantidad;
    END IF;

    -- Decrementar stock
    UPDATE productos
    SET
        stock_cantidad = stock_cantidad - p_cantidad,
        updated_at = NOW()
    WHERE id = p_producto_id;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Dar permisos de ejecucion a usuarios autenticados
GRANT EXECUTE ON FUNCTION decrementar_stock(UUID, INTEGER) TO authenticated;

-- =============================================================================
-- INDICES PARA PERFORMANCE (si no existen)
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_ventas_business ON ventas(business_id);
CREATE INDEX IF NOT EXISTS idx_ventas_created_by ON ventas(created_by);
CREATE INDEX IF NOT EXISTS idx_ventas_created_at ON ventas(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_venta_items_venta ON venta_items(venta_id);
CREATE INDEX IF NOT EXISTS idx_venta_items_producto ON venta_items(producto_id);

-- =============================================================================
-- VERIFICACION
-- =============================================================================

-- Mostrar politicas creadas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('ventas', 'venta_items')
ORDER BY tablename, policyname;
