import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../../manage_tailors/data/models/tailor_model.dart';
import '../../data/model/majun_transactions_model.dart';
import '../../data/repositories/majun_repository.dart';

// ============================================================
// 1. REPOSITORY PROVIDER
// ============================================================

final majunRepositoryProvider = Provider<MajunRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return MajunRepository(supabase);
});

// ============================================================
// 2. DATA PROVIDERS
// ============================================================

final tailorListForMajunProvider = FutureProvider<List<TailorModel>>((ref) {
  return ref.watch(majunRepositoryProvider).getTailorList();
});

final majunHistoryProvider = FutureProvider<List<MajunTransactionsModel>>((
  ref,
) {
  return ref.watch(majunRepositoryProvider).getMajunHistory();
});

final limbahHistoryProvider = FutureProvider<List<LimbahTransactionsModel>>((
  ref,
) {
  return ref.watch(majunRepositoryProvider).getLimbahHistory();
});

final majunPricePerKgProvider = FutureProvider<double>((ref) {
  return ref.watch(majunRepositoryProvider).getMajunPricePerKg();
});

final majunMonthlyStatsProvider = FutureProvider<Map<String, double>>((ref) {
  return ref.watch(majunRepositoryProvider).getMonthlyMajunStats();
});

// ============================================================
// 2b. UPDATE PRICE NOTIFIER
// ============================================================

final updatePriceNotifierProvider =
    AsyncNotifierProvider<UpdatePriceNotifier, void>(UpdatePriceNotifier.new);

class UpdatePriceNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updatePrice(double newPrice) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(majunRepositoryProvider).updateMajunPricePerKg(newPrice);
      ref.invalidate(majunPricePerKgProvider);
    });
    if (state.hasError) throw state.error!;
  }
}

// ============================================================
// 3. SETOR MAJUN NOTIFIER
// ============================================================

final setorMajunNotifierProvider =
    AsyncNotifierProvider<SetorMajunNotifier, void>(SetorMajunNotifier.new);

class SetorMajunNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Proses setor majun: upload foto → INSERT ke majun_transactions
  /// Trigger di DB otomatis menghitung earned_wage & update tailors
  Future<SetorMajunResult> setorMajun({
    required String tailorId,
    required double weightMajun,
    required File photo,
  }) async {
    state = const AsyncValue.loading();

    SetorMajunResult? result;

    state = await AsyncValue.guard(() async {
      final repository = ref.read(majunRepositoryProvider);

      final staffId = Supabase.instance.client.auth.currentUser?.id;
      if (staffId == null) {
        throw Exception('Pengguna tidak terautentikasi. Silakan login ulang.');
      }

      // 1. Upload foto bukti timbangan
      final deliveryProof = await repository.uploadDeliveryProof(
        imageFile: photo,
        tailorId: tailorId,
        folder: 'majun_photos',
      );

      // 2. INSERT ke majun_transactions (trigger handles the rest)
      result = await repository.setorMajun(
        tailorId: tailorId,
        weightMajun: weightMajun,
        deliveryProof: deliveryProof,
        staffId: staffId,
      );

      // 3. Refresh data terkait
      ref.invalidate(majunHistoryProvider);
      ref.invalidate(majunMonthlyStatsProvider);
    });

    if (state.hasError) throw state.error!;
    return result!;
  }
}

// ============================================================
// 4. SETOR LIMBAH NOTIFIER
// ============================================================

final setorLimbahNotifierProvider =
    AsyncNotifierProvider<SetorLimbahNotifier, void>(SetorLimbahNotifier.new);

class SetorLimbahNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Proses setor limbah: upload foto (opsional) → INSERT ke limbah_transactions
  /// Trigger di DB otomatis mengurangi tailors.total_stock (tanpa upah)
  Future<LimbahTransactionsModel> setorLimbah({
    required String tailorId,
    required double weightLimbah,
    File? photo,
  }) async {
    state = const AsyncValue.loading();

    LimbahTransactionsModel? result;

    state = await AsyncValue.guard(() async {
      final repository = ref.read(majunRepositoryProvider);

      final staffId = Supabase.instance.client.auth.currentUser?.id;
      if (staffId == null) {
        throw Exception('Pengguna tidak terautentikasi. Silakan login ulang.');
      }

      // 1. Upload foto bukti (opsional untuk limbah)
      String? deliveryProof;
      if (photo != null) {
        deliveryProof = await repository.uploadDeliveryProof(
          imageFile: photo,
          tailorId: tailorId,
          folder: 'limbah_photos',
        );
      }

      // 2. INSERT ke limbah_transactions (trigger handles the rest)
      result = await repository.setorLimbah(
        tailorId: tailorId,
        weightLimbah: weightLimbah,
        staffId: staffId,
        deliveryProof: deliveryProof,
      );

      // 3. Refresh data terkait
      ref.invalidate(limbahHistoryProvider);
      ref.invalidate(majunMonthlyStatsProvider);
    });

    if (state.hasError) throw state.error!;
    return result!;
  }
}
