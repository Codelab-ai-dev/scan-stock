import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header (JWT del usuario admin)
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    // Create Supabase client with service role (para crear usuarios)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Create client with user's JWT (para verificar permisos)
    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader }
        }
      }
    )

    // Verify the calling user is an admin
    const { data: { user: callingUser }, error: userError } = await supabaseUser.auth.getUser()
    if (userError || !callingUser) {
      throw new Error('Usuario no autenticado')
    }

    // Get calling user's profile to check if admin and get business_id
    const { data: callerProfile, error: profileError } = await supabaseUser
      .from('profiles')
      .select('role, business_id, is_super_admin')
      .eq('id', callingUser.id)
      .single()

    if (profileError || !callerProfile) {
      throw new Error('No se pudo obtener el perfil del usuario')
    }

    // Only admins can create users
    if (callerProfile.role !== 'admin' && !callerProfile.is_super_admin) {
      throw new Error('No tienes permisos para crear usuarios')
    }

    if (!callerProfile.business_id) {
      throw new Error('No estás asignado a ningún negocio')
    }

    // Get request body
    const { email, password, fullName, role } = await req.json()

    if (!email || !password || !fullName || !role) {
      throw new Error('Faltan campos requeridos: email, password, fullName, role')
    }

    // Validate role
    if (!['user', 'admin'].includes(role)) {
      throw new Error('Rol inválido. Debe ser "user" o "admin"')
    }

    // Create user using admin client (won't affect caller's session)
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        full_name: fullName,
        role: role,
      }
    })

    if (createError) {
      throw new Error(`Error al crear usuario: ${createError.message}`)
    }

    if (!newUser.user) {
      throw new Error('No se pudo crear el usuario')
    }

    // Check if profile exists (might be created by trigger)
    const { data: existingProfile } = await supabaseAdmin
      .from('profiles')
      .select('id')
      .eq('id', newUser.user.id)
      .maybeSingle()

    if (existingProfile) {
      // Update existing profile
      await supabaseAdmin
        .from('profiles')
        .update({
          full_name: fullName,
          role: role,
          business_id: callerProfile.business_id,
        })
        .eq('id', newUser.user.id)
    } else {
      // Create profile
      await supabaseAdmin
        .from('profiles')
        .insert({
          id: newUser.user.id,
          email: email,
          full_name: fullName,
          role: role,
          business_id: callerProfile.business_id,
        })
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Usuario creado exitosamente',
        user: {
          id: newUser.user.id,
          email: newUser.user.email,
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
