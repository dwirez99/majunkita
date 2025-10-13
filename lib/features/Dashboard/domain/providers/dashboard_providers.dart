// lib/features/dashboard/domain/providers/dashboard_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../data/models/admin_dashboard_models.dart';
import '../../data/repositories/dashboard_repository.dart';

// Provider untuk Repository
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseClientProvider));
});

// Provider untuk Data Summary Dashboard Admin
final adminDashboardProvider = FutureProvider<AdminDashboardSummary>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getAdminDashboardSummary();
});