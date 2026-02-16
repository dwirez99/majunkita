// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../data/models/add_perca_plan_model.dart';
import '../../data/repositories/perca_plan_repository.dart';

// ===========================================================================
// REPOSITORY PROVIDER
// ===========================================================================

final percaPlanRepositoryProvider = Provider<PercaPlanRepository>((ref) {
  return PercaPlanRepository(ref.watch(supabaseClientProvider));
});

// ===========================================================================
// STATUS FILTER PROVIDER
// ===========================================================================

/// Notifier untuk filter status
class StatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  void setStatus(String status) => state = status;
  void clear() => state = 'ALL';
}

final statusFilterProvider = NotifierProvider<StatusFilterNotifier, String>(
  StatusFilterNotifier.new,
);

// ===========================================================================
// PENDING PLANS PROVIDER (untuk Manager)
// ===========================================================================

/// Provider untuk daftar rencana yang berstatus PENDING
final pendingPlansProvider =
    FutureProvider.family<List<AddPercaPlanModel>, int>((ref, page) async {
  final repository = ref.watch(percaPlanRepositoryProvider);
  return repository.getPendingPlans(page: page, limit: 20);
});

// ===========================================================================
// ALL PLANS PROVIDER (untuk Admin dengan filter status)
// ===========================================================================

/// Provider untuk semua rencana dengan filter status
final allPlansProvider =
    FutureProvider.family<List<AddPercaPlanModel>, int>((ref, page) async {
  final repository = ref.watch(percaPlanRepositoryProvider);
  final status = ref.watch(statusFilterProvider);

  return repository.getAllPlans(
    statusFilter: status == 'ALL' ? null : status,
    page: page,
    limit: 20,
  );
});

// ===========================================================================
// PLANS BY FACTORY PROVIDER
// ===========================================================================

/// Provider untuk rencana berdasarkan factory
final plansByFactoryProvider = FutureProvider.family<List<AddPercaPlanModel>,
    String>((ref, factoryId) async {
  final repository = ref.watch(percaPlanRepositoryProvider);
  return repository.getPlansByFactory(factoryId);
});

// ===========================================================================
// SINGLE PLAN PROVIDER
// ===========================================================================

/// Provider untuk detail rencana berdasarkan ID
final singlePlanProvider =
    FutureProvider.family<AddPercaPlanModel, String>((ref, planId) async {
  final repository = ref.watch(percaPlanRepositoryProvider);
  return repository.getPlanById(planId);
});

// ===========================================================================
// PLAN STATS PROVIDER
// ===========================================================================

/// Provider untuk statistik rencana
final planStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(percaPlanRepositoryProvider);
  return repository.getPlanStats();
});

// ===========================================================================
// COUNT BY STATUS PROVIDER
// ===========================================================================

/// Provider untuk menghitung rencana berdasarkan status
final planCountByStatusProvider =
    FutureProvider.family<int, String>((ref, status) async {
  final repository = ref.watch(percaPlanRepositoryProvider);
  return repository.countPlansByStatus(status);
});

// ===========================================================================
// ACTION PROVIDERS (Create, Update, Delete)
// ===========================================================================

/// Notifier untuk membuat rencana baru (untuk Admin)
class CreatePlanNotifier extends Notifier<AsyncValue<AddPercaPlanModel>> {
  @override
  AsyncValue<AddPercaPlanModel> build() => const AsyncValue.loading();

