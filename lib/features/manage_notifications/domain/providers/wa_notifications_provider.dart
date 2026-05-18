import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../data/models/wa_notification_item_model.dart';
import '../../data/repositories/wa_notifications_repository.dart';

final waNotificationsRepositoryProvider = Provider<WaNotificationsRepository>(
  (ref) => WaNotificationsRepository(ref.watch(supabaseClientProvider)),
);

class WaNotificationsFilterState {
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? eventType;

  WaNotificationsFilterState({
    this.status = 'all',
    this.startDate,
    this.endDate,
    this.eventType,
  });

  WaNotificationsFilterState copyWith({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    bool clearDates = false,
    bool clearEventType = false,
  }) {
    return WaNotificationsFilterState(
      status: status ?? this.status,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      eventType: clearEventType ? null : (eventType ?? this.eventType),
    );
  }
}

class WaNotificationsFilterNotifier extends Notifier<WaNotificationsFilterState> {
  @override
  WaNotificationsFilterState build() => WaNotificationsFilterState();

  void setStatus(String value) => state = state.copyWith(status: value);
  void setDateRange(DateTime? start, DateTime? end) => 
      state = state.copyWith(startDate: start, endDate: end, clearDates: start == null && end == null);
  void setEventType(String? type) => 
      state = state.copyWith(eventType: type, clearEventType: type == null);
}

final waNotificationsFilterProvider =
    NotifierProvider<WaNotificationsFilterNotifier, WaNotificationsFilterState>(
      WaNotificationsFilterNotifier.new,
    );

final waNotificationsListProvider =
    FutureProvider.autoDispose<List<WaNotificationItemModel>>((ref) async {
      final repo = ref.watch(waNotificationsRepositoryProvider);
      final filter = ref.watch(waNotificationsFilterProvider);
      
      final items = await repo.getNotifications(status: filter.status);
      
      return items.where((item) {
        if (filter.eventType != null && filter.eventType != 'all' && item.eventType != filter.eventType) {
          return false;
        }
        if (filter.startDate != null) {
          final start = DateTime(filter.startDate!.year, filter.startDate!.month, filter.startDate!.day);
          if (item.createdAt.isBefore(start)) return false;
        }
        if (filter.endDate != null) {
          final end = DateTime(filter.endDate!.year, filter.endDate!.month, filter.endDate!.day, 23, 59, 59);
          if (item.createdAt.isAfter(end)) return false;
        }
        return true;
      }).toList();
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
