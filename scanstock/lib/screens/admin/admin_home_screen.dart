import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'product_list_screen.dart';
import 'product_form_screen.dart';
import 'user_management_screen.dart';
import 'reports_screen.dart';
import 'dashboard_screen.dart';
import '../user/scanner_screen.dart';
import '../sales/new_sale_screen.dart';
import '../sales/sales_history_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(profile?.fullName ?? 'Administrador'),
                      const SizedBox(height: 20),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildMenuSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.surface.withValues(alpha: 0.95),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'ScanStock',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Cerrar sesion',
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(String name) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0, 0.6, curve: Curves.easeOut),
        ),
        child: IndustrialCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 24,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge.admin(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final authProvider = context.read<AuthProvider>();
    final hasInventory = authProvider.hasModule('inventory');
    final hasSales = authProvider.hasModule('sales');

    // Construir lista de acciones rápidas según módulos habilitados
    final List<Widget> actionCards = [];

    if (hasSales) {
      actionCards.add(
        Expanded(
          child: _buildActionCard(
            icon: Icons.point_of_sale_rounded,
            title: 'Nueva\nVenta',
            color: AppTheme.primary,
            delay: 0.3,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewSaleScreen(),
                ),
              );
            },
          ),
        ),
      );
    }

    if (hasInventory) {
      actionCards.add(
        Expanded(
          child: _buildActionCard(
            icon: Icons.add_box_rounded,
            title: 'Nuevo\nProducto',
            color: AppTheme.success,
            delay: 0.4,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductFormScreen(),
                ),
              );
            },
          ),
        ),
      );
      actionCards.add(
        Expanded(
          child: _buildActionCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Escanear\nProducto',
            color: AppTheme.info,
            delay: 0.5,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScannerScreen(),
                ),
              );
            },
          ),
        ),
      );
      actionCards.add(
        Expanded(
          child: _buildActionCard(
            icon: Icons.inventory_2_rounded,
            title: 'Ver\nProductos',
            color: AppTheme.warning,
            delay: 0.6,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ),
              );
            },
          ),
        ),
      );
    }

    // Si no hay acciones, no mostrar esta sección
    if (actionCards.isEmpty) {
      return const SizedBox.shrink();
    }

    // Organizar en filas de 2
    final List<Widget> rows = [];
    for (int i = 0; i < actionCards.length; i += 2) {
      final rowChildren = <Widget>[actionCards[i]];
      if (i + 1 < actionCards.length) {
        rowChildren.add(const SizedBox(width: 10));
        rowChildren.add(actionCards[i + 1]);
      }
      rows.add(Row(children: rowChildren));
      if (i + 2 < actionCards.length) {
        rows.add(const SizedBox(height: 10));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ACCIONES RAPIDAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...rows,
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required double delay,
  }) {
    final clampedDelay = delay.clamp(0.0, 0.7);
    final clampedEnd = (clampedDelay + 0.3).clamp(0.0, 1.0);
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(clampedDelay, clampedEnd, curve: Curves.easeOutCubic),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Interval(clampedDelay, clampedEnd, curve: Curves.easeOut),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.15),
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(icon, size: 22, color: color),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    final authProvider = context.read<AuthProvider>();
    final hasInventory = authProvider.hasModule('inventory');
    final hasSales = authProvider.hasModule('sales');
    final hasUsers = authProvider.hasModule('users');

    final List<Widget> menuItems = [];
    double delay = 0.6;

    // Módulo Inventario
    if (hasInventory) {
      menuItems.add(_buildMenuItem(
        icon: Icons.qr_code_scanner_rounded,
        title: 'Escanear Producto',
        subtitle: 'Buscar producto por codigo de barras',
        delay: delay,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScannerScreen(),
            ),
          );
        },
      ));
      delay += 0.05;

      menuItems.add(_buildMenuItem(
        icon: Icons.inventory_2_rounded,
        title: 'Gestionar Productos',
        subtitle: 'Ver, crear, editar y eliminar productos',
        delay: delay,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductListScreen(),
            ),
          );
        },
      ));
      delay += 0.05;
    }

    // Módulo Usuarios
    if (hasUsers) {
      menuItems.add(_buildMenuItem(
        icon: Icons.people_alt_rounded,
        title: 'Gestionar Usuarios',
        subtitle: 'Agregar y administrar usuarios del sistema',
        delay: delay,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserManagementScreen(),
            ),
          );
        },
      ));
      delay += 0.05;
    }

    // Módulo Ventas
    if (hasSales) {
      menuItems.add(_buildMenuItem(
        icon: Icons.receipt_long_rounded,
        title: 'Historial de Ventas',
        subtitle: 'Ver todas las ventas realizadas',
        delay: delay,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SalesHistoryScreen(isAdmin: true),
            ),
          );
        },
      ));
      delay += 0.05;

      menuItems.add(_buildMenuItem(
        icon: Icons.dashboard_rounded,
        title: 'Dashboard',
        subtitle: 'Estadísticas y métricas de ventas',
        delay: delay,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
            ),
          );
        },
      ));
      delay += 0.05;

      menuItems.add(_buildMenuItem(
        icon: Icons.analytics_rounded,
        title: 'Reportes',
        subtitle: 'Generar reportes PDF y Excel',
        delay: delay,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReportsScreen(),
            ),
          );
        },
      ));
    }

    if (menuItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.block_rounded,
                size: 64,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay módulos habilitados',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Contacta al administrador para habilitar funcionalidades',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'MENU PRINCIPAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...menuItems,
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double delay,
  }) {
    final clampedDelay = delay.clamp(0.0, 0.8);
    final clampedEnd = (clampedDelay + 0.2).clamp(0.0, 1.0);
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(clampedDelay, clampedEnd, curve: Curves.easeOutCubic),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Interval(clampedDelay, clampedEnd, curve: Curves.easeOut),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.error.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cerrar sesion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estas seguro que deseas cerrar sesion?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthProvider>().signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Salir',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
