class PushAlert {
  final int id;
  final String userId;
  final int? orderId;
  final String title;
  final String body;
  final DateTime createdAt;

  const PushAlert({
    required this.id,
    required this.userId,
    this.orderId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory PushAlert.fromMap(Map<String, dynamic> map) {
    return PushAlert(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      orderId: map['order_id'] as int?,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
