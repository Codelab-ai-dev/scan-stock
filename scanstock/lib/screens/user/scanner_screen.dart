import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/producto.dart';
import '../../services/product_service.dart';
import '../../widgets/barcode_scanner_widget.dart';
import '../../widgets/product_card.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();

  bool _isScanning = true;
  bool _isLoading = false;
  Producto? _foundProduct;
  String? _scannedBarcode;
  bool _productNotFound = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(String barcode) async {
    setState(() {
      _isScanning = false;
      _isLoading = true;
      _scannedBarcode = barcode;
      _foundProduct = null;
      _productNotFound = false;
    });

    try {
      final product = await _productService.getProductByBarcode(barcode);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (product != null) {
            _foundProduct = product;
          } else {
            _productNotFound = true;
          }
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _productNotFound = true;
        });
        _animationController.forward(from: 0);
      }
    }
  }

  void _scanAgain() {
    setState(() {
      _isScanning = true;
      _foundProduct = null;
      _scannedBarcode = null;
      _productNotFound = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        body: BarcodeScannerWidget(
          onBarcodeDetected: _onBarcodeDetected,
          onClose: () => Navigator.pop(context),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildContent(),
              ),
              _buildScanAgainButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Resultado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Buscando producto...',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            if (_scannedBarcode != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _scannedBarcode!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppTheme.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (_foundProduct != null) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          )),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildSuccessBadge(),
                ProductDetailCard(producto: _foundProduct!),
              ],
            ),
          ),
        ),
      );
    }

    if (_productNotFound) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Producto no encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No existe un producto con el codigo:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.qr_code_rounded,
                        color: AppTheme.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _scannedBarcode ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.info,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Contacta al administrador para\nagregar este producto.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Center(
      child: Text(
        'Escanea un codigo de barras',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.success,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Producto encontrado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanAgainButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GradientActionButton(
        label: 'Escanear otro producto',
        icon: Icons.qr_code_scanner_rounded,
        onPressed: _scanAgain,
      ),
    );
  }
}
