import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';
import '../../models/venta_item.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';
import '../../widgets/continuous_scanner_widget.dart';
import '../../widgets/sale_item_card.dart';

enum SaleScreenState { scanning, reviewing, payment, processing, success, error }

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final SaleService _saleService = SaleService();

  SaleScreenState _state = SaleScreenState.scanning;
  final List<VentaItem> _items = [];
  String? _errorMessage;
  String? _lastScannedProduct;

  // Payment state
  final TextEditingController _montoRecibidoController = TextEditingController();
  double _montoRecibido = 0;
  double get _cambio => _montoRecibido - _total;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _montoRecibidoController.dispose();
    super.dispose();
  }

  double get _total => _items.fold(0, (sum, item) => sum + item.subtotal);
  int get _totalItems => _items.fold(0, (sum, item) => sum + item.cantidad);

  void _onBarcodeScanned(String barcode) async {
    // Buscar si ya existe en la lista
    final existingIndex =
        _items.indexWhere((item) => item.productoCodigoBarras == barcode);

    if (existingIndex >= 0) {
      // Verificar stock disponible antes de incrementar
      final existing = _items[existingIndex];
      final stockDisponible = existing.producto?.stockCantidad ?? 0;
      final cantidadEnCarrito = existing.cantidad;

      if (cantidadEnCarrito >= stockDisponible) {
        _showStockInsuficienteDialog(existing.productoNombre, stockDisponible);
        return;
      }

      // Incrementar cantidad
      setState(() {
        _items[existingIndex] = existing.copyWith(cantidad: cantidadEnCarrito + 1);
        _lastScannedProduct = existing.productoNombre;
      });
      _showProductAddedFeedback(isIncrement: true, stockRestante: stockDisponible - cantidadEnCarrito - 1);
      return;
    }

    // Buscar producto en base de datos
    try {
      final producto = await _productService.getProductByBarcode(barcode);

      if (producto == null) {
        _showProductNotFoundDialog(barcode);
        return;
      }

      // Verificar si tiene stock disponible
      if (producto.stockCantidad <= 0) {
        _showStockInsuficienteDialog(producto.nombre, 0);
        return;
      }

      setState(() {
        _items.add(VentaItem.fromProducto(producto));
        _lastScannedProduct = producto.nombre;
      });
      _showProductAddedFeedback(isIncrement: false, stockRestante: producto.stockCantidad - 1);
    } catch (e) {
      _showErrorSnackbar('Error al buscar producto');
    }
  }

  void _showStockInsuficienteDialog(String nombreProducto, int stockDisponible) {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Stock insuficiente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nombreProducto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  stockDisponible == 0 ? 'AGOTADO' : 'Solo $stockDisponible disponible(s)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductAddedFeedback({required bool isIncrement, int? stockRestante}) {
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isIncrement ? Icons.add_circle : Icons.check_circle,
              color: AppTheme.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isIncrement
                    ? '+1 $_lastScannedProduct'
                    : 'Agregado: $_lastScannedProduct',
                style: const TextStyle(color: AppTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (stockRestante != null && stockRestante <= 5)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: stockRestante <= 0
                      ? AppTheme.error.withValues(alpha: 0.2)
                      : AppTheme.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Stock: $stockRestante',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: stockRestante <= 0 ? AppTheme.error : AppTheme.warning,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        margin: const EdgeInsets.only(bottom: 130, left: 16, right: 16),
      ),
    );
  }

  void _showProductNotFoundDialog(String barcode) {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off,
                  color: AppTheme.warning,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Producto no encontrado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  barcode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continuar escaneando'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  void _incrementItem(int index) {
    final item = _items[index];
    final stockDisponible = item.producto?.stockCantidad ?? 0;

    if (item.cantidad >= stockDisponible) {
      _showStockInsuficienteDialog(item.productoNombre, stockDisponible);
      return;
    }

    setState(() {
      _items[index] = item.copyWith(cantidad: item.cantidad + 1);
    });
    HapticFeedback.lightImpact();
  }

  void _decrementItem(int index) {
    setState(() {
      final item = _items[index];
      if (item.cantidad > 1) {
        _items[index] = item.copyWith(cantidad: item.cantidad - 1);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    HapticFeedback.mediumImpact();
  }

  void _switchToReview() {
    if (_items.isEmpty) {
      _showErrorSnackbar('Agrega al menos un producto');
      return;
    }
    setState(() {
      _state = SaleScreenState.reviewing;
    });
    _animationController.forward(from: 0);
  }

  void _switchToScanning() {
    setState(() {
      _state = SaleScreenState.scanning;
    });
  }

  void _switchToPayment() {
    setState(() {
      _state = SaleScreenState.payment;
      _montoRecibido = 0;
      _montoRecibidoController.clear();
    });
    _animationController.forward(from: 0);
  }

  void _switchToReviewFromPayment() {
    setState(() {
      _state = SaleScreenState.reviewing;
    });
  }

  void _processPayment() async {
    if (_montoRecibido < _total) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('El monto recibido es menor al total'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _state = SaleScreenState.processing;
    });

    try {
      await _saleService.createSale(_items);

      setState(() {
        _state = SaleScreenState.success;
      });

      HapticFeedback.heavyImpact();

      // Esperar y volver
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _state = SaleScreenState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _showCancelDialog() {
    if (_items.isEmpty) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppTheme.warning,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cancelar venta?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Perderas todos los productos escaneados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Continuar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _items.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case SaleScreenState.scanning:
        return _buildScanningState();
      case SaleScreenState.reviewing:
        return _buildReviewingState();
      case SaleScreenState.payment:
        return _buildPaymentState();
      case SaleScreenState.processing:
        return _buildProcessingState();
      case SaleScreenState.success:
        return _buildSuccessState();
      case SaleScreenState.error:
        return _buildErrorState();
    }
  }

  Widget _buildScanningState() {
    return Stack(
      children: [
        ContinuousScannerWidget(
          onBarcodeDetected: _onBarcodeScanned,
          onClose: () => _showCancelDialog(),
          itemCount: _totalItems,
          totalAmount: _total,
        ),
        // Boton para revisar venta
        if (_items.isNotEmpty)
          Positioned(
            bottom: 155,
            left: 16,
            right: 16,
            child: GradientActionButton(
              label: 'Revisar venta (${_items.length})',
              icon: Icons.shopping_cart_checkout,
              onPressed: _switchToReview,
            ),
          ),
      ],
    );
  }

  Widget _buildReviewingState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
      child: SafeArea(
        child: Column(
          children: [
            _buildReviewHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return SaleItemCard(
                      item: _items[index],
                      onIncrement: () => _incrementItem(index),
                      onDecrement: () => _decrementItem(index),
                      onRemove: () => _removeItem(index),
                    );
                  },
                ),
              ),
            ),
            _buildTotalSection(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _switchToScanning,
            child: Container(
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
              'Revisar Venta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_totalItems items',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Text(
            '\$${_total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _switchToScanning,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Seguir escaneando', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _switchToPayment,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Cobrar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _switchToReviewFromPayment,
                    child: Container(
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
                      'Cobrar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Total a cobrar
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL A COBRAR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              '$_totalItems productos',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Monto recibido
                      const Text(
                        'Efectivo recibido',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: TextField(
                          controller: _montoRecibidoController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '\$0.00',
                            hintStyle: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Text(
                                '\$',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _montoRecibido = double.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botones de monto rápido
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickAmountButton(_total),
                          _buildQuickAmountButton((_total / 10).ceil() * 10.0),
                          _buildQuickAmountButton((_total / 50).ceil() * 50.0),
                          _buildQuickAmountButton((_total / 100).ceil() * 100.0),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Cambio
                      if (_montoRecibido > 0)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _cambio >= 0
                                ? AppTheme.success.withValues(alpha: 0.1)
                                : AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _cambio >= 0
                                  ? AppTheme.success.withValues(alpha: 0.3)
                                  : AppTheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _cambio >= 0 ? 'CAMBIO' : 'FALTA',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _cambio >= 0 ? AppTheme.success : AppTheme.error,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${_cambio.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: _cambio >= 0 ? AppTheme.success : AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Botón de confirmar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: ElevatedButton.icon(
                onPressed: _montoRecibido >= _total ? _processPayment : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmar Venta'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    final isExact = amount == _total;
    return GestureDetector(
      onTap: () {
        setState(() {
          _montoRecibido = amount;
          _montoRecibidoController.text = amount.toStringAsFixed(2);
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isExact ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExact ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border,
          ),
        ),
        child: Text(
          isExact ? 'Exacto' : '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isExact ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
            SizedBox(height: 24),
            Text(
              'Procesando venta...',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Venta registrada!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: \$${_total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.success,
              ),
            ),
            if (_cambio > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CAMBIO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_cambio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppTheme.error,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Error al guardar la venta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _state = SaleScreenState.reviewing;
                    _errorMessage = null;
                  });
                },
                child: const Text('Intentar de nuevo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
