import 'package:flutter_dotenv/flutter_dotenv.dart';

class BunnyConfig {
  // Credenciales de Storage Zone
  static String get storageZoneName => dotenv.env['BUNNY_STORAGE_ZONE'] ?? '';
  static String get storagePassword => dotenv.env['BUNNY_STORAGE_PASSWORD'] ?? '';
  static String get storageRegion => dotenv.env['BUNNY_STORAGE_REGION'] ?? 'ny';

  // CDN Pull Zone para URLs públicas
  static String get pullZoneName => dotenv.env['BUNNY_PULL_ZONE'] ?? '';

  /// Endpoint de la Storage Zone
  /// Regiones: ny (New York), la (Los Angeles), sg (Singapore),
  ///           syd (Sydney), uk (London), de (Frankfurt), jh (Johannesburg)
  static String get storageEndpoint {
    final region = storageRegion;
    if (region == 'de') {
      return 'storage.bunnycdn.com'; // Frankfurt es el default
    }
    return '$region.storage.bunnycdn.com';
  }

  /// URL base para operaciones de Storage (upload/delete)
  static String get storageBaseUrl =>
      'https://$storageEndpoint/$storageZoneName';

  /// URL base del CDN para acceso público
  static String get cdnBaseUrl => 'https://$pullZoneName.b-cdn.net';

  /// Headers requeridos para autenticación con Bunny Storage
  static Map<String, String> getAuthHeaders({String? contentType}) {
    return {
      'AccessKey': storagePassword,
      if (contentType != null) 'Content-Type': contentType,
    };
  }

  /// Genera URL pública del CDN para un archivo
  static String getCdnUrl(String filePath) {
    final cleanPath =
        filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$cdnBaseUrl/$cleanPath';
  }

  /// Genera URL de storage para operaciones (upload/delete)
  static String getStorageUrl(String filePath) {
    final cleanPath =
        filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$storageBaseUrl/$cleanPath';
  }
}
