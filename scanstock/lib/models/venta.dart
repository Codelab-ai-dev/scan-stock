import 'venta_item.dart';

class Venta {
  final String? id;
  final double total;
  final int cantidadItems;
  final String? createdBy;
  final DateTime? createdAt;
  final List<VentaItem>? items;

  // Datos adicionales del creador (para mostrar en historial de admin)
  final String? creadorNombre;
  final String? creadorEmail;

  Venta({
    this.id,
    required this.total,
    required this.cantidadItems,
    this.createdBy,
    this.createdAt,
    this.items,
    this.creadorNombre,
    this.creadorEmail,
  });

  factory Venta.fromJson(Map<String, dynamic> json, {List<VentaItem>? items}) {
    // Manejar datos del creador si vienen incluidos (join con profiles)
    String? creadorNombre;
    String? creadorEmail;

    if (json['profiles'] != null && json['profiles'] is Map) {
      creadorNombre = json['profiles']['full_name'] as String?;
      creadorEmail = json['profiles']['email'] as String?;
    }

    return Venta(
      id: json['id'] as String?,
      total: (json['total'] as num).toDouble(),
      cantidadItems: json['cantidad_items'] as int,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      items: items,
      creadorNombre: creadorNombre,
      creadorEmail: creadorEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'total': total,
      'cantidad_items': cantidadItems,
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  Venta copyWith({
    String? id,
    double? total,
    int? cantidadItems,
    String? createdBy,
    DateTime? createdAt,
    List<VentaItem>? items,
    String? creadorNombre,
    String? creadorEmail,
  }) {
    return Venta(
      id: id ?? this.id,
      total: total ?? this.total,
      cantidadItems: cantidadItems ?? this.cantidadItems,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      creadorNombre: creadorNombre ?? this.creadorNombre,
      creadorEmail: creadorEmail ?? this.creadorEmail,
    );
  }

  String get totalFormateado => '\$${total.toStringAsFixed(2)}';

  String get fechaFormateada {
    if (createdAt == null) return '';
    final dia = createdAt!.day.toString().padLeft(2, '0');
    final mes = createdAt!.month.toString().padLeft(2, '0');
    final anio = createdAt!.year;
    final hora = createdAt!.hour.toString().padLeft(2, '0');
    final minuto = createdAt!.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
  }

  String get fechaCorta {
    if (createdAt == null) return '';
    final dia = createdAt!.day.toString().padLeft(2, '0');
    final mes = createdAt!.month.toString().padLeft(2, '0');
    final anio = createdAt!.year;
    return '$dia/$mes/$anio';
  }
}
