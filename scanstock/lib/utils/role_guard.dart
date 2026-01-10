import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/user/user_home_screen.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando...'),
                  ],
                ),
              ),
            );

          case AuthStatus.authenticated:
            if (authProvider.isAdmin) {
              return const AdminHomeScreen();
            } else {
              return const UserHomeScreen();
            }

          case AuthStatus.unauthenticated:
            return const LoginScreen();
        }
      },
    );
  }
}

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        if (!authProvider.isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Acceso denegado')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes permiso para acceder a esta seccion',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
