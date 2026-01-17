import 'dart:async';

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/producto.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/product_card.dart';
import '../../utils/feedback.dart' as app_feedback;
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  List<Producto> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _error;
  int _currentPage = 0;
  static const int _pageSize = 20;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scrollController.addListener(_onScroll);
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  void _onSearchChanged() {
    // Cancelar timer anterior si existe
    _debounceTimer?.cancel();

    // Esperar 500ms antes de buscar (debounce real)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 0;
      _hasMoreData = true;
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
    });

    try {
      final searchQuery = _searchController.text.trim();
      final products = await _productService.getProductsPage(
        page: 0,
        pageSize: _pageSize,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      );
      setState(() {
        _products = products;
        _isLoading = false;
        _hasMoreData = products.length >= _pageSize;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = 'Error al cargar productos';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final searchQuery = _searchController.text.trim();
      final nextPage = _currentPage + 1;
      final newProducts = await _productService.getProductsPage(
        page: nextPage,
        pageSize: _pageSize,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      );

      setState(() {
        _currentPage = nextPage;
        _products.addAll(newProducts);
        _isLoadingMore = false;
        _hasMoreData = newProducts.length >= _pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _deleteProduct(Producto product) async {
    final confirm = await app_feedback.Feedback.confirmDelete(
      context,
      itemName: product.nombre,
    );

    if (!confirm) return;

    try {
      if (product.imagenUrl != null && product.imagenUrl!.isNotEmpty) {
        await _storageService.deleteProductImage(product.imagenUrl!);
      }

      await _productService.deleteProduct(product.id!);

      if (mounted) {
        app_feedback.Feedback.success(context, 'Producto eliminado');
        _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        app_feedback.Feedback.error(context, 'Error al eliminar: $e');
      }
    }
  }

  void _editProduct(Producto product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    ).then((_) => _loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Productos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: _loadProducts,
              tooltip: 'Actualizar',
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o codigo...',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cargando productos...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(
                _searchController.text.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.inventory_2_rounded,
                size: 48,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No se encontraron productos'
                  : 'No hay productos registrados',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Intenta con otros terminos de busqueda'
                  : 'Agrega tu primer producto',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: 24),
              GradientActionButton(
                label: 'Agregar producto',
                icon: Icons.add_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductFormScreen(),
                    ),
                  ).then((_) => _loadProducts());
                },
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.primary,
      backgroundColor: AppTheme.surfaceLight,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 100, top: 8),
        itemCount: _products.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Indicador de carga al final
          if (index == _products.length) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            );
          }

          final product = _products[index];
          final animationIndex = index < 20 ? index : 0;
          final animationLength = _products.length < 20 ? _products.length : 20;

          return FadeTransition(
            opacity: CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (animationIndex / animationLength) * 0.5,
                ((animationIndex / animationLength) * 0.5) + 0.5,
                curve: Curves.easeOut,
              ),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (animationIndex / animationLength) * 0.5,
                  ((animationIndex / animationLength) * 0.5) + 0.5,
                  curve: Curves.easeOutCubic,
                ),
              )),
              child: ProductCard(
                producto: product,
                showActions: true,
                showStock: true,
                onEdit: () => _editProduct(product),
                onDelete: () => _deleteProduct(product),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          ).then((_) => _loadProducts());
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(
          Icons.add_rounded,
          color: Color(0xFF1A1A1A),
          size: 28,
        ),
      ),
    );
  }
}
