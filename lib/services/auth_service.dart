import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/app_user.dart';

class AuthService {
  /// Registro: crea el usuario en Supabase Auth. El trigger
  /// `handle_new_user` (ver supabase/schema.sql) crea la fila en `profiles`.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String role, // 'customer' | 'store'
  }) async {
    // Sanitización fuerte del correo (quita espacios, saltos de línea y caracteres invisibles)
    final cleanEmail = email.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '').trim();

    if (name.trim().isEmpty || cleanEmail.isEmpty || password.length < 6) {
      throw ArgumentError('Datos inválidos. Contraseña mínima 6 caracteres.');
    }

    final response = await supabase.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'name': name.trim(),
        'role': role,
      },
    );

    final userId = response.user?.id;
    if (userId == null) {
      throw StateError('No se pudo completar el registro.');
    }

    // El trigger puede tardar un instante en insertar el profile;
    // lo esperamos leyéndolo justo después.
    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return AppUser.fromMap(profile);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final userId = response.user?.id;
    if (userId == null) {
      throw StateError('Credenciales inválidas.');
    }

    return _fetchProfile(userId);
  }

  Future<AppUser?> restoreSession() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      return await _fetchProfile(userId);
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> _fetchProfile(String userId) async {
    final row = await supabase.from('profiles').select().eq('id', userId).single();
    return AppUser.fromMap(row);
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  Future<AppUser> updateProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    if (name.trim().length < 2) {
      throw ArgumentError('El nombre debe tener al menos 2 caracteres');
    }
    if (!email.contains('@')) {
      throw ArgumentError('Email inválido');
    }

    final row = await supabase
        .from('profiles')
        .update({'name': name.trim(), 'email': email.trim()})
        .eq('id', userId)
        .select()
        .single();

    return AppUser.fromMap(row);
  }

  /// Devuelve (nombre, email) del primer usuario con rol 'store'.
  Future<AppUser?> getStorePublicProfile() async {
    final rows = await supabase.from('profiles').select().eq('role', 'store').limit(1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Stream<AuthState> authStateChanges() => supabase.auth.onAuthStateChange;
}
