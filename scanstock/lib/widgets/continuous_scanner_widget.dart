import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/app_theme.dart';

class ContinuousScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeDetected;
  final VoidCallback? onClose;
  final int itemCount;
  final double totalAmount;

  const ContinuousScannerWidget({
    super.key,
    required this.onBarcodeDetected,
    this.onClose,
    this.itemCount = 0,
    this.totalAmount = 0.0,
  });

  @override
  State<ContinuousScannerWidget> createState() => _ContinuousScannerWidgetState();
}

class _ContinuousScannerWidgetState extends State<ContinuousScannerWidget> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const _scanCooldown = Duration(milliseconds: 1500);

  // Dimensiones del area de escaneo
  static const double _scanAreaWidth = 280;
  static const double _scanAreaHeight = 140;
  static const double _borderRadius = 12;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    final now = DateTime.now();

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        final code = barcode.rawValue!;

        // Evitar escaneos duplicados muy rapidos del mismo codigo
        if (_lastScannedCode == code &&
            _lastScanTime != null &&
            now.difference(_lastScanTime!) < _scanCooldown) {
          return;
        }

        _lastScannedCode = code;
        _lastScanTime = now;

        // Feedback haptico
        HapticFeedback.mediumImpact();

        widget.onBarcodeDetected(code);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camara
        MobileScanner(
          controller: _controller,
          onDetect: _handleBarcode,
        ),
        // Overlay oscuro con hueco para escaneo
        _buildScanOverlay(context),
        // Controles superiores
        _buildTopControls(),
        // Texto instruccional
        _buildInstructionText(),
        // Panel inferior con info de venta
        _buildSaleInfo(),
      ],
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Centrar el area de escaneo un poco mas arriba para dejar espacio al panel inferior
        final centerX = (screenWidth - _scanAreaWidth) / 2;
        final centerY = (screenHeight - _scanAreaHeight) / 2 - 60;

        return Stack(
          children: [
            // Overlay oscuro con hueco transparente
            CustomPaint(
              size: Size(screenWidth, screenHeight),
              painter: _ScanOverlayPainter(
                scanRect: Rect.fromLTWH(
                  centerX,
                  centerY,
                  _scanAreaWidth,
                  _scanAreaHeight,
                ),
                borderRadius: _borderRadius,
                overlayColor: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            // Marco naranja exactamente sobre el hueco
            Positioned(
              left: centerX - 2,
              top: centerY - 2,
              child: Container(
                width: _scanAreaWidth + 4,
                height: _scanAreaHeight + 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_borderRadius + 2),
                  border: Border.all(
                    color: AppTheme.primary,
                    width: 3,
                  ),
                ),
              ),
            ),
            // Esquinas decorativas
            ..._buildCornerDecorations(centerX, centerY),
          ],
        );
      },
    );
  }

  List<Widget> _buildCornerDecorations(double left, double top) {
    const cornerSize = 20.0;
    const cornerWidth = 4.0;

    return [
      // Esquina superior izquierda
      Positioned(
        left: left - 2,
        top: top - 2,
        child: _buildCorner(cornerSize, cornerWidth, true, true),
      ),
      // Esquina superior derecha
      Positioned(
        right: (MediaQuery.of(context).size.width - left - _scanAreaWidth) - 2,
        top: top - 2,
        child: _buildCorner(cornerSize, cornerWidth, true, false),
      ),
      // Esquina inferior izquierda
      Positioned(
        left: left - 2,
        bottom: (MediaQuery.of(context).size.height - top - _scanAreaHeight) - 2,
        child: _buildCorner(cornerSize, cornerWidth, false, true),
      ),
      // Esquina inferior derecha
      Positioned(
        right: (MediaQuery.of(context).size.width - left - _scanAreaWidth) - 2,
        bottom: (MediaQuery.of(context).size.height - top - _scanAreaHeight) - 2,
        child: _buildCorner(cornerSize, cornerWidth, false, false),
      ),
    ];
  }

  Widget _buildCorner(double size, double width, bool isTop, bool isLeft) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: AppTheme.primary,
          strokeWidth: width,
          isTop: isTop,
          isLeft: isLeft,
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.onClose != null)
              _buildControlButton(
                icon: Icons.close,
                onPressed: widget.onClose!,
              )
            else
              const SizedBox(width: 48),
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return _buildControlButton(
                  icon: state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                  onPressed: () => _controller.toggleTorch(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildInstructionText() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 160,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Escanea productos continuamente',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaleInfo() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.primary, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                icon: Icons.shopping_cart_rounded,
                label: 'Items',
                value: '${widget.itemCount}',
                color: AppTheme.info,
              ),
              Container(
                height: 50,
                width: 1,
                color: AppTheme.border,
              ),
              _buildInfoChip(
                icon: Icons.attach_money_rounded,
                label: 'Total',
                value: '\$${widget.totalAmount.toStringAsFixed(2)}',
                color: AppTheme.success,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Painter para el overlay oscuro con hueco transparente
class _ScanOverlayPainter extends CustomPainter {
  final Rect scanRect;
  final double borderRadius;
  final Color overlayColor;

  _ScanOverlayPainter({
    required this.scanRect,
    required this.borderRadius,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // Dibujar overlay completo
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Crear path con hueco
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(
        RRect.fromRectAndRadius(scanRect, Radius.circular(borderRadius)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return scanRect != oldDelegate.scanRect ||
        borderRadius != oldDelegate.borderRadius ||
        overlayColor != oldDelegate.overlayColor;
  }
}

/// Painter para las esquinas decorativas
class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isTop;
  final bool isLeft;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.isTop,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        isTop != oldDelegate.isTop ||
        isLeft != oldDelegate.isLeft;
  }
}
