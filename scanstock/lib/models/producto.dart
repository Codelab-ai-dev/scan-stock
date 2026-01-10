import '../services/storage_service.dart';

class Producto {
  final String? id;
  final String codigoBarras;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final int stockCantidad;
  final int stockMinimo;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Producto({
    this.id,
    required this.codigoBarras,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.imagenUrl,
    this.stockCantidad = 0,
    this.stockMinimo = 5,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String?,
      codigoBarras: json['codigo_barras'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num).toDouble(),
      imagenUrl: json['imagen_url'] as String?,
      stockCantidad: (json['stock_cantidad'] as int?) ?? 0,
      stockMinimo: (json['stock_minimo'] as int?) ?? 5,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'codigo_barras': codigoBarras,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'imagen_url': imagenUrl,
      'stock_cantidad': stockCantidad,
      'stock_minimo': stockMinimo,
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  Producto copyWith({
    String? id,
    String? codigoBarras,
    String? nombre,
    String? descripcion,
    double? precio,
    String? imagenUrl,
    int? stockCantidad,
    int? stockMinimo,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Producto(
      id: id ?? this.id,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      stockCantidad: stockCantidad ?? this.stockCantidad,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get precioFormateado => '\$${precio.toStringAsFixed(2)}';

  /// Retorna la URL de imagen accesible (convierte wasabi:// a URL pre-firmada)
  String? get imagenUrlAccesible => StorageService.getAccessibleUrl(imagenUrl);

  /// Retorna true si el stock está por debajo del mínimo
  bool get tieneStockBajo => stockCantidad <= stockMinimo;

  /// Retorna true si no hay stock disponible
  bool get sinStock => stockCantidad <= 0;

  /// Retorna el color del indicador de stock
  /// Verde: OK, Amarillo: Bajo, Rojo: Agotado
  String get estadoStock {
    if (stockCantidad <= 0) return 'agotado';
    if (stockCantidad <= stockMinimo) return 'bajo';
    return 'disponible';
  }
}
