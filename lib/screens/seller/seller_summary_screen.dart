import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../domain/order_workflow.dart';
import '../../services/order_service.dart';
import '../../state/orders_provider.dart';

class SellerSummaryScreen extends StatefulWidget {
  const SellerSummaryScreen({super.key});

  @override
  State<SellerSummaryScreen> createState() => _SellerSummaryScreenState();
}

class _SellerSummaryScreenState extends State<SellerSummaryScreen> {
  String _period = 'day';
  AdminOrderSummary? _summary;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final summary = await context.read<OrdersProvider>().summary(_period);
    if (mounted) {
      setState(() {
        _summary = summary;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<OrdersProvider>(); // refresca al cambiar pedidos

    return RefreshIndicator(
      color: DulceColors.rose,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Selector de período
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: DulceColors.chocolate.withOpacity(0.06),
                  blurRadius: 8,
                )
              ],
            ),
            child: Row(
              children: [
                _PeriodTab(
                  label: 'Hoy',
                  icon: Icons.today_rounded,
                  value: 'day',
                  selected: _period == 'day',
                  onTap: () => _changePeriod('day'),
                ),
                _PeriodTab(
                  label: 'Semana',
                  icon: Icons.date_range_rounded,
                  value: 'week',
                  selected: _period == 'week',
                  onTap: () => _changePeriod('week'),
                ),
                _PeriodTab(
                  label: 'Mes',
                  icon: Icons.calendar_month_rounded,
                  value: 'month',
                  selected: _period == 'month',
                  onTap: () => _changePeriod('month'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_loading)
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: DulceColors.rose),
              ),
            )
          else if (_summary != null) ...[
            // Tarjeta principal de ventas
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: DulceColors.gradientPrimary,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: DulceColors.chocolateDark.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.attach_money_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ventas totales',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _periodLabel(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '\$${_summary!.totalSales.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_summary!.totalOrders} pedidos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Métricas secundarias
            if (_summary!.totalOrders > 0) ...[
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.shopping_basket_rounded,
                      label: 'Ticket promedio',
                      value:
                          '\$${(_summary!.totalSales / _summary!.totalOrders).toStringAsFixed(2)}',
                      color: DulceColors.rose,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'Pedidos',
                      value: '${_summary!.totalOrders}',
                      color: DulceColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Desglose por estado
            if (_summary!.statusBreakdown.isNotEmpty) ...[
              Text(
                'Desglose por estado',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: DulceColors.chocolateDark,
                ),
              ),
              const SizedBox(height: 12),
              ...(_summary!.statusBreakdown.map((entry) {
                final maxCount = _summary!.statusBreakdown
                    .map((e) => e.value)
                    .reduce((a, b) => a > b ? a : b);
                final ratio =
                    maxCount > 0 ? entry.value / maxCount : 0.0;
                return _StatusBar(
                  status: entry.key,
                  count: entry.value,
                  ratio: ratio,
                );
              })),
            ],

            if (_summary!.totalOrders == 0) ...[
              const SizedBox(height: 20),
              DulceWidgets.emptyState(
                'Sin pedidos en este período',
                icon: Icons.inbox_outlined,
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _changePeriod(String period) {
    setState(() => _period = period);
    _load();
  }

  String _periodLabel() {
    switch (_period) {
      case 'week':
        return 'Esta semana';
      case 'month':
        return 'Este mes';
      default:
        return 'Hoy';
    }
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? DulceColors.gradientPrimary : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : DulceColors.chocolateLight,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : DulceColors.chocolateLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DulceColors.chocolate.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: DulceColors.chocolateDark,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: DulceColors.chocolateLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String status;
  final int count;
  final double ratio;

  const _StatusBar({
    required this.status,
    required this.count,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final label = statusLabel(status);
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DulceColors.chocolate.withOpacity(0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DulceColors.chocolateDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'created':
        return DulceColors.info;
      case 'in_oven':
        return DulceColors.warning;
      case 'decorating':
        return const Color(0xFF9C27B0);
      case 'on_the_way':
        return const Color(0xFF0288D1);
      case 'delivered':
        return DulceColors.success;
      case 'cancelled':
        return DulceColors.error;
      default:
        return DulceColors.chocolateLight;
    }
  }
}
