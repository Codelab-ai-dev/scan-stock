import 'producto.dart';

class VentaItem {
  final String? id;
  final String? ventaId;
  final String productoId;
  final String productoNombre;
  final String productoCodigoBarras;
  final double precioUnitario;
  final int cantidad;
  final double subtotal;
  final String? imagenUrl;

  // Producto completo para uso en UI (no se persiste)
  final Producto? producto;

  VentaItem({
    this.id,
    this.ventaId,
    required this.productoId,
    required this.productoNombre,
    required this.productoCodigoBarras,
    required this.precioUnitario,
    required this.cantidad,
    required this.subtotal,
    this.imagenUrl,
    this.producto,
  });

  /// Crea un VentaItem a partir de un Producto
  factory VentaItem.fromProducto(Producto producto, {int cantidad = 1}) {
    return VentaItem(
      productoId: producto.id!,
      productoNombre: producto.nombre,
      productoCodigoBarras: producto.codigoBarras,
      precioUnitario: producto.precio,
      cantidad: cantidad,
      subtotal: producto.precio * cantidad,
      imagenUrl: producto.imagenUrl,
      producto: producto,
    );
  }

  factory VentaItem.fromJson(Map<String, dynamic> json) {
    // Obtener imagen del join con productos si existe
    String? imagenUrl;
    if (json['productos'] != null && json['productos'] is Map) {
      imagenUrl = json['productos']['imagen_url'] as String?;
    }

    return VentaItem(
      id: json['id'] as String?,
      ventaId: json['venta_id'] as String?,
      productoId: json['producto_id'] as String,
      productoNombre: json['producto_nombre'] as String,
      productoCodigoBarras: json['producto_codigo_barras'] as String,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      cantidad: json['cantidad'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      imagenUrl: imagenUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (ventaId != null) 'venta_id': ventaId,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'producto_codigo_barras': productoCodigoBarras,
      'precio_unitario': precioUnitario,
      'cantidad': cantidad,
      'subtotal': subtotal,
    };
  }

  /// Crea una copia con cantidad actualizada (recalcula subtotal)
  VentaItem copyWith({int? cantidad}) {
    final newCantidad = cantidad ?? this.cantidad;
    return VentaItem(
      id: id,
      ventaId: ventaId,
      productoId: productoId,
      productoNombre: productoNombre,
      productoCodigoBarras: productoCodigoBarras,
      precioUnitario: precioUnitario,
      cantidad: newCantidad,
      subtotal: precioUnitario * newCantidad,
      imagenUrl: imagenUrl,
      producto: producto,
    );
  }

  String get subtotalFormateado => '\$${subtotal.toStringAsFixed(2)}';
  String get precioFormateado => '\$${precioUnitario.toStringAsFixed(2)}';
}
