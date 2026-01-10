# ScanStock Admin

Panel de administración para super-admins de la plataforma ScanStock.

## Tecnologías

- **SvelteKit 2** - Framework web
- **Svelte 5** - UI con runes
- **Tailwind CSS** - Estilos
- **DaisyUI** - Componentes
- **Supabase** - Backend (Auth + Database)

## Requisitos

- Node.js 18+
- npm o pnpm
- Cuenta de Supabase con el proyecto ScanStock configurado

## Instalación

1. Clonar el repositorio
2. Instalar dependencias:

```bash
npm install
```

3. Crear archivo `.env` con las credenciales de Supabase:

```env
PUBLIC_SUPABASE_URL=https://tu-proyecto.supabase.co
PUBLIC_SUPABASE_ANON_KEY=tu-anon-key
```

4. Ejecutar el servidor de desarrollo:

```bash
npm run dev
```

## Funcionalidades

- **Dashboard** - Vista general de la plataforma
- **Gestión de Negocios** - CRUD de negocios/tenants
- **Módulos** - Habilitar/deshabilitar módulos por negocio
- **Usuarios** - Gestión de usuarios por negocio

## Deploy

El proyecto está configurado para deploy en Vercel:

```bash
npm run build
```

## Estructura

```
src/
├── lib/
│   ├── components/     # Componentes reutilizables
│   ├── stores/         # Stores de Svelte
│   ├── types/          # TypeScript types
│   └── supabase.ts     # Cliente Supabase
├── routes/
│   ├── dashboard/      # Dashboard principal
│   ├── businesses/     # Gestión de negocios
│   └── settings/       # Configuración
└── app.html            # Template HTML
```
