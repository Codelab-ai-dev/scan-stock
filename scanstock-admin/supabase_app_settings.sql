-- Tabla para almacenar la configuración de la aplicación móvil
-- Ejecutar este SQL en el SQL Editor de Supabase

CREATE TABLE IF NOT EXISTS app_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  apk_url TEXT,
  apk_version TEXT,
  apk_size TEXT,
  apk_filename TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Habilitar RLS
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Política para lectura pública (cualquiera puede ver la info del APK)
CREATE POLICY "Public read access" ON app_settings
  FOR SELECT
  USING (true);

-- Política para que solo super admins puedan modificar
CREATE POLICY "Super admins can modify" ON app_settings
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_super_admin = true
    )
  );

-- Insertar registro inicial vacío
INSERT INTO app_settings (id) VALUES (gen_random_uuid())
ON CONFLICT DO NOTHING;

-- Comentario: Después de crear la tabla, agregar las siguientes variables de entorno:
-- BUNNY_STORAGE_ZONE=tu-storage-zone-name
-- BUNNY_API_KEY=tu-api-key
-- BUNNY_CDN_URL=https://tu-pullzone.b-cdn.net
