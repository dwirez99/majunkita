import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../../manage_tailors/data/models/tailor_model.dart';
import '../../data/repositories/perca_transactions_repository.dart';

// ============================================================
// 1. REPOSITORY PROVIDER
// ============================================================

/// Provider untuk PercaTransactionsRepository
final percaTransactionsRepositoryProvider =
    Provider<PercaTransactionsRepository>((ref) {
      final supabase = ref.watch(supabaseClientProvider);
      return PercaTransactionsRepository(supabase);
    });

// ============================================================
// 2. DATA PROVIDERS (FutureProvider)
// ============================================================

/// Provider untuk mengambil daftar Tailor (untuk dropdown form transaksi)
final tailorListForTransactionProvider = FutureProvider<List<TailorModel>>((
  ref,
) {
  return ref.watch(percaTransactionsRepositoryProvider).getTailorList();
});

/// Provider untuk mengambil ringkasan stok tersedia per sack_code
final availableSackSummaryProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) {
    return ref
        .watch(percaTransactionsRepositoryProvider)
        .getAvailableSackSummary();
  },
);

/// Provider untuk mengambil riwayat transaksi perca
final percaTransactionHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
      return ref
          .watch(percaTransactionsRepositoryProvider)
          .getPercaTransactionHistory();
    });

/// Provider untuk statistik bulanan transaksi perca
final percaTransactionMonthlyStatsProvider =
    FutureProvider<Map<String, double>>((ref) {
      return ref
          .watch(percaTransactionsRepositoryProvider)
          .getMonthlyTransactionStats();
    });

/// Provider untuk total berat per tailor
final percaWeightPerTailorProvider = FutureProvider<Map<String, double>>((ref) {
  return ref
      .watch(percaTransactionsRepositoryProvider)
      .getTotalWeightPerTailor();
});

/// Provider untuk mengambil transaksi berdasarkan ID tailor tertentu
final percaTransactionsByTailorProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tailorId) {
      return ref
          .watch(percaTransactionsRepositoryProvider)
          .getTransactionsByTailor(tailorId);
    });

/// Provider untuk mengambil detail transaksi berdasarkan ID
final percaTransactionDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, transactionId) {
      return ref
          .watch(percaTransactionsRepositoryProvider)
          .getPercaTransactionById(transactionId);
    });

// ============================================================
// 3. NOTIFIER PROVIDER (untuk CREATE via RPC)
// ============================================================

/// Notifier untuk menangani proses transaksi perca via RPC
final percaTransactionNotifierProvider =
    AsyncNotifierProvider<PercaTransactionNotifier, void>(
      PercaTransactionNotifier.new,
    );

class PercaTransactionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Tidak ada state awal yang perlu dibangun
  }

  /// Proses transaksi perca via RPC process_transaction_by_sack_code
  /// - Otomatis FIFO (karung terlama diambil duluan)
  /// - Otomatis update status stok percas_stock → 'diambil_penjahit'
  /// - Otomatis insert ke perca_transactions
  Future<Map<String, dynamic>> processTransaction({
    required String idTailor,
    required String sackCode,
    required int sackCount,
    required DateTime dateEntry,
  }) async {
    state = const AsyncValue.loading();

    Map<String, dynamic> result = {};

    state = await AsyncValue.guard(() async {
      final repository = ref.read(percaTransactionsRepositoryProvider);

      // Ambil staff_id dari user yang sedang login
      final staffId = Supabase.instance.client.auth.currentUser?.id;
      if (staffId == null) {
        throw Exception(
          'Pengguna tidak terautentikasi. Silakan login ulang.',
        );
      }

      // Panggil RPC
      result = await repository.processTransactionBySackCode(
        idTailor: idTailor,
        staffId: staffId,
        sackCode: sackCode,
        sackCount: sackCount,
        dateEntry: dateEntry,
      );

      // Refresh semua data terkait
      ref.invalidate(percaTransactionHistoryProvider);
      ref.invalidate(percaTransactionMonthlyStatsProvider);
      ref.invalidate(percaWeightPerTailorProvider);
      ref.invalidate(availableSackSummaryProvider);
    });

    // Rethrow error agar caller dapat mendeteksi kegagalan per-transaksi
    if (state.hasError) {
      throw state.error!;
    }

    return result;
  }

  /// Update transaksi perca yang sudah ada
  Future<void> updatePercaTransaction({
    required String transactionId,
    required Map<String, dynamic> updateData,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(percaTransactionsRepositoryProvider);
      await repository.updatePercaTransaction(transactionId, updateData);

      ref.invalidate(percaTransactionHistoryProvider);
      ref.invalidate(percaTransactionMonthlyStatsProvider);
      ref.invalidate(percaWeightPerTailorProvider);
    });
  }

  /// Hapus transaksi perca
  Future<void> deletePercaTransaction(String transactionId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(percaTransactionsRepositoryProvider);
      await repository.deletePercaTransaction(transactionId);

      ref.invalidate(percaTransactionHistoryProvider);
      ref.invalidate(percaTransactionMonthlyStatsProvider);
      ref.invalidate(percaWeightPerTailorProvider);
      ref.invalidate(availableSackSummaryProvider);
    });
  }
}
