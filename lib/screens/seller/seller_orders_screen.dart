import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../domain/order_workflow.dart';
import '../../models/order.dart';
import '../../state/orders_provider.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();

    if (ordersProvider.isLoading) {
      return DulceWidgets.loadingState();
    }
    if (ordersProvider.orders.isEmpty) {
      return DulceWidgets.emptyState(
        'Aún no hay pedidos.\n¡Cuando lleguen aparecerán aquí!',
        icon: Icons.receipt_long_outlined,
      );
    }

    return RefreshIndicator(
      color: DulceColors.rose,
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: ordersProvider.orders.length,
        itemBuilder: (context, index) {
          final order = ordersProvider.orders[index];
          return _SellerOrderCard(order: order, index: index);
        },
      ),
    );
  }
}

class _SellerOrderCard extends StatefulWidget {
  final CakeOrder order;
  final int index;

  const _SellerOrderCard({required this.order, required this.index});

  @override
  State<_SellerOrderCard> createState() => _SellerOrderCardState();
}

class _SellerOrderCardState extends State<_SellerOrderCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 60),
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
    final nextStatuses = sellerNextOrderStatuses(order.status);
    final canAdvance = order.isPaid && nextStatuses.isNotEmpty;
    final isCancelled = order.status == 'cancelled';
    final isDelivered = order.status == 'delivered';

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(
              color: _leftBorderColor(order.status),
              width: 5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: DulceColors.chocolate.withOpacity(0.07),
              blurRadius: 14,
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
                child: Row(
                  children: [
                    // Ícono de estado
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _leftBorderColor(order.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _statusIcon(order.status),
                        color: _leftBorderColor(order.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pedido #${order.id}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: DulceColors.chocolateDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              DulceWidgets.statusChip(order.status),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${order.total.toStringAsFixed(2)} · '
                            '${order.isPaid ? '✓ Pagado' : '⏳ Sin pagar'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: order.isPaid
                                  ? DulceColors.success
                                  : DulceColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: DulceColors.chocolateLight,
                    ),
                  ],
                ),
              ),
            ),

            // Detalle expandible
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

                    // Dirección de entrega
                    if (order.deliveryAddress.isNotEmpty)
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        text: order.deliveryAddress,
                      ),

                    // Notas
                    if (order.notes.isNotEmpty)
                      _DetailRow(
                        icon: Icons.sticky_note_2_outlined,
                        text: order.notes,
                      ),

                    const SizedBox(height: 8),

                    // Items del pedido
                    if (order.items.isNotEmpty) ...[
                      Text(
                        'Productos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DulceColors.chocolateLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...order.items.map((item) => _ItemRow(item: item)),
                      const SizedBox(height: 8),
                    ],

                    // Acciones
                    if (!isCancelled && !isDelivered) ...[
                      if (!order.isPaid)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DulceColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: DulceColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_bottom_rounded,
                                  size: 16, color: DulceColors.warning),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Esperando confirmación de pago del cliente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: DulceColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (canAdvance)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: nextStatuses.map((entry) {
                            return _AdvanceButton(
                              label: entry.value,
                              onPressed: () =>
                                  _advance(context, order, entry.key),
                            );
                          }).toList(),
                        ),
                    ],

                    if (isDelivered)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: DulceColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.done_all_rounded,
                                size: 16, color: DulceColors.success),
                            SizedBox(width: 8),
                            Text(
                              'Pedido entregado con éxito',
                              style: TextStyle(
                                fontSize: 12,
                                color: DulceColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

  Future<void> _advance(
      BuildContext context, CakeOrder order, String targetStatus) async {
    final ok = await context.read<OrdersProvider>().advanceStatus(order, targetStatus);
    if (context.mounted) {
      if (ok) {
        DulceWidgets.showSuccess(
            context, 'Estado actualizado: ${statusLabel(targetStatus)}');
      } else {
        DulceWidgets.showError(context, 'No se pudo actualizar el estado');
      }
    }
  }

  Color _leftBorderColor(String status) {
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
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: DulceColors.chocolateLight),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: DulceColors.chocolateLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final details = [
      if (item.size.isNotEmpty) item.size,
      if (item.shape.isNotEmpty) item.shape,
      if (item.flavor.isNotEmpty) item.flavor,
      if (item.color.isNotEmpty) item.color,
    ].join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DulceColors.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: DulceColors.chocolate,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'x${item.quantity}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 12,
                      color: DulceColors.chocolateDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (item.ingredients.isNotEmpty)
                  Text(
                    item.ingredients,
                    style: TextStyle(
                      fontSize: 11,
                      color: DulceColors.chocolateLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '\$${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DulceColors.chocolateDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvanceButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _AdvanceButton({required this.label, required this.onPressed});

  @override
  State<_AdvanceButton> createState() => _AdvanceButtonState();
}

class _AdvanceButtonState extends State<_AdvanceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: DulceColors.gradientPrimary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: DulceColors.chocolate.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
