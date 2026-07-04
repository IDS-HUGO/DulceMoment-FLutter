import '../core/supabase_config.dart';
import '../models/push_alert.dart';

class AlertService {
  Future<void> sendAlert({
    required String userId,
    int? orderId,
    required String title,
    required String body,
  }) async {
    await supabase.from('push_alerts').insert({
      'user_id': userId,
      'order_id': orderId,
      'title': title,
      'body': body,
    });
  }

  Future<List<PushAlert>> fetchAlerts(String userId) async {
    final rows = await supabase
        .from('push_alerts')
        .select()
        .eq('user_id', userId)
        .order('id', ascending: false);
    return (rows as List).map((e) => PushAlert.fromMap(e as Map<String, dynamic>)).toList();
  }

  Stream<List<PushAlert>> watchAlerts(String userId) {
    return supabase
        .from('push_alerts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('id', ascending: false)
        .map((rows) => rows.map((e) => PushAlert.fromMap(e)).toList());
  }
}
