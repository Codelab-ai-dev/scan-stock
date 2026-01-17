import 'package:flutter/material.dart';

/// Helper centralizado para mostrar feedback al usuario
/// Uso: Feedback.success(context, 'Mensaje') o Feedback.of(context).success('Mensaje')

class Feedback {
  final BuildContext context;

  Feedback._(this.context);

  /// Factory para uso con patrón builder
  static Feedback of(BuildContext context) => Feedback._(context);

  // ============================================
  // MÉTODOS ESTÁTICOS (USO RÁPIDO)
  // ============================================

  /// Muestra snackbar de éxito
  static void success(BuildContext context, String message, {Duration? duration}) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green.shade600,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Muestra snackbar de error
  static void error(BuildContext context, String message, {Duration? duration}) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: Colors.red.shade600,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Muestra snackbar de advertencia
  static void warning(BuildContext context, String message, {Duration? duration}) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.orange.shade700,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Muestra snackbar informativo
  static void info(BuildContext context, String message, {Duration? duration}) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Colors.blue.shade600,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Muestra snackbar de carga (sin auto-dismiss)
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> loading(
    BuildContext context,
    String message,
  ) {
    return _showSnackBar(
      context,
      message: message,
      icon: null,
      backgroundColor: Colors.grey.shade800,
      duration: const Duration(days: 1), // Larga duración, se cierra manualmente
      showProgress: true,
    );
  }

  /// Cierra el snackbar actual
  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // ============================================
  // MÉTODOS DE INSTANCIA (PATRÓN BUILDER)
  // ============================================

  void showSuccess(String message, {Duration? duration}) =>
      success(context, message, duration: duration);

  void showError(String message, {Duration? duration}) =>
      error(context, message, duration: duration);

  void showWarning(String message, {Duration? duration}) =>
      warning(context, message, duration: duration);

  void showInfo(String message, {Duration? duration}) =>
      info(context, message, duration: duration);

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(String message) =>
      loading(context, message);

  void hide() => dismiss(context);

  // ============================================
  // SNACKBAR CON ACCIÓN
  // ============================================

  /// Muestra snackbar con botón de acción
  static void withAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Color? backgroundColor,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor ?? Colors.grey.shade800,
        duration: duration ?? const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
      ),
    );
  }

  /// Muestra snackbar con opción de deshacer
  static void withUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration? duration,
  }) {
    withAction(
      context,
      message: message,
      actionLabel: 'DESHACER',
      onAction: onUndo,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  // ============================================
  // DIÁLOGOS DE CONFIRMACIÓN
  // ============================================

  /// Muestra diálogo de confirmación
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? Colors.red : null,
              foregroundColor: isDanger ? Colors.white : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Diálogo de confirmación para eliminar
  static Future<bool> confirmDelete(
    BuildContext context, {
    String? itemName,
    String? customMessage,
  }) {
    return confirm(
      context,
      title: 'Confirmar eliminación',
      message: customMessage ??
          (itemName != null
              ? '¿Estás seguro de eliminar "$itemName"? Esta acción no se puede deshacer.'
              : '¿Estás seguro de eliminar este elemento? Esta acción no se puede deshacer.'),
      confirmText: 'Eliminar',
      isDanger: true,
    );
  }

  /// Diálogo de confirmación para salir sin guardar
  static Future<bool> confirmDiscard(BuildContext context) {
    return confirm(
      context,
      title: 'Descartar cambios',
      message: '¿Estás seguro de salir? Los cambios no guardados se perderán.',
      confirmText: 'Descartar',
      isDanger: true,
    );
  }

  // ============================================
  // DIÁLOGOS DE ENTRADA
  // ============================================

  /// Muestra diálogo para ingresar texto
  static Future<String?> inputDialog(
    BuildContext context, {
    required String title,
    String? hint,
    String? initialValue,
    String confirmText = 'Aceptar',
    String cancelText = 'Cancelar',
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
            keyboardType: keyboardType,
            validator: validator,
            autofocus: true,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  // ============================================
  // HELPER INTERNO
  // ============================================

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData? icon,
    required Color backgroundColor,
    required Duration duration,
    bool showProgress = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (showProgress) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ] else if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
