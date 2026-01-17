// Utilidades de validación centralizadas para la app
// Uso: Validators.email(value) o Validators.required(value, 'Campo')

class Validators {
  Validators._(); // Previene instanciación

  // ============================================
  // VALIDACIONES BÁSICAS
  // ============================================

  /// Valida que el campo no esté vacío
  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida formato de email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  /// Valida contraseña con requisitos de seguridad
  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < minLength) {
      return 'Mínimo $minLength caracteres';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe incluir al menos una mayúscula';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe incluir al menos una minúscula';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe incluir al menos un número';
    }

    return null;
  }

  /// Valida que las contraseñas coincidan
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirma la contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  // ============================================
  // VALIDACIONES NUMÉRICAS
  // ============================================

  /// Valida que sea un número válido
  static String? number(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    if (double.tryParse(value.trim()) == null) {
      return '$fieldName debe ser un número válido';
    }

    return null;
  }

  /// Valida que sea un número positivo
  static String? positiveNumber(String? value, [String fieldName = 'Este campo']) {
    final numberError = number(value, fieldName);
    if (numberError != null) return numberError;

    final num = double.parse(value!.trim());
    if (num <= 0) {
      return '$fieldName debe ser mayor a 0';
    }

    return null;
  }

  /// Valida que sea un número no negativo (0 o mayor)
  static String? nonNegativeNumber(String? value, [String fieldName = 'Este campo']) {
    final numberError = number(value, fieldName);
    if (numberError != null) return numberError;

    final num = double.parse(value!.trim());
    if (num < 0) {
      return '$fieldName no puede ser negativo';
    }

    return null;
  }

  /// Valida que sea un entero válido
  static String? integer(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    if (int.tryParse(value.trim()) == null) {
      return '$fieldName debe ser un número entero';
    }

    return null;
  }

  /// Valida que sea un entero positivo
  static String? positiveInteger(String? value, [String fieldName = 'Este campo']) {
    final intError = integer(value, fieldName);
    if (intError != null) return intError;

    final num = int.parse(value!.trim());
    if (num <= 0) {
      return '$fieldName debe ser mayor a 0';
    }

    return null;
  }

  /// Valida rango numérico
  static String? numberInRange(
    String? value,
    double min,
    double max, [
    String fieldName = 'Este campo',
  ]) {
    final numberError = number(value, fieldName);
    if (numberError != null) return numberError;

    final num = double.parse(value!.trim());
    if (num < min || num > max) {
      return '$fieldName debe estar entre $min y $max';
    }

    return null;
  }

  // ============================================
  // VALIDACIONES DE TEXTO
  // ============================================

  /// Valida longitud mínima
  static String? minLength(String? value, int length, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    if (value.trim().length < length) {
      return '$fieldName debe tener al menos $length caracteres';
    }

    return null;
  }

  /// Valida longitud máxima
  static String? maxLength(String? value, int length, [String fieldName = 'Este campo']) {
    if (value != null && value.trim().length > length) {
      return '$fieldName no puede exceder $length caracteres';
    }

    return null;
  }

  /// Valida longitud exacta
  static String? exactLength(String? value, int length, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    if (value.trim().length != length) {
      return '$fieldName debe tener exactamente $length caracteres';
    }

    return null;
  }

  /// Valida que solo contenga letras
  static String? alphabetic(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(value.trim())) {
      return '$fieldName solo puede contener letras';
    }

    return null;
  }

  /// Valida que solo contenga letras y números
  static String? alphanumeric(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    if (!RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(value.trim())) {
      return '$fieldName solo puede contener letras y números';
    }

    return null;
  }

  // ============================================
  // VALIDACIONES ESPECÍFICAS DE NEGOCIO
  // ============================================

  /// Valida código de barras (EAN-13, UPC-A, etc.)
  static String? barcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Código de barras puede ser opcional
    }

    final cleaned = value.trim().replaceAll(RegExp(r'\s'), '');

    // Permitir formatos comunes: EAN-13, EAN-8, UPC-A, códigos internos
    if (!RegExp(r'^[0-9]{4,14}$').hasMatch(cleaned)) {
      return 'Código de barras inválido';
    }

    return null;
  }

  /// Valida SKU (Stock Keeping Unit)
  static String? sku(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // SKU puede ser opcional
    }

    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(value.trim())) {
      return 'SKU solo puede contener letras, números, guiones y guiones bajos';
    }

    if (value.trim().length > 50) {
      return 'SKU no puede exceder 50 caracteres';
    }

    return null;
  }

  /// Valida precio
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El precio es requerido';
    }

    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Ingresa un precio válido';
    }

    if (price < 0) {
      return 'El precio no puede ser negativo';
    }

    // Validar máximo 2 decimales
    if (value.contains('.')) {
      final decimals = value.split('.')[1];
      if (decimals.length > 2) {
        return 'Máximo 2 decimales';
      }
    }

    return null;
  }

  /// Valida cantidad/stock
  static String? stock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La cantidad es requerida';
    }

    final stock = int.tryParse(value.trim());
    if (stock == null) {
      return 'Ingresa una cantidad válida';
    }

    if (stock < 0) {
      return 'La cantidad no puede ser negativa';
    }

    return null;
  }

  /// Valida teléfono (formato flexible)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Teléfono puede ser opcional
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(cleaned)) {
      return 'Ingresa un teléfono válido';
    }

    return null;
  }

  /// Valida URL
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL puede ser opcional
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Ingresa una URL válida';
    }

    return null;
  }

  // ============================================
  // COMBINADORES
  // ============================================

  /// Combina múltiples validadores (retorna el primer error)
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  /// Validación opcional (solo valida si hay valor)
  static String? Function(String?) optional(String? Function(String?) validator) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return validator(value);
    };
  }
}
