import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/venta.dart';
import '../models/venta_item.dart';

class SaleService {
  final SupabaseClient _client = SupabaseConfig.client;
  static const String _ventasTable = 'ventas';
  static const String _itemsTable = 'venta_items';
  static const String _productosTable = 'productos';

  /// Obtiene el business_id del usuario actual
  Future<String?> _getCurrentBusinessId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select('business_id')
        .eq('id', userId)
        .single();

    return response['business_id'] as String?;
  }

  /// Verifica si hay stock suficiente para todos los items
  /// Retorna lista de productos sin stock suficiente
  Future<List<String>> checkStockAvailability(List<VentaItem> items) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return ['Usuario no asignado a un negocio'];

    final insufficientStock = <String>[];

    for (final item in items) {
      final response = await _client
          .from(_productosTable)
          .select('stock_cantidad, nombre')
          .eq('business_id', businessId)
          .eq('id', item.productoId)
          .maybeSingle();

      if (response != null) {
        final stockActual = (response['stock_cantidad'] as int?) ?? 0;
        if (stockActual < item.cantidad) {
          insufficientStock.add(
            '${response['nombre']}: disponible $stockActual, solicitado ${item.cantidad}',
          );
        }
      }
    }

    return insufficientStock;
  }

  /// Crea una venta con todos sus items (valida y decrementa stock)
  Future<Venta> createSale(List<VentaItem> items) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    if (items.isEmpty) throw Exception('La venta debe tener al menos un item');

    final businessId = await _getCurrentBusinessId();
    if (businessId == null) {
      throw Exception('Usuario no asignado a un negocio');
    }

    // Verificar stock disponible
    final insufficientStock = await checkStockAvailability(items);
    if (insufficientStock.isNotEmpty) {
      throw Exception(
        'Stock insuficiente:\n${insufficientStock.join('\n')}',
      );
    }

    // Calcular totales
    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final cantidadItems = items.fold<int>(0, (sum, item) => sum + item.cantidad);

    // Crear venta (cabecera)
    final ventaData = {
      'total': total,
      'cantidad_items': cantidadItems,
      'created_by': userId,
      'business_id': businessId,
    };

    final ventaResponse = await _client
        .from(_ventasTable)
        .insert(ventaData)
        .select()
        .single();

    final ventaId = ventaResponse['id'] as String;

    // Crear items de la venta
    final itemsData = items
        .map((item) => {
              ...item.toJson(),
              'venta_id': ventaId,
            })
        .toList();

    await _client.from(_itemsTable).insert(itemsData);

    // Decrementar stock de cada producto
    for (final item in items) {
      await _client.rpc('decrementar_stock', params: {
        'p_producto_id': item.productoId,
        'p_cantidad': item.cantidad,
      });
    }

    return Venta.fromJson(ventaResponse, items: items);
  }

  /// Obtiene las ventas del usuario actual
  Future<List<Venta>> getMyVentas() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return [];

    final response = await _client
        .from(_ventasTable)
        .select()
        .eq('business_id', businessId)
        .eq('created_by', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Venta.fromJson(json)).toList();
  }

  /// Obtiene todas las ventas del negocio (solo admin)
  Future<List<Venta>> getAllVentas() async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return [];

    final response = await _client
        .from(_ventasTable)
        .select('*, profiles(full_name, email)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Venta.fromJson(json)).toList();
  }

  /// Obtiene una venta con sus items
  Future<Venta?> getVentaWithItems(String ventaId) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return null;

    final ventaResponse = await _client
        .from(_ventasTable)
        .select('*, profiles(full_name, email)')
        .eq('business_id', businessId)
        .eq('id', ventaId)
        .maybeSingle();

    if (ventaResponse == null) return null;

    // Obtener items con la imagen del producto
    final itemsResponse = await _client
        .from(_itemsTable)
        .select('*, productos(imagen_url)')
        .eq('venta_id', ventaId)
        .order('created_at');

    final items =
        (itemsResponse as List).map((json) => VentaItem.fromJson(json)).toList();

    return Venta.fromJson(ventaResponse, items: items);
  }

  /// Obtiene resumen de ventas del dia actual
  Future<Map<String, dynamic>> getTodaySummary() async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) {
      return {'total_ventas': 0, 'monto_total': 0.0, 'items_total': 0};
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final response = await _client
        .from(_ventasTable)
        .select('total, cantidad_items')
        .eq('business_id', businessId)
        .gte('created_at', startOfDay.toIso8601String());

    final ventas = response as List;
    final totalVentas = ventas.length;
    final montoTotal =
        ventas.fold<double>(0, (sum, v) => sum + (v['total'] as num).toDouble());
    final itemsTotal =
        ventas.fold<int>(0, (sum, v) => sum + (v['cantidad_items'] as int));

    return {
      'total_ventas': totalVentas,
      'monto_total': montoTotal,
      'items_total': itemsTotal,
    };
  }

  /// Obtiene ventas filtradas por rango de fechas
  Future<List<Venta>> getVentasByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    bool onlyMine = false,
  }) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return [];

    var query = _client
        .from(_ventasTable)
        .select('*, profiles(full_name, email)')
        .eq('business_id', businessId)
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String());

    if (onlyMine) {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        query = query.eq('created_by', userId);
      }
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List).map((json) => Venta.fromJson(json)).toList();
  }

  /// Stream de ventas en tiempo real
  Stream<List<Venta>> streamVentas({bool onlyMine = false, required String businessId}) {
    final userId = _client.auth.currentUser?.id;

    return _client
        .from(_ventasTable)
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .map((data) {
          var ventas = data.map((json) => Venta.fromJson(json)).toList();
          if (onlyMine && userId != null) {
            ventas = ventas.where((v) => v.createdBy == userId).toList();
          }
          return ventas;
        });
  }

  /// Obtiene ventas agrupadas por día para el dashboard
  Future<List<Map<String, dynamic>>> getSalesByDay(int days) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return [];

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day - days + 1);

    final response = await _client
        .from(_ventasTable)
        .select('total, created_at')
        .eq('business_id', businessId)
        .gte('created_at', startDate.toIso8601String())
        .order('created_at');

    // Agrupar por día
    final salesByDay = <String, Map<String, dynamic>>{};

    // Inicializar todos los días con 0
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      salesByDay[dateKey] = {
        'date': dateKey,
        'total': 0.0,
        'count': 0,
      };
    }

    // Sumar ventas por día
    for (final venta in response as List) {
      final createdAt = DateTime.parse(venta['created_at'] as String);
      final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      if (salesByDay.containsKey(dateKey)) {
        salesByDay[dateKey]!['total'] =
            (salesByDay[dateKey]!['total'] as double) + (venta['total'] as num).toDouble();
        salesByDay[dateKey]!['count'] = (salesByDay[dateKey]!['count'] as int) + 1;
      }
    }

    return salesByDay.values.toList();
  }

  /// Obtiene resumen de ventas (hoy, semana, mes)
  Future<Map<String, dynamic>> getSalesSummary() async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) {
      return {
        'today': {'total': 0.0, 'count': 0},
        'week': {'total': 0.0, 'count': 0},
        'month': {'total': 0.0, 'count': 0},
      };
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Obtener todas las ventas del mes
    final response = await _client
        .from(_ventasTable)
        .select('total, created_at')
        .eq('business_id', businessId)
        .gte('created_at', startOfMonth.toIso8601String());

    final ventas = response as List;

    double todayTotal = 0;
    double weekTotal = 0;
    double monthTotal = 0;
    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;

    for (final venta in ventas) {
      final createdAt = DateTime.parse(venta['created_at'] as String);
      final total = (venta['total'] as num).toDouble();

      monthTotal += total;
      monthCount++;

      if (createdAt.isAfter(startOfWeek) || createdAt.isAtSameMomentAs(startOfWeek)) {
        weekTotal += total;
        weekCount++;
      }

      if (createdAt.isAfter(startOfToday) || createdAt.isAtSameMomentAs(startOfToday)) {
        todayTotal += total;
        todayCount++;
      }
    }

    return {
      'today': {'total': todayTotal, 'count': todayCount},
      'week': {'total': weekTotal, 'count': weekCount},
      'month': {'total': monthTotal, 'count': monthCount},
    };
  }

  /// Obtiene productos con stock bajo del negocio actual
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return [];

    final response = await _client
        .from(_productosTable)
        .select('id, nombre, codigo_barras, stock_cantidad, stock_minimo, imagen_url')
        .eq('business_id', businessId)
        .order('stock_cantidad');

    // Filtrar productos donde stock <= minimo (client-side)
    final products = (response as List).cast<Map<String, dynamic>>();
    return products.where((p) {
      final stock = (p['stock_cantidad'] as int?) ?? 0;
      final minimo = (p['stock_minimo'] as int?) ?? 5;
      return stock <= minimo;
    }).toList();
  }

  /// Obtiene ventas paginadas
  Future<List<Venta>> getVentasPage({
    required int page,
    int pageSize = 20,
    bool onlyMine = false,
  }) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return [];

    final offset = page * pageSize;

    var query = _client
        .from(_ventasTable)
        .select('*, profiles(full_name, email)')
        .eq('business_id', businessId);

    if (onlyMine) {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        query = query.eq('created_by', userId);
      }
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + pageSize - 1);

    return (response as List).map((json) => Venta.fromJson(json)).toList();
  }

  /// Obtiene el total de ventas (para calcular páginas)
  Future<int> getVentasCount({bool onlyMine = false}) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return 0;

    var query = _client
        .from(_ventasTable)
        .select('id')
        .eq('business_id', businessId);

    if (onlyMine) {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        query = query.eq('created_by', userId);
      }
    }

    final response = await query;
    return (response as List).length;
  }
}
