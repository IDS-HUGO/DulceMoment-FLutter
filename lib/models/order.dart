const kOrderStatusSequence = [
  'created',
  'in_oven',
  'decorating',
  'on_the_way',
  'delivered',
];

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final String ingredients;
  final String size;
  final String shape;
  final String flavor;
  final String color;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.ingredients,
    required this.size,
    required this.shape,
    required this.flavor,
    required this.color,
  });

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      ingredients: (map['ingredients'] ?? '') as String,
      size: (map['size'] ?? '') as String,
      shape: (map['shape'] ?? '') as String,
      flavor: (map['flavor'] ?? '') as String,
      color: (map['color'] ?? '') as String,
    );
  }
}

class TrackingEvent {
  final int id;
  final int orderId;
  final String status;
  final String message;
  final int etaMinutes;
  final DateTime createdAt;

  const TrackingEvent({
    required this.id,
    required this.orderId,
    required this.status,
    required this.message,
    required this.etaMinutes,
    required this.createdAt,
  });

  factory TrackingEvent.fromMap(Map<String, dynamic> map) {
    return TrackingEvent(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      status: map['status'] as String,
      message: (map['message'] ?? '') as String,
      etaMinutes: (map['eta_minutes'] ?? 0) as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class PaymentInfo {
  final int id;
  final int orderId;
  final double amount;
  final String status;
  final String cardLast4;
  final DateTime createdAt;

  const PaymentInfo({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.cardLast4,
    required this.createdAt,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String,
      cardLast4: (map['card_last4'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class CakeOrder {
  final int id;
  final String customerId;
  final String status;
  final double total;
  final String deliveryAddress;
  final String notes;
  final DateTime createdAt;
  final List<OrderItem> items;
  final List<TrackingEvent> events;
  final PaymentInfo? payment;

  const CakeOrder({
    required this.id,
    required this.customerId,
    required this.status,
    required this.total,
    required this.deliveryAddress,
    required this.notes,
    required this.createdAt,
    this.items = const [],
    this.events = const [],
    this.payment,
  });

  bool get isPaid => payment != null && payment!.status.toLowerCase() == 'approved';
  bool get requiresPayment => status == 'created' && !isPaid;

  factory CakeOrder.fromMap(Map<String, dynamic> map) {
    final rawItems = (map['order_items'] as List<dynamic>?) ?? const [];
    final rawEvents = (map['tracking_events'] as List<dynamic>?) ?? const [];
    final rawPayments = (map['payments'] as List<dynamic>?) ?? const [];
    return CakeOrder(
      id: map['id'] as int,
      customerId: map['customer_id'] as String,
      status: map['status'] as String,
      total: (map['total'] as num).toDouble(),
      deliveryAddress: (map['delivery_address'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: rawItems.map((e) => OrderItem.fromMap(e as Map<String, dynamic>)).toList(),
      events: rawEvents.map((e) => TrackingEvent.fromMap(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      payment: rawPayments.isNotEmpty
          ? PaymentInfo.fromMap(rawPayments.first as Map<String, dynamic>)
          : null,
    );
  }
}
