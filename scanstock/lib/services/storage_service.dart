import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/bunny_config.dart';

class StorageService {
  /// Sube una imagen de producto a Bunny Storage
  /// Retorna "bunny://path" para almacenar en BD
  Future<String?> uploadProductImage(File imageFile, String fileName) async {
    try {
      debugPrint('[StorageService] Iniciando upload a Bunny...');
      debugPrint('[StorageService] Archivo: ${imageFile.path}');
      debugPrint('[StorageService] fileName: $fileName');

      final bytes = await imageFile.readAsBytes();
      debugPrint('[StorageService] Bytes leídos: ${bytes.length}');

      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final filePath = 'productos/$fileName.$fileExt';
      final contentType = _getContentType(fileExt);

      debugPrint('[StorageService] Extension: $fileExt');
      debugPrint('[StorageService] FilePath: $filePath');
      debugPrint('[StorageService] ContentType: $contentType');

      final url = BunnyConfig.getStorageUrl(filePath);
      debugPrint('[StorageService] URL: $url');

      final headers = BunnyConfig.getAuthHeaders(contentType: contentType);

      debugPrint('[StorageService] Enviando request PUT a Bunny...');
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: bytes,
      );

      debugPrint('[StorageService] Response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('[StorageService] Upload exitoso! Path: $filePath');
        return 'bunny://$filePath';
      } else {
        debugPrint('[StorageService] Upload fallido: ${response.statusCode}');
        debugPrint('[StorageService] Response body: ${response.body}');
        throw Exception(
            'Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('[StorageService] Error: $e');
      debugPrint('[StorageService] StackTrace: $stackTrace');
      throw Exception('Error uploading image: $e');
    }
  }

  /// Elimina una imagen de producto de Bunny Storage
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      String filePath;

      if (imageUrl.startsWith('bunny://')) {
        filePath = imageUrl.replaceFirst('bunny://', '');
      } else if (imageUrl.contains('b-cdn.net')) {
        final uri = Uri.parse(imageUrl);
        filePath =
            uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      } else {
        debugPrint('[StorageService] URL no reconocida, ignorando: $imageUrl');
        return;
      }

      final url = BunnyConfig.getStorageUrl(filePath);
      final headers = BunnyConfig.getAuthHeaders();

      debugPrint('[StorageService] Eliminando de Bunny: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Bunny delete failed: ${response.statusCode}');
      }

      debugPrint('[StorageService] Eliminado de Bunny exitosamente');
    } catch (e) {
      throw Exception('Error deleting image: $e');
    }
  }

  String getPublicUrl(String filePath) {
    return BunnyConfig.getCdnUrl(filePath);
  }

  /// Convierte una URL almacenada a una URL accesible del CDN
  static String getAccessibleUrl(String? storedUrl) {
    if (storedUrl == null || storedUrl.isEmpty) return '';

    // Prefijo bunny://
    if (storedUrl.startsWith('bunny://')) {
      final path = storedUrl.replaceFirst('bunny://', '');
      return BunnyConfig.getCdnUrl(path);
    }

    // URL completa de CDN (ya es accesible)
    if (storedUrl.contains('b-cdn.net')) {
      return storedUrl;
    }

    // Otras URLs: devolver tal cual
    return storedUrl;
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
