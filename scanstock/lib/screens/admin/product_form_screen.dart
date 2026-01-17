import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';
import '../../models/producto.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/camera_capture_widget.dart';
import '../../widgets/barcode_scanner_widget.dart';
import '../../utils/validators.dart';
import '../../utils/feedback.dart' as app_feedback;

class ProductFormScreen extends StatefulWidget {
  final Producto? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _storageService = StorageService();

  final _barcodeController = TextEditingController();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockCantidadController = TextEditingController();
  final _stockMinimoController = TextEditingController();

  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isScanning = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _barcodeController.text = widget.product!.codigoBarras;
      _nombreController.text = widget.product!.nombre;
      _descripcionController.text = widget.product!.descripcion ?? '';
      _precioController.text = widget.product!.precio.toStringAsFixed(2);
      _stockCantidadController.text = widget.product!.stockCantidad.toString();
      _stockMinimoController.text = widget.product!.stockMinimo.toString();
      _existingImageUrl = widget.product!.imagenUrl;
    } else {
      _stockCantidadController.text = '0';
      _stockMinimoController.text = '5';
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockCantidadController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(String barcode) {
    setState(() {
      _barcodeController.text = barcode;
      _isScanning = false;
    });
  }

  void _showScanner() {
    setState(() {
      _isScanning = true;
    });
  }

  void _onImageCaptured(File file) {
    setState(() {
      _imageFile = file;
    });
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final barcodeExists = await _productService.barcodeExists(
        _barcodeController.text,
        excludeId: widget.product?.id,
      );

      if (barcodeExists) {
        if (mounted) {
          app_feedback.Feedback.warning(
            context,
            'Ya existe un producto con este código de barras',
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      String? imageUrl = _existingImageUrl;

      if (_imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_barcodeController.text}';
        imageUrl = await _storageService.uploadProductImage(_imageFile!, fileName);
      }

      final producto = Producto(
        id: widget.product?.id,
        codigoBarras: _barcodeController.text.trim(),
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        precio: double.parse(_precioController.text),
        imagenUrl: imageUrl,
        stockCantidad: int.tryParse(_stockCantidadController.text) ?? 0,
        stockMinimo: int.tryParse(_stockMinimoController.text) ?? 5,
      );

      if (isEditing) {
        await _productService.updateProduct(producto);
      } else {
        await _productService.createProduct(producto);
      }

      if (mounted) {
        app_feedback.Feedback.success(
          context,
          isEditing
              ? 'Producto actualizado correctamente'
              : 'Producto creado correctamente',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        app_feedback.Feedback.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        body: BarcodeScannerWidget(
          onBarcodeDetected: _onBarcodeDetected,
          onClose: () {
            setState(() {
              _isScanning = false;
            });
          },
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImageSection(),
                        const SizedBox(height: 20),
                        _buildBarcodeField(),
                        const SizedBox(height: 14),
                        _buildNameField(),
                        const SizedBox(height: 14),
                        _buildDescriptionField(),
                        const SizedBox(height: 14),
                        _buildPriceField(),
                        const SizedBox(height: 14),
                        _buildStockFields(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
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
          Expanded(
            child: Text(
              isEditing ? 'Editar Producto' : 'Nuevo Producto',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  Widget _buildImageSection() {
    return IndustrialCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.image_rounded,
                  color: AppTheme.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'IMAGEN DEL PRODUCTO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CameraCaptureWidget(
            imageFile: _imageFile,
            imageUrl: _existingImageUrl,
            onImageCaptured: _onImageCaptured,
            onImageRemoved: (_imageFile != null || _existingImageUrl != null)
                ? _removeImage
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _barcodeController,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontFamily: 'monospace',
              fontSize: 14,
              letterSpacing: 1,
            ),
            decoration: const InputDecoration(
              labelText: 'Codigo de barras',
              hintText: 'Ej: 7501234567890',
              prefixIcon: Icon(Icons.qr_code),
            ),
            validator: (value) => Validators.required(value, 'El código de barras'),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showScanner,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF1A1A1A),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nombreController,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 14,
      ),
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Nombre del producto',
        hintText: 'Ej: Coca Cola 600ml',
        prefixIcon: Icon(Icons.inventory_2_outlined),
      ),
      validator: (value) => Validators.required(value, 'El nombre'),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descripcionController,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 14,
      ),
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Descripcion (opcional)',
        hintText: 'Descripcion del producto...',
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: Icon(Icons.description_outlined),
        ),
      ),
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _precioController,
      style: const TextStyle(
        color: AppTheme.success,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Precio',
        hintText: '0.00',
        hintStyle: TextStyle(color: AppTheme.success.withValues(alpha: 0.5)),
        prefixIcon: const Icon(Icons.attach_money, color: AppTheme.success),
      ),
      validator: Validators.price,
    );
  }

  Widget _buildStockFields() {
    return IndustrialCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.inventory_rounded,
                  color: AppTheme.info,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'CONTROL DE INVENTARIO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stockCantidadController,
                  style: const TextStyle(
                    color: AppTheme.info,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Stock actual',
                    hintText: '0',
                    prefixIcon: Icon(Icons.inventory_2_outlined, color: AppTheme.info),
                  ),
                  validator: Validators.stock,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stockMinimoController,
                  style: const TextStyle(
                    color: AppTheme.warning,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Stock minimo',
                    hintText: '5',
                    prefixIcon: Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                  ),
                  validator: Validators.stock,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Se mostrara alerta cuando el stock sea menor o igual al minimo',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GradientActionButton(
      label: isEditing ? 'Actualizar Producto' : 'Guardar Producto',
      icon: isEditing ? Icons.save_rounded : Icons.add_rounded,
      isLoading: _isLoading,
      onPressed: _isLoading ? null : _saveProduct,
    );
  }
}
