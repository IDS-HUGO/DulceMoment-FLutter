import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/dulce_repository.dart';

enum SessionStatus { loading, loggedOut, loggedIn }

class SessionProvider extends ChangeNotifier {
  final DulceRepository repository;

  SessionProvider(this.repository) {
    _restore();
  }

  SessionStatus status = SessionStatus.loading;
  AppUser? currentUser;
  String? errorMessage;

  Future<void> _restore() async {
    currentUser = await repository.restoreSession();
    status = currentUser != null ? SessionStatus.loggedIn : SessionStatus.loggedOut;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    errorMessage = null;
    try {
      currentUser = await repository.login(email: email, password: password);
      status = SessionStatus.loggedIn;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _readableError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String role) async {
    errorMessage = null;
    try {
      currentUser = await repository.register(name: name, email: email, password: password, role: role);
      status = SessionStatus.loggedIn;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _readableError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await repository.logout();
    currentUser = null;
    status = SessionStatus.loggedOut;
    notifyListeners();
  }

  Future<bool> updateProfile(String name, String email) async {
    if (currentUser == null) return false;
    errorMessage = null;
    try {
      currentUser = await repository.auth.updateProfile(userId: currentUser!.id, name: name, email: email);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _readableError(e);
      notifyListeners();
      return false;
    }
  }

  String _readableError(Object e) {
    final text = e.toString();
    if (text.contains('Invalid login credentials')) return 'Correo o contraseña incorrectos';
    return text.replaceFirst('Exception: ', '');
  }
}
