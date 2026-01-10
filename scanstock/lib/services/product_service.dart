import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/producto.dart';

class ProductService {
  final SupabaseClient _client = SupabaseConfig.client;
  static const String _tableName = 'productos';

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

  Future<List<Producto>> getAllProducts() async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return [];

    final response = await _client
        .from(_tableName)
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Producto.fromJson(json))
        .toList();
  }

  Future<Producto?> getProductByBarcode(String barcode) async {
    try {
      final businessId = await _getCurrentBusinessId();
      if (businessId == null) return null;

      final response = await _client
          .from(_tableName)
          .select()
          .eq('business_id', businessId)
          .eq('codigo_barras', barcode)
          .maybeSingle();

      if (response == null) return null;
      return Producto.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Producto?> getProductById(String id) async {
    try {
      final businessId = await _getCurrentBusinessId();
      if (businessId == null) return null;

      final response = await _client
          .from(_tableName)
          .select()
          .eq('business_id', businessId)
          .eq('id', id)
          .single();

      return Producto.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Producto> createProduct(Producto producto) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final businessId = await _getCurrentBusinessId();
    if (businessId == null) {
      throw Exception('Usuario no asignado a un negocio');
    }

    final data = producto.toJson();
    data['created_by'] = userId;
    data['business_id'] = businessId;

    final response = await _client
        .from(_tableName)
        .insert(data)
        .select()
        .single();

    return Producto.fromJson(response);
  }

  Future<Producto> updateProduct(Producto producto) async {
    if (producto.id == null) {
      throw Exception('Product ID is required for update');
    }

    final businessId = await _getCurrentBusinessId();
    if (businessId == null) {
      throw Exception('Usuario no asignado a un negocio');
    }

    final response = await _client
        .from(_tableName)
        .update(producto.toJson())
        .eq('id', producto.id!)
        .eq('business_id', businessId)
        .select()
        .single();

    return Producto.fromJson(response);
  }

  Future<void> deleteProduct(String id) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return;

    await _client
        .from(_tableName)
        .delete()
        .eq('id', id)
        .eq('business_id', businessId);
  }

  Future<bool> barcodeExists(String barcode, {String? excludeId}) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return false;

    var query = _client
        .from(_tableName)
        .select('id')
        .eq('business_id', businessId)
        .eq('codigo_barras', barcode);

    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }

    final response = await query.maybeSingle();
    return response != null;
  }

  Stream<List<Producto>> streamProducts(String businessId) {
    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Producto.fromJson(json)).toList());
  }

  /// Obtiene productos paginados con búsqueda opcional
  Future<List<Producto>> getProductsPage({
    required int page,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return [];

    final offset = page * pageSize;

    var query = _client
        .from(_tableName)
        .select()
        .eq('business_id', businessId);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'nombre.ilike.%$searchQuery%,codigo_barras.ilike.%$searchQuery%',
      );
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + pageSize - 1);

    return (response as List)
        .map((json) => Producto.fromJson(json))
        .toList();
  }

  /// Obtiene el total de productos (para calcular páginas)
  Future<int> getProductCount({String? searchQuery}) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return 0;

    var query = _client
        .from(_tableName)
        .select('id')
        .eq('business_id', businessId);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'nombre.ilike.%$searchQuery%,codigo_barras.ilike.%$searchQuery%',
      );
    }

    final response = await query;
    return (response as List).length;
  }

  /// Actualiza el stock de un producto
  Future<void> updateStock(String productId, int cantidad) async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return;

    await _client
        .from(_tableName)
        .update({'stock_cantidad': cantidad})
        .eq('id', productId)
        .eq('business_id', businessId);
  }

  /// Obtiene productos con stock bajo
  Future<List<Producto>> getLowStockProducts() async {
    final businessId = await _getCurrentBusinessId();
    if (businessId == null) return [];

    final response = await _client
        .from(_tableName)
        .select()
        .eq('business_id', businessId)
        .order('stock_cantidad');

    final products = (response as List)
        .map((json) => Producto.fromJson(json))
        .toList();

    return products.where((p) => p.tieneStockBajo).toList();
  }
}
