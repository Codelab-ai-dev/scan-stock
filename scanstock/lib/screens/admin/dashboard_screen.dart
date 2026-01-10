import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../services/sale_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SaleService _saleService = SaleService();

  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _salesByDay = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _saleService.getSalesSummary(),
        _saleService.getSalesByDay(_selectedDays),
        _saleService.getLowStockProducts(),
      ]);

      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _salesByDay = results[1] as List<Map<String, dynamic>>;
        _lowStockProducts = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppTheme.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKPICards(),
                              const SizedBox(height: 20),
                              _buildSalesChart(),
                              const SizedBox(height: 20),
                              _buildLowStockSection(),
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
          const Expanded(
            child: Text(
              'Dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.refresh,
                size: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    final today = _summary['today'] as Map<String, dynamic>? ?? {};
    final week = _summary['week'] as Map<String, dynamic>? ?? {};
    final month = _summary['month'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de Ventas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                title: 'Hoy',
                amount: (today['total'] as num?)?.toDouble() ?? 0,
                count: (today['count'] as int?) ?? 0,
                color: AppTheme.success,
                icon: Icons.today,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKPICard(
                title: 'Semana',
                amount: (week['total'] as num?)?.toDouble() ?? 0,
                count: (week['count'] as int?) ?? 0,
                color: AppTheme.info,
                icon: Icons.calendar_view_week,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKPICard(
                title: 'Mes',
                amount: (month['total'] as num?)?.toDouble() ?? 0,
                count: (month['count'] as int?) ?? 0,
                color: AppTheme.primary,
                icon: Icons.calendar_month,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required double amount,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '\$${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ventas',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ventas por Dia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              _buildDaysSelector(),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _salesByDay.isEmpty
                ? const Center(
                    child: Text(
                      'Sin datos',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppTheme.surfaceElevated,
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final data = _salesByDay[groupIndex];
                            return BarTooltipItem(
                              '\$${(data['total'] as double).toStringAsFixed(0)}\n${data['count']} ventas',
                              const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < _salesByDay.length) {
                                final date = _salesByDay[index]['date'] as String;
                                final parts = date.split('-');
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${parts[2]}/${parts[1]}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getMaxY() / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.border,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _buildBarGroups(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDayOption(7),
          _buildDayOption(15),
          _buildDayOption(30),
        ],
      ),
    );
  }

  Widget _buildDayOption(int days) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        if (_selectedDays != days) {
          setState(() => _selectedDays = days);
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${days}d',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF1A1A1A) : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  double _getMaxY() {
    if (_salesByDay.isEmpty) return 100;
    final maxTotal = _salesByDay.map((e) => (e['total'] as double)).reduce((a, b) => a > b ? a : b);
    return maxTotal <= 0 ? 100 : maxTotal * 1.2;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return _salesByDay.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final total = (data['total'] as double);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xFFFF9500),
                Color(0xFFFFB84D),
              ],
            ),
            width: _selectedDays > 15 ? 8 : 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildLowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Stock Bajo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (_lowStockProducts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_lowStockProducts.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warning,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lowStockProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.success, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Todos los productos tienen stock suficiente',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(
            _lowStockProducts.length > 5 ? 5 : _lowStockProducts.length,
            (index) => _buildLowStockItem(_lowStockProducts[index]),
          ),
        if (_lowStockProducts.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                '+${_lowStockProducts.length - 5} productos mas',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLowStockItem(Map<String, dynamic> product) {
    final stock = (product['stock_cantidad'] as int?) ?? 0;
    final minimo = (product['stock_minimo'] as int?) ?? 5;
    final isAgotado = stock <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAgotado
              ? AppTheme.error.withValues(alpha: 0.5)
              : AppTheme.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isAgotado ? AppTheme.error : AppTheme.warning).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isAgotado ? Icons.error_outline : Icons.warning_amber_rounded,
              color: isAgotado ? AppTheme.error : AppTheme.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['nombre'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product['codigo_barras'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isAgotado ? AppTheme.error : AppTheme.warning).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isAgotado ? 'AGOTADO' : '$stock uds',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAgotado ? AppTheme.error : AppTheme.warning,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Min: $minimo',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