  Future<void> createPlan({
    required String idFactory,
    required DateTime plannedDate,
    required String createdBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(percaPlanRepositoryProvider);
      final plan = await repository.createPlan(
        idFactory: idFactory,
        plannedDate: plannedDate,
        createdBy: createdBy,
      );

      state = AsyncValue.data(plan);

      // Invalidate related providers untuk refresh data
      ref.invalidate(allPlansProvider);
      ref.invalidate(pendingPlansProvider);
      ref.invalidate(plansByFactoryProvider(idFactory));
      ref.invalidate(planStatsProvider);
      ref.invalidate(planCountByStatusProvider('PENDING'));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final createPlanProvider =
    NotifierProvider<CreatePlanNotifier, AsyncValue<AddPercaPlanModel>>(
  CreatePlanNotifier.new,
);

// ===========================================================================
// APPROVE PLAN ACTION
// ===========================================================================

/// Notifier untuk menyetujui rencana (untuk Manager)
class ApprovePlanNotifier extends Notifier<AsyncValue<AddPercaPlanModel>> {
  @override
  AsyncValue<AddPercaPlanModel> build() => const AsyncValue.loading();

  Future<void> approvePlan(String planId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(percaPlanRepositoryProvider);
      final plan = await repository.approvePlan(planId);

      state = AsyncValue.data(plan);

      // Invalidate related providers untuk refresh data
      ref.invalidate(pendingPlansProvider);
      ref.invalidate(allPlansProvider);
      ref.invalidate(singlePlanProvider(planId));
      ref.invalidate(planStatsProvider);
      ref.invalidate(planCountByStatusProvider('PENDING'));
      ref.invalidate(planCountByStatusProvider('APPROVED'));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final approvePlanProvider =
    NotifierProvider<ApprovePlanNotifier, AsyncValue<AddPercaPlanModel>>(
  ApprovePlanNotifier.new,
);

// ===========================================================================
// REJECT PLAN ACTION
// ===========================================================================

/// Notifier untuk menolak rencana (untuk Manager)
class RejectPlanNotifier extends Notifier<AsyncValue<AddPercaPlanModel>> {
  @override
  AsyncValue<AddPercaPlanModel> build() => const AsyncValue.loading();

  Future<void> rejectPlan(String planId, String rejectionReason) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(percaPlanRepositoryProvider);
      final plan =
          await repository.rejectPlan(planId, rejectionReason: rejectionReason);

      state = AsyncValue.data(plan);

      // Invalidate related providers untuk refresh data
      ref.invalidate(pendingPlansProvider);
      ref.invalidate(allPlansProvider);
      ref.invalidate(singlePlanProvider(planId));
      ref.invalidate(planStatsProvider);
      ref.invalidate(planCountByStatusProvider('PENDING'));
      ref.invalidate(planCountByStatusProvider('REJECTED'));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final rejectPlanProvider =
    NotifierProvider<RejectPlanNotifier, AsyncValue<AddPercaPlanModel>>(
  RejectPlanNotifier.new,
);

// ===========================================================================
// UPDATE PLAN ACTION
// ===========================================================================

/// Notifier untuk mengupdate rencana (untuk Admin)
class UpdatePlanNotifier extends Notifier<AsyncValue<AddPercaPlanModel>> {
  @override
  AsyncValue<AddPercaPlanModel> build() => const AsyncValue.loading();

  Future<void> updatePlan(
    String planId, {
    DateTime? plannedDate,
    String? notes,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(percaPlanRepositoryProvider);
      final plan = await repository.updatePlan(
        planId,
        plannedDate: plannedDate,
        notes: notes,
        status: status,
      );

      state = AsyncValue.data(plan);

      // Invalidate related providers untuk refresh data
      ref.invalidate(allPlansProvider);
      ref.invalidate(pendingPlansProvider);
      ref.invalidate(singlePlanProvider(planId));
      
      // Invalidate status counts
      if (status != null) {
        ref.invalidate(planCountByStatusProvider(status));
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final updatePlanProvider =
    NotifierProvider<UpdatePlanNotifier, AsyncValue<AddPercaPlanModel>>(
  UpdatePlanNotifier.new,
);

// ===========================================================================
// DELETE PLAN ACTION
// ===========================================================================

/// Notifier untuk menghapus rencana (untuk Admin)
class DeletePlanNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.loading();

  Future<void> deletePlan(String planId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(percaPlanRepositoryProvider);
      await repository.deletePlan(planId);

      state = const AsyncValue.data(null);

      // Invalidate related providers untuk refresh data
      ref.invalidate(allPlansProvider);
      ref.invalidate(pendingPlansProvider);
      ref.invalidate(singlePlanProvider(planId));
      ref.invalidate(planStatsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final deletePlanProvider = NotifierProvider<DeletePlanNotifier, AsyncValue<void>>(
  DeletePlanNotifier.new,
);
