import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'alert_service.dart';
import 'auth_service.dart';
import 'order_service.dart';
import 'payment_service.dart';
import 'product_service.dart';

/// Fachada única sobre todos los servicios de Supabase, análoga a
/// `CakeRepository`/`LocalDulceRepository` del proyecto original en Android.
class DulceRepository {
  final AuthService auth = AuthService();
  final ProductService products = ProductService();
  final OrderService orders = OrderService();
  final PaymentService payments = PaymentService();
  final AlertService alerts = AlertService();

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return auth.register(name: name, email: email, password: password, role: role);
  }

  Future<AppUser> login({required String email, required String password}) {
    return auth.login(email: email, password: password);
  }

  Future<AppUser?> restoreSession() => auth.restoreSession();

  Future<void> logout() => auth.logout();

  Future<int> createOrder({
    required AppUser customer,
    required List<Product> catalog,
    required List<OrderItemDraft> items,
    required String address,
    required String notes,
  }) async {
    final orderId = await orders.createOrder(
      customerId: customer.id,
      address: address,
      notes: notes,
      items: items,
    );

    await alerts.sendAlert(
      userId: customer.id,
      orderId: orderId,
      title: 'Pedido creado',
      body: 'Tu pedido fue recibido en la tienda',
    );

    final store = await auth.getStorePublicProfile();
    if (store != null) {
      await alerts.sendAlert(
        userId: store.id,
        orderId: orderId,
        title: 'Nuevo pedido',
        body: 'Se recibió el pedido #$orderId. Esperando confirmación de pago.',
      );
    }

    return orderId;
  }

  Future<void> updateOrderStatus({
    required CakeOrder order,
    required String targetStatus,
  }) async {
    final updated = await orders.updateOrderStatus(
      orderId: order.id,
      currentStatus: order.status,
      targetStatus: targetStatus,
    );

    await alerts.sendAlert(
      userId: order.customerId,
      orderId: order.id,
      title: 'Actualización de pedido',
      body: updated.events.isNotEmpty ? updated.events.last.message : 'Tu pedido tiene una actualización',
    );
  }

  Future<String> payOrder({
    required CakeOrder order,
    required String cardNumber,
    required String cardName,
    required String securityCode,
    required String expiry,
  }) async {
    final result = await payments.payOrder(
      orderId: order.id,
      amount: order.total,
      cardNumber: cardNumber,
      cardName: cardName,
      securityCode: securityCode,
      expiry: expiry,
    );

    await alerts.sendAlert(
      userId: order.customerId,
      orderId: order.id,
      title: 'Pago confirmado',
      body: 'Tu pago del pedido #${order.id} fue aprobado.',
    );

    final store = await auth.getStorePublicProfile();
    if (store != null) {
      await alerts.sendAlert(
        userId: store.id,
        orderId: order.id,
        title: 'Pedido pagado',
        body: 'El pedido #${order.id} fue pagado y está confirmado.',
      );
    }

    return result;
  }
}
