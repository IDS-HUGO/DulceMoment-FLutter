import 'package:supabase_flutter/supabase_flutter.dart';

/// Reemplaza estos valores con los de tu proyecto en
/// https://supabase.com/dashboard/project/_/settings/api
class SupabaseConfig {
  static const String url = 'https://tbefphuplqgyyjiqcgov.supabase.co/rest/v1/';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiZWZwaHVwbHFneXlqaXFjZ292Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxMjk1NjIsImV4cCI6MjA5ODcwNTU2Mn0.tM41-i9qCMWS4Yn4BPms-TJbGQKVZ5gMiN7WdAD5TDs';

  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}

/// Acceso rápido al cliente Supabase desde cualquier parte del código.
SupabaseClient get supabase => Supabase.instance.client;
