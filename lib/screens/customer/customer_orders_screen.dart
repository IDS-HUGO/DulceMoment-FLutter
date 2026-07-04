import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../domain/order_workflow.dart';
import '../../models/order.dart';
import '../../state/orders_provider.dart';
import 'payment_screen.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();

    if (ordersProvider.isLoading) {
      return DulceWidgets.loadingState();
    }
    if (ordersProvider.orders.isEmpty) {
      return DulceWidgets.emptyState(
        'Todavía no tienes pedidos.\n¡Explora el catálogo y pide tu pastel!',
        icon: Icons.receipt_long_outlined,
      );
    }

    return RefreshIndicator(
      color: DulceColors.rose,
      onRefresh: () async {
        // El stream se actualiza solo; esto solo fuerza scroll
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: ordersProvider.orders.length,
        itemBuilder: (context, index) {
          final order = ordersProvider.orders[index];
          return _OrderCard(order: order, index: index);
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final CakeOrder order;
  final int index;

  const _OrderCard({required this.order, required this.index});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 50),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final needsPayment = orderRequiresPayment(order.status, order.isPaid);
    final isCancelled = order.status == 'cancelled';
    final isDelivered = order.status == 'delivered';

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCancelled
                ? DulceColors.error.withOpacity(0.3)
                : isDelivered
                    ? DulceColors.success.withOpacity(0.3)
                    : needsPayment
                        ? DulceColors.warning.withOpacity(0.4)
                        : DulceColors.sand.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: DulceColors.chocolate.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Cabecera
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Ícono de estado
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _statusColor(order.status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _statusIcon(order.status),
                            color: _statusColor(order.status),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pedido #${order.id}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: DulceColors.chocolateDark,
                                ),
                              ),
                              Text(
                                _formatDate(order.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: DulceColors.chocolateLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DulceWidgets.statusChip(order.status),
                        const SizedBox(width: 8),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: DulceColors.chocolateLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.attach_money_rounded,
                            label: '\$${order.total.toStringAsFixed(2)}',
                            color: DulceColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoChip(
                            icon: order.isPaid
                                ? Icons.check_circle_rounded
                                : Icons.pending_rounded,
                            label: order.isPaid ? 'Pagado' : 'Sin pagar',
                            color: order.isPaid
                                ? DulceColors.success
                                : DulceColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Contenido expandible
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    // Dirección
                    if (order.deliveryAddress.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: DulceColors.chocolateLight),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: TextStyle(
                                  fontSize: 13, color: DulceColors.chocolateLight),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Timeline de eventos
                    if (order.events.isNotEmpty) ...[
                      Text(
                        'Seguimiento',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: DulceColors.chocolateDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.events.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        final isLast = i == order.events.length - 1;
                        return _TimelineItem(
                          event: e,
                          isLast: isLast,
                          isActive: isLast,
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                    // Botones de acción
                    if (needsPayment)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.payment_rounded, size: 18),
                          label: const Text('Pagar pedido'),
                          style: FilledButton.styleFrom(
                            backgroundColor: DulceColors.rose,
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    PaymentScreen(order: order)),
                          ),
                        ),
                      )
                    else if (!isDelivered && !isCancelled)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancelar pedido'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DulceColors.error,
                            side: const BorderSide(color: DulceColors.error),
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _confirmCancel(context, order.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar pedido',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            '¿Estás seguro de que quieres cancelar este pedido? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, mantener'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DulceColors.error,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await context.read<OrdersProvider>().cancelOrder(orderId);
      if (context.mounted) {
        if (ok) {
          DulceWidgets.showInfo(context, 'Pedido cancelado');
        } else {
          DulceWidgets.showError(context, 'No se pudo cancelar el pedido');
        }
      }
    }
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'created':
        return Icons.check_circle_outline_rounded;
      case 'in_oven':
        return Icons.local_fire_department_rounded;
      case 'decorating':
        return Icons.brush_rounded;
      case 'on_the_way':
        return Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TrackingEvent event;
  final bool isLast;
  final bool isActive;

  const _TimelineItem({
    required this.event,
    required this.isLast,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? DulceColors.rose : DulceColors.sand,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: DulceColors.rose.withOpacity(0.4),
                              blurRadius: 4,
                            )
                          ]
                        : [],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: DulceColors.sand,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? DulceColors.chocolateDark
                          : DulceColors.chocolateLight,
                    ),
                  ),
                  if (event.etaMinutes > 0)
                    Text(
                      'ETA: ${event.etaMinutes} min',
                      style: TextStyle(
                        fontSize: 11,
                        color: DulceColors.chocolateLight.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
