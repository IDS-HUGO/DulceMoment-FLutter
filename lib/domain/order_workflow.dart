import '../models/order.dart';

/// Verifica que el pedido avance exactamente un paso dentro
/// de la secuencia: created -> in_oven -> decorating -> on_the_way -> delivered
bool isValidOrderStatusTransition(String currentStatus, String targetStatus) {
  final currentIndex = kOrderStatusSequence.indexOf(currentStatus);
  final targetIndex = kOrderStatusSequence.indexOf(targetStatus);
  if (currentIndex == -1 || targetIndex == -1) return false;
  return targetIndex == currentIndex + 1;
}

/// Siguiente(s) estado(s) que la tienda puede aplicar a un pedido dado su estado actual.
List<MapEntry<String, String>> sellerNextOrderStatuses(String currentStatus) {
  switch (currentStatus) {
    case 'created':
      return [const MapEntry('in_oven', 'En horno')];
    case 'in_oven':
      return [const MapEntry('decorating', 'Decorando')];
    case 'decorating':
      return [const MapEntry('on_the_way', 'En camino')];
    case 'on_the_way':
      return [const MapEntry('delivered', 'Entregado')];
    default:
      return const [];
  }
}

bool orderRequiresPayment(String orderStatus, bool paymentConfirmed) {
  return orderStatus == 'created' && !paymentConfirmed;
}

String statusLabel(String status) {
  switch (status) {
    case 'created':
      return 'Confirmado';
    case 'in_oven':
      return 'En horno';
    case 'decorating':
      return 'Decorando';
    case 'on_the_way':
      return 'En camino';
    case 'delivered':
      return 'Entregado';
    case 'cancelled':
      return 'Cancelado';
    default:
      return status;
  }
}

String messageForStatus(String status) {
  switch (status) {
    case 'in_oven':
      return 'Tu pastel entró al horno';
    case 'decorating':
      return 'Estamos decorando tu pastel';
    case 'on_the_way':
      return '¡Tu pedido va en camino!';
    case 'delivered':
      return 'Entregado';
    default:
      return '';
  }
}

int etaForStatus(String status) {
  switch (status) {
    case 'in_oven':
      return 60;
    case 'decorating':
      return 35;
    case 'on_the_way':
      return 20;
    default:
      return 0;
  }
}
