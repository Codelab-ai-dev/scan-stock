import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  Profile? _profile;
  String? _error;
  List<String> _enabledModules = [];
  StreamSubscription<AuthState>? _authSubscription;

  AuthStatus get status => _status;
  Profile? get profile => _profile;
  String? get error => _error;
  List<String> get enabledModules => _enabledModules;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _profile?.isAdmin ?? false;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isSuperAdmin => _profile?.isSuperAdmin ?? false;
  bool get hasNegocio => _profile?.hasNegocio ?? false;

  /// Verifica si el usuario tiene acceso a un módulo específico
  bool hasModule(String moduleId) => _enabledModules.contains(moduleId);

  AuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((state) async {
      if (state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.tokenRefreshed) {
        await _loadProfile();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _profile = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });

    _checkCurrentSession();
  }

  Future<void> _checkCurrentSession() async {
    if (_authService.isLoggedIn) {
      await _loadProfile();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    try {
      _profile = await _authService.getCurrentProfile();

      // Cargar módulos habilitados si tiene negocio
      if (_profile?.businessId != null) {
        _enabledModules = await _authService.getEnabledModules();
      } else {
        _enabledModules = [];
      }

      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = 'Error loading profile';
    }
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _authService.signIn(
        email: email,
        password: password,
      );

      // Esperar a que el listener de authStateChanges cargue el perfil
      // No llamamos _loadProfile() aquí porque ya lo hace el listener en _init()
      await Future.delayed(const Duration(milliseconds: 100));

      // Si el listener aún no cargó el perfil, lo cargamos
      if (_profile == null) {
        await _loadProfile();
      }

      // Bloquear acceso de super-admin en la app móvil
      if (_profile?.isSuperAdmin == true) {
        await _authService.signOut();
        _profile = null;
        _status = AuthStatus.unauthenticated;
        _error = 'Los super-administradores deben usar el panel web';
        notifyListeners();
        return false;
      }

      // Verificar que el usuario tenga un negocio asignado
      if (_profile?.businessId == null) {
        await _authService.signOut();
        _profile = null;
        _status = AuthStatus.unauthenticated;
        _error = 'Tu cuenta no está asignada a ningún negocio';
        notifyListeners();
        return false;
      }

      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _profile = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error signing out';
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
