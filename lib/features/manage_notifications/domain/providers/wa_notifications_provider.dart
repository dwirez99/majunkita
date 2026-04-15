import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../data/models/wa_notification_item_model.dart';
import '../../data/repositories/wa_notifications_repository.dart';

final waNotificationsRepositoryProvider = Provider<WaNotificationsRepository>(
  (ref) => WaNotificationsRepository(ref.watch(supabaseClientProvider)),
);

class WaNotificationsFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setStatus(String value) => state = value;
}

final waNotificationsFilterProvider =
    NotifierProvider<WaNotificationsFilterNotifier, String>(
      WaNotificationsFilterNotifier.new,
    );

final waNotificationsListProvider =
    FutureProvider.autoDispose<List<WaNotificationItemModel>>((ref) async {
      final repo = ref.watch(waNotificationsRepositoryProvider);
      final status = ref.watch(waNotificationsFilterProvider);
      return repo.getNotifications(status: status);
    });

final waNotificationsBadgeCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final repo = ref.watch(waNotificationsRepositoryProvider);
  final items = await repo.getNotifications(limit: 500, status: 'all');
  return items
      .where((item) => item.status == 'pending' || item.status == 'processing' || item.status == 'failed')
      .length;
});

class WaNotificationActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> retry(int queueId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(waNotificationsRepositoryProvider);
      await repo.retryNotification(queueId);
      ref.invalidate(waNotificationsListProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final waNotificationActionProvider =
    AsyncNotifierProvider<WaNotificationActionNotifier, void>(
      WaNotificationActionNotifier.new,
    );
