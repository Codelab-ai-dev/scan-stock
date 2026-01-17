import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String role = 'user',
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Profile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return Profile.fromJson(response);
  }

  Future<bool> isCurrentUserAdmin() async {
    final profile = await getCurrentProfile();
    return profile?.isAdmin ?? false;
  }

  Future<void> updateProfile({
    String? fullName,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    await _client.from('profiles').update({
      if (fullName != null) 'full_name': fullName,
    }).eq('id', user.id);
  }

  /// Actualiza la contraseña del usuario actual
  Future<void> updatePassword({
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No hay usuario logueado');

    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Crea un usuario para el mismo negocio del admin actual.
  /// Usa una Edge Function para no afectar la sesión del admin.
  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Debes estar logueado como admin');
    }

    // Llamar a la Edge Function
    final response = await _client.functions.invoke(
      'create-user',
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': role,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Error desconocido al crear usuario';
      throw Exception(error);
    }

    if (response.data?['success'] != true) {
      throw Exception(response.data?['error'] ?? 'Error al crear usuario');
    }
  }

  /// Obtiene todos los usuarios del mismo negocio que el usuario actual
  Future<List<Profile>> getAllUsers() async {
    final user = currentUser;
    if (user == null) return [];

    // Obtener el business_id del usuario actual
    final profileResponse = await _client
        .from('profiles')
        .select('business_id')
        .eq('id', user.id)
        .single();

    final businessId = profileResponse['business_id'];
    if (businessId == null) return [];

    // Obtener usuarios del mismo negocio
    final response = await _client
        .from('profiles')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  /// Obtiene los módulos habilitados para el negocio del usuario actual
  Future<List<String>> getEnabledModules() async {
    final user = currentUser;
    if (user == null) {
      debugPrint('[getEnabledModules] No hay usuario logueado');
      return [];
    }

    try {
      // Primero obtener el business_id del perfil
      final profileResponse = await _client
          .from('profiles')
          .select('business_id')
          .eq('id', user.id)
          .single();

      final businessId = profileResponse['business_id'];
      debugPrint('[getEnabledModules] business_id: $businessId');

      if (businessId == null) {
        debugPrint('[getEnabledModules] Usuario sin business_id');
        return [];
      }

      // Obtener los módulos habilitados para ese negocio
      final modulesResponse = await _client
          .from('business_modules')
          .select('module_id')
          .eq('business_id', businessId);

      final modules = (modulesResponse as List)
          .map((item) => item['module_id'] as String)
          .toList();

      debugPrint('[getEnabledModules] Módulos encontrados: $modules');
      return modules;
    } catch (e) {
      debugPrint('[getEnabledModules] ERROR: $e');
      return [];
    }
  }
}
