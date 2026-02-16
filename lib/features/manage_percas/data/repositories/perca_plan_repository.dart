// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/add_perca_plan_model.dart';

/// Repository untuk mengelola data Rencana Pengambilan Perca
/// Mengisolasi logika Supabase dari UI layer
class PercaPlanRepository {
  final SupabaseClient _supabase;

  PercaPlanRepository(this._supabase);

  // ===========================================================================
  // LOGGING HELPER
  // ===========================================================================

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    print('[$timestamp] [$level] PERCA_PLAN_REPOSITORY: $message');
  }

  // ===========================================================================
  // READ OPERATIONS
  // ===========================================================================

  /// Mengambil semua data rencana pengambilan perca
  /// Filter by status jika diperlukan (PENDING, APPROVED, REJECTED)
  Future<List<AddPercaPlanModel>> getAllPlans({
    String? statusFilter,
    int page = 1,
    int limit = 20,
  }) async {
    _log('Fetching all plans (status: ${statusFilter ?? "ALL"}, page: $page, limit: $limit)...');
    try {
      final offset = (page - 1) * limit;

      var query = _supabase
          .from('percas_plans')
          .select(
            'id, id_factory, planned_date, status, notes, created_by, created_at, updated_at',
          );

      // Filter by status jika diperlukan
      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      // Order and pagination
      final response = await query.order('planned_date', ascending: false).range(offset, offset + limit - 1);

      final plans = (response as List)
          .map((json) => AddPercaPlanModel.fromJson(json))
          .toList();

      _log('Successfully fetched ${plans.length} plans');
      return plans;
    } catch (e) {
      _log('Error fetching all plans: $e', level: 'ERROR');
      throw Exception('Gagal mengambil daftar rencana: $e');
    }
  }

  /// Mengambil rencana yang berstatus PENDING (belum disetujui)
  Future<List<AddPercaPlanModel>> getPendingPlans({
    int page = 1,
    int limit = 20,
  }) async {
    _log('Fetching PENDING plans (page: $page, limit: $limit)...');
    try {
      final offset = (page - 1) * limit;

      final response = await _supabase
          .from('percas_plans')
          .select(
            'id, id_factory, planned_date, status, notes, created_by, created_at, updated_at',
          )
          .eq('status', 'PENDING')
          .order('planned_date', ascending: true)
          .range(offset, offset + limit - 1);

      final plans = (response as List)
          .map((json) => AddPercaPlanModel.fromJson(json))
          .toList();

      _log('Successfully fetched ${plans.length} pending plans');
      return plans;
    } catch (e) {
      _log('Error fetching pending plans: $e', level: 'ERROR');
      throw Exception('Gagal mengambil daftar rencana yang menunggu: $e');
    }
  }

  /// Mengambil rencana berdasarkan ID
  Future<AddPercaPlanModel> getPlanById(String planId) async {
    _log('Fetching plan by ID: $planId...');
    try {
      final response = await _supabase
          .from('percas_plans')
          .select(
            'id, id_factory, planned_date, status, notes, created_by, created_at, updated_at',
          )
          .eq('id', planId)
          .single();

      final plan = AddPercaPlanModel.fromJson(response);
      _log('Successfully fetched plan: $planId');
      return plan;
    } catch (e) {
      _log('Error fetching plan by ID: $e', level: 'ERROR');
      throw Exception('Gagal mengambil rencana dengan ID $planId: $e');
    }
  }

  /// Mengambil rencana berdasarkan ID Factory
  Future<List<AddPercaPlanModel>> getPlansByFactory(
    String factoryId, {
    int page = 1,
    int limit = 20,
  }) async {
    _log('Fetching plans for factory: $factoryId (page: $page, limit: $limit)...');
    try {
      final offset = (page - 1) * limit;

      final response = await _supabase
          .from('percas_plans')
          .select(
            'id, id_factory, planned_date, status, notes, created_by, created_at, updated_at',
          )
          .eq('id_factory', factoryId)
          .order('planned_date', ascending: false)
          .range(offset, offset + limit - 1);

      final plans = (response as List)
          .map((json) => AddPercaPlanModel.fromJson(json))
          .toList();

      _log('Successfully fetched ${plans.length} plans for factory: $factoryId');
      return plans;
    } catch (e) {
      _log('Error fetching plans for factory: $e', level: 'ERROR');
      throw Exception('Gagal mengambil rencana untuk pabrik: $e');
    }
  }

  /// Menghitung jumlah rencana berdasarkan status
  Future<int> countPlansByStatus(String status) async {
    _log('Counting plans with status: $status...');
    try {
      final response = await _supabase
          .from('percas_plans')
          .select('id')
          .eq('status', status);

      final count = (response as List).length;
      _log('Successfully counted $count plans with status: $status');
      return count;
    } catch (e) {
      _log('Error counting plans: $e', level: 'ERROR');
      throw Exception('Gagal menghitung rencana: $e');
    }
  }

  // ===========================================================================
  // CREATE OPERATIONS
  // ===========================================================================

  /// Membuat rencana pengambilan perca baru (Admin only)
  /// Input: Factory ID dan Tanggal Rencana
  Future<AddPercaPlanModel> createPlan({
    required String idFactory,
    required DateTime plannedDate,
    required String createdBy,
  }) async {
    _log('Creating new plan for factory: $idFactory, date: $plannedDate...');
    try {
      final now = DateTime.now();
      final planData = {
        'id_factory': idFactory,
        'planned_date': plannedDate.toIso8601String().split('T')[0], // YYYY-MM-DD
        'status': 'PENDING',
        'notes': null,
        'created_by': createdBy,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('percas_plans')
          .insert([planData])
          .select(
            'id, id_factory, planned_date, status, notes, created_by, created_at, updated_at',
          )
          .single();

      final plan = AddPercaPlanModel.fromJson(response);
      _log('Successfully created plan: ${plan.id}');
      return plan;
    } catch (e) {
      _log('Error creating plan: $e', level: 'ERROR');
      throw Exception('Gagal membuat rencana baru: $e');
    }
  }

  // ===========================================================================
  // UPDATE OPERATIONS
  // ===========================================================================

  /// Menyetujui rencana (Manager only)
  /// Status berubah dari PENDING ke APPROVED
  Future<AddPercaPlanModel> approvePlan(String planId) async {
    _log('Approving plan: $planId...');
    try {
      final now = DateTime.now();

      final response = await _supabase
          .from('percas_plans')
          .update({
            'status': 'APPROVED',
            'notes': null,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', planId)
          .select(
            'id, id_factory, planned_date, status, notes, created_by, created_at, updated_at',
          )
          .single();

      final plan = AddPercaPlanModel.fromJson(response);
      _log('Successfully approved plan: $planId');
      return plan;
    } catch (e) {
      _log('Error approving plan: $e', level: 'ERROR');
      throw Exception('Gagal menyetujui rencana: $e');
    }
  }

  /// Menolak rencana (Manager only)
  /// Status berubah dari PENDING ke REJECTED + Catatan penolakan
  Future<AddPercaPlanModel> rejectPlan(
    String planId, {
    required String rejectionReason,
  }) async {
    _log('Rejecting plan: $planId with reason: $rejectionReason...');
    try {
      final now = DateTime.now();

      final response = await _supabase
          .from('percas_plans')
          .update({
            'status': 'REJECTED',
            'notes': rejectionReason,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', planId)
          .select(
            'id, id_factory, planned_date, status, notes, created_by, created_at, updated_at',
          )
          .single();

      final plan = AddPercaPlanModel.fromJson(response);
      _log('Successfully rejected plan: $planId');
      return plan;
    } catch (e) {
      _log('Error rejecting plan: $e', level: 'ERROR');
      throw Exception('Gagal menolak rencana: $e');
    }
  }

  /// Update rencana (Admin only)
  /// Bisa mengubah tanggal rencana jika masih PENDING
  Future<AddPercaPlanModel> updatePlan(
    String planId, {
    DateTime? plannedDate,
    String? notes,
  }) async {
    _log('Updating plan: $planId...');
    try {
      final now = DateTime.now();
      final updateData = <String, dynamic>{
        'updated_at': now.toIso8601String(),
      };

      if (plannedDate != null) {
        updateData['planned_date'] = plannedDate.toIso8601String().split('T')[0];
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      final response = await _supabase
          .from('percas_plans')
          .update(updateData)
          .eq('id', planId)
          .select(
            'id, id_factory, planned_date, status, notes, created_by, created_at, updated_at',
          )
          .single();

      final plan = AddPercaPlanModel.fromJson(response);
      _log('Successfully updated plan: $planId');
      return plan;
    } catch (e) {
      _log('Error updating plan: $e', level: 'ERROR');
      throw Exception('Gagal mengubah rencana: $e');
    }
  }

  // ===========================================================================
  // DELETE OPERATIONS
  // ===========================================================================

  /// Menghapus rencana (Admin only)
  /// Hanya bisa dihapus jika status PENDING
  Future<void> deletePlan(String planId) async {
    _log('Deleting plan: $planId...');
    try {
      await _supabase
          .from('percas_plans')
          .delete()
          .eq('id', planId);

      _log('Successfully deleted plan: $planId');
    } catch (e) {
      _log('Error deleting plan: $e', level: 'ERROR');
      throw Exception('Gagal menghapus rencana: $e');
    }
  }

  // ===========================================================================
  // STATS & HELPER OPERATIONS
  // ===========================================================================

  /// Mendapatkan statistik rencana
  Future<Map<String, int>> getPlanStats() async {
    _log('Fetching plan statistics...');
    try {
      final response = await _supabase
          .from('percas_plans')
          .select('status')
          .order('status');

      final stats = <String, int>{
        'PENDING': 0,
        'APPROVED': 0,
        'REJECTED': 0,
      };

      for (final plan in (response as List)) {
        final status = plan['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      _log('Plan statistics: $stats');
      return stats;
    } catch (e) {
      _log('Error fetching plan statistics: $e', level: 'ERROR');
      throw Exception('Gagal mengambil statistik rencana: $e');
    }
  }
}
