import 'package:flutter/material.dart';

/// ScanStock Theme - Industrial Warehouse Aesthetic
///
/// Inspiración: Almacén moderno, logística, señalización industrial
/// Colores: Tonos oscuros con acentos ámbar/naranja de seguridad
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PALETA DE COLORES - Industrial Warehouse
  // ═══════════════════════════════════════════════════════════════════════════

  // Colores primarios - Acento industrial ámbar/naranja
  static const Color primary = Color(0xFFFF9500);        // Ámbar industrial
  static const Color primaryDark = Color(0xFFE68600);    // Ámbar oscuro
  static const Color primaryLight = Color(0xFFFFAD33);   // Ámbar claro

  // Fondos - Tonos oscuros de almacén
  static const Color background = Color(0xFF0D1117);     // Negro profundo
  static const Color surface = Color(0xFF161B22);        // Gris carbón
  static const Color surfaceLight = Color(0xFF21262D);   // Gris elevado
  static const Color surfaceElevated = Color(0xFF30363D);// Gris tarjeta

  // Texto
  static const Color textPrimary = Color(0xFFF0F6FC);    // Blanco suave
  static const Color textSecondary = Color(0xFF8B949E);  // Gris claro
  static const Color textMuted = Color(0xFF484F58);      // Gris apagado

  // Estados y acentos
  static const Color success = Color(0xFF3FB950);        // Verde éxito
  static const Color error = Color(0xFFF85149);          // Rojo error
  static const Color warning = Color(0xFFD29922);        // Amarillo warning
  static const Color info = Color(0xFF58A6FF);           // Azul info

  // Bordes y divisores
  static const Color border = Color(0xFF30363D);
  static const Color borderLight = Color(0xFF21262D);

  // Gradientes industriales
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFFF7B00)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF161B22), Color(0xFF0D1117)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C2128), Color(0xFF161B22)],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SOMBRAS
  // ═══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMA PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryDark,
        secondary: primaryLight,
        surface: surface,
        error: error,
        onPrimary: Color(0xFF1A1A1A),
        onSurface: textPrimary,
        onError: Colors.white,
        outline: border,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input Decoration Theme - Industrial Style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: const TextStyle(
          color: error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return primary;
          }
          return textSecondary;
        }),
        suffixIconColor: textSecondary,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 8,
        shape: CircleBorder(),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceLight,
        circularTrackColor: surfaceLight,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 14,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 12,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS DECORATIVOS REUTILIZABLES
// ═══════════════════════════════════════════════════════════════════════════

/// Patrón de código de barras decorativo
class BarcodePattern extends StatelessWidget {
  final double height;
  final double opacity;

  const BarcodePattern({
    super.key,
    this.height = 40,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(30, (index) {
            final width = (index % 3 == 0) ? 3.0 : (index % 2 == 0) ? 2.0 : 1.0;
            return Container(
              width: width,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: AppTheme.textPrimary,
            );
          }),
        ),
      ),
    );
  }
}

/// Contenedor con estilo de tarjeta industrial
class IndustrialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool elevated;

  const IndustrialCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.showBorder = true,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: showBorder ? Border.all(color: AppTheme.border) : null,
        boxShadow: elevated ? AppTheme.cardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Badge de estado con colores industriales
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.admin() => const StatusBadge(
    label: 'Admin',
    color: AppTheme.primary,
    icon: Icons.admin_panel_settings,
  );

  factory StatusBadge.user() => const StatusBadge(
    label: 'Usuario',
    color: AppTheme.info,
    icon: Icons.person,
  );

  factory StatusBadge.inStock() => const StatusBadge(
    label: 'En Stock',
    color: AppTheme.success,
    icon: Icons.check_circle,
  );

  factory StatusBadge.lowStock() => const StatusBadge(
    label: 'Stock Bajo',
    color: AppTheme.warning,
    icon: Icons.warning,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icono con fondo circular estilizado
class IconCircle extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final bool showGlow;

  const IconCircle({
    super.key,
    required this.icon,
    this.color,
    this.size = 56,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppTheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withValues(alpha: 0.15),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: showGlow ? [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: iconColor,
      ),
    );
  }
}

/// Botón de acción con gradiente
class GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const GradientActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed != null && !isLoading
          ? AppTheme.primaryGradient
          : null,
        color: onPressed == null || isLoading
          ? AppTheme.surfaceElevated
          : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed != null && !isLoading ? [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: onPressed != null
                        ? const Color(0xFF1A1A1A)
                        : AppTheme.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onPressed != null
                          ? const Color(0xFF1A1A1A)
                          : AppTheme.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

/// Línea decorativa con gradiente
class GradientDivider extends StatelessWidget {
  final double height;
  final double indent;

  const GradientDivider({
    super.key,
    this.height = 1,
    this.indent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: indent),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.border,
            AppTheme.border,
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
    );
  }
}
