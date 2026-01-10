import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/producto.dart';

class ProductCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showStock;

  const ProductCard({
    super.key,
    required this.producto,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.showStock = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildImage(),
                const SizedBox(width: 14),
                Expanded(child: _buildInfo()),
                if (showActions) _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: producto.imagenUrlAccesible != null && producto.imagenUrlAccesible!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: producto.imagenUrlAccesible!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.surfaceLight,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceLight,
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: AppTheme.textMuted,
                    size: 24,
                  ),
                ),
              )
            : Container(
                color: AppTheme.surfaceLight,
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppTheme.textMuted,
                  size: 28,
                ),
              ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          producto.nombre,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            producto.codigoBarras,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (producto.descripcion != null && producto.descripcion!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              producto.descripcion!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: Text(
                producto.precioFormateado,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                ),
              ),
            ),
            if (showStock) ...[
              const SizedBox(width: 8),
              _buildStockBadge(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStockBadge() {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (producto.estadoStock) {
      case 'agotado':
        badgeColor = AppTheme.error;
        badgeIcon = Icons.error_outline;
        badgeText = 'Agotado';
        break;
      case 'bajo':
        badgeColor = AppTheme.warning;
        badgeIcon = Icons.warning_amber_rounded;
        badgeText = '${producto.stockCantidad}';
        break;
      default:
        badgeColor = AppTheme.info;
        badgeIcon = Icons.inventory_2_outlined;
        badgeText = '${producto.stockCantidad}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          _buildActionButton(
            icon: Icons.edit_rounded,
            color: AppTheme.info,
            onTap: onEdit!,
            tooltip: 'Editar',
          ),
        if (onEdit != null && onDelete != null) const SizedBox(height: 8),
        if (onDelete != null)
          _buildActionButton(
            icon: Icons.delete_rounded,
            color: AppTheme.error,
            onTap: onDelete!,
            tooltip: 'Eliminar',
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class ProductDetailCard extends StatelessWidget {
  final Producto producto;

  const ProductDetailCard({
    super.key,
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImage(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.qr_code_rounded,
                  label: 'Codigo',
                  value: producto.codigoBarras,
                  isCode: true,
                ),
                const SizedBox(height: 14),
                _buildPriceRow(),
                const SizedBox(height: 14),
                _buildStockRow(),
                if (producto.descripcion != null &&
                    producto.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const GradientDivider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: AppTheme.primary,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'DESCRIPCION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    producto.descripcion!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
        border: Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            producto.imagenUrlAccesible != null && producto.imagenUrlAccesible!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: producto.imagenUrlAccesible!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.surfaceLight,
                      child: const Icon(
                        Icons.error_rounded,
                        size: 40,
                        color: AppTheme.error,
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.surfaceLight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceElevated,
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            size: 40,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Sin imagen',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 70,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.surface.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isCode = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: isCode
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withValues(alpha: 0.1),
            AppTheme.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.attach_money_rounded,
              size: 22,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PRECIO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                producto.precioFormateado,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockRow() {
    Color stockColor;
    IconData stockIcon;
    String stockLabel;

    switch (producto.estadoStock) {
      case 'agotado':
        stockColor = AppTheme.error;
        stockIcon = Icons.error_outline;
        stockLabel = 'AGOTADO';
        break;
      case 'bajo':
        stockColor = AppTheme.warning;
        stockIcon = Icons.warning_amber_rounded;
        stockLabel = 'STOCK BAJO';
        break;
      default:
        stockColor = AppTheme.info;
        stockIcon = Icons.inventory_2_outlined;
        stockLabel = 'EN STOCK';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stockColor.withValues(alpha: 0.1),
            stockColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stockColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              stockIcon,
              size: 22,
              color: stockColor,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stockLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${producto.stockCantidad} unidades',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: stockColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'Min',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${producto.stockMinimo}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
