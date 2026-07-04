import '../core/supabase_config.dart';
import '../domain/order_workflow.dart';
import '../models/order.dart';

class OrderItemDraft {
  final int productId;
  final int quantity;
  final double unitPrice;
  final String ingredients;
  final String size;
  final String shape;
  final String flavor;
  final String color;

  const OrderItemDraft({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.ingredients = '',
    this.size = '',
    this.shape = '',
    this.flavor = '',
    this.color = '',
  });

  double get subtotal => unitPrice * quantity;
}

class OrderService {
  static const _selectWithDetails =
      '*, order_items(*), tracking_events(*), payments(*)';

  Future<List<CakeOrder>> fetchOrdersForCustomer(String customerId) async {
    final rows = await supabase
        .from('orders')
        .select(_selectWithDetails)
        .eq('customer_id', customerId)
        .order('id', ascending: false);
    return (rows as List).map((e) => CakeOrder.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<CakeOrder>> fetchAllOrdersForStore() async {
    final rows = await supabase
        .from('orders')
        .select(_selectWithDetails)
        .order('id', ascending: false);
    return (rows as List).map((e) => CakeOrder.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// Stream en vivo (Supabase Realtime) de la tabla orders; cuando cambia algo
  /// se vuelve a pedir el detalle completo con sus relaciones.
  Stream<List<CakeOrder>> watchOrders({String? customerId}) {
    final base = supabase.from('orders').stream(primaryKey: ['id']).order('id', ascending: false);
    return base.asyncMap((_) {
      return customerId != null ? fetchOrdersForCustomer(customerId) : fetchAllOrdersForStore();
    });
  }

  Future<int> createOrder({
    required String customerId,
    required String address,
    required String notes,
    required List<OrderItemDraft> items,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('El pedido debe tener al menos un producto');
    }
    if (items.any((item) => item.quantity <= 0)) {
      throw ArgumentError('Cantidad inválida');
    }
    if (address.trim().isEmpty) {
      throw ArgumentError('La dirección es obligatoria');
    }

    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);

    final orderRow = await supabase
        .from('orders')
        .insert({
          'customer_id': customerId,
          'status': 'created',
          'total': total,
          'delivery_address': address.trim(),
          'notes': notes.trim(),
        })
        .select()
        .single();

    final orderId = orderRow['id'] as int;

    await supabase.from('order_items').insert(
          items
              .map((item) => {
                    'order_id': orderId,
                    'product_id': item.productId,
                    'quantity': item.quantity,
                    'unit_price': item.unitPrice,
                    'ingredients': item.ingredients,
                    'size': item.size,
                    'shape': item.shape,
                    'flavor': item.flavor,
                    'color': item.color,
                  })
              .toList(),
        );

    // Descuenta stock de cada producto pedido.
    for (final item in items) {
      final product = await supabase.from('products').select('stock').eq('id', item.productId).single();
      final newStock = ((product['stock'] as int) - item.quantity).clamp(0, 1 << 30);
      await supabase.from('products').update({'stock': newStock}).eq('id', item.productId);
    }

    return orderId;
  }

  Future<void> cancelOrder(int orderId) async {
    await supabase.from('orders').update({'status': 'cancelled'}).eq('id', orderId);
  }

  Future<CakeOrder> updateOrderStatus({
    required int orderId,
    required String currentStatus,
    required String targetStatus,
  }) async {
    const validTargets = {'in_oven', 'decorating', 'on_the_way', 'delivered'};
    if (!validTargets.contains(targetStatus)) {
      throw ArgumentError('Estado no válido');
    }
    if (!isValidOrderStatusTransition(currentStatus, targetStatus)) {
      throw StateError(
        'Transición inválida: $currentStatus -> $targetStatus. '
        'Debe seguir el flujo Confirmado > En horno > Decorando > En camino > Entregado',
      );
    }

    final message = messageForStatus(targetStatus);
    final eta = etaForStatus(targetStatus);

    final updated = await supabase
        .from('orders')
        .update({'status': targetStatus})
        .eq('id', orderId)
        .select()
        .single();

    await supabase.from('tracking_events').insert({
      'order_id': orderId,
      'status': targetStatus,
      'message': message,
      'eta_minutes': eta,
    });

    return CakeOrder.fromMap(updated);
  }

  Future<AdminOrderSummary> ordersSummary(List<CakeOrder> allOrders, String period) async {
    final safePeriod = period.toLowerCase().isEmpty ? 'day' : period.toLowerCase();
    final now = DateTime.now();
    final start = _startOfPeriod(safePeriod, now);

    final inPeriod = allOrders.where((o) => !o.createdAt.isBefore(start) && !o.createdAt.isAfter(now)).toList();

    final breakdown = <String, int>{};
    for (final order in inPeriod) {
      breakdown[order.status] = (breakdown[order.status] ?? 0) + 1;
    }
    final sortedBreakdown = breakdown.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return AdminOrderSummary(
      period: safePeriod,
      totalOrders: inPeriod.length,
      totalSales: inPeriod.fold(0, (sum, o) => sum + o.total),
      statusBreakdown: sortedBreakdown.map((e) => MapEntry(e.key, e.value)).toList(),
    );
  }

  DateTime _startOfPeriod(String period, DateTime now) {
    switch (period) {
      case 'week':
        final mondayOffset = now.weekday - 1;
        final monday = now.subtract(Duration(days: mondayOffset));
        return DateTime(monday.year, monday.month, monday.day);
      case 'month':
        return DateTime(now.year, now.month, 1);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }
}

class AdminOrderSummary {
  final String period;
  final int totalOrders;
  final double totalSales;
  final List<MapEntry<String, int>> statusBreakdown;

  const AdminOrderSummary({
    required this.period,
    required this.totalOrders,
    required this.totalSales,
    required this.statusBreakdown,
  });
}
