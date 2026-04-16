import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wa_notification_item_model.dart';

class WaNotificationsRepository {
  final SupabaseClient _supabase;

  WaNotificationsRepository(this._supabase);

  Future<List<WaNotificationItemModel>> getNotifications({
    int limit = 100,
    int offset = 0,
    String? status,
  }) async {
    final response = await _supabase.rpc(
      'rpc_get_wa_notifications',
      params: {
        'p_limit': limit,
        'p_offset': offset,
        'p_status': (status == null || status == 'all') ? null : status,
      },
    );

    final list = response as List<dynamic>? ?? [];
    return list
        .map(
          (row) => WaNotificationItemModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<void> retryNotification(int queueId) async {
    await _supabase.rpc(
      'rpc_retry_wa_notification',
      params: {'p_queue_id': queueId},
    );
  }
}
