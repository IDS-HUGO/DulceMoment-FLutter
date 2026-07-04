import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/push_alert.dart';
import '../services/dulce_repository.dart';

class AlertsProvider extends ChangeNotifier {
  final DulceRepository repository;
  StreamSubscription<List<PushAlert>>? _sub;

  AlertsProvider(this.repository);

  List<PushAlert> alerts = [];

  void start(String userId) {
    _sub?.cancel();
    _sub = repository.alerts.watchAlerts(userId).listen((list) {
      alerts = list;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
