import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/dulce_repository.dart';

class CatalogProvider extends ChangeNotifier {
  final DulceRepository repository;
  StreamSubscription<List<Product>>? _sub;

  CatalogProvider(this.repository);

  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;

  void start({required bool onlyActive}) {
    isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = repository.products.watchProducts().listen(
      (list) {
        products = onlyActive ? list.where((p) => p.isActive).toList() : list;
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

  Future<void> refresh({required bool onlyActive}) async {
    try {
      final list = await repository.products.fetchProducts(onlyActive: onlyActive);
      products = list;
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String imageUrl,
  }) async {
    try {
      await repository.products.addProduct(
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageUrl: imageUrl,
      );
      await refresh(onlyActive: false);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct({
    required int productId,
    required String name,
    required String description,
    required double price,
    required int stock,
    String? imageUrl,
  }) async {
    try {
      await repository.products.updateProduct(
        productId: productId,
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageUrl: imageUrl,
      );
      await refresh(onlyActive: false);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteProduct(int productId) async {
    await repository.products.deleteProduct(productId);
    await refresh(onlyActive: false);
  }

  Future<void> setOutOfStock(int productId) async {
    await repository.products.setOutOfStock(productId);
    await refresh(onlyActive: false);
  }

  Future<void> restockProduct(int productId, int units) async {
    await repository.products.restockProduct(productId, units);
    await refresh(onlyActive: false);
  }

  Future<void> toggleActive(int productId, bool isActive) async {
    await repository.products.toggleProductActive(productId, isActive);
    await refresh(onlyActive: false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
