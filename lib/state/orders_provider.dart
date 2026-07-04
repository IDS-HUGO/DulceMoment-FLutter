import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/dulce_repository.dart';
import '../services/order_service.dart';

class OrdersProvider extends ChangeNotifier {
  final DulceRepository repository;
  StreamSubscription<List<CakeOrder>>? _sub;

  OrdersProvider(this.repository);

  List<CakeOrder> orders = [];
  bool isLoading = true;
  String? errorMessage;

  /// customerId == null -> vista de tienda (todos los pedidos)
  void start({String? customerId}) {
    isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = repository.orders.watchOrders(customerId: customerId).listen(
      (list) {
        orders = list;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<int?> createOrder({
    required AppUser customer,
    required List<Product> catalog,
    required List<OrderItemDraft> items,
    required String address,
    required String notes,
  }) async {
    try {
      final id = await repository.createOrder(
        customer: customer,
        catalog: catalog,
        items: items,
        address: address,
        notes: notes,
      );
      errorMessage = null;
      return id;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      await repository.orders.cancelOrder(orderId);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> advanceStatus(CakeOrder order, String targetStatus) async {
    try {
      await repository.updateOrderStatus(order: order, targetStatus: targetStatus);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String?> payOrder({
    required CakeOrder order,
    required String cardNumber,
    required String cardName,
    required String securityCode,
    required String expiry,
  }) async {
    try {
      final message = await repository.payOrder(
        order: order,
        cardNumber: cardNumber,
        cardName: cardName,
        securityCode: securityCode,
        expiry: expiry,
      );
      errorMessage = null;
      return message;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<AdminOrderSummary> summary(String period) {
    return repository.orders.ordersSummary(orders, period);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
