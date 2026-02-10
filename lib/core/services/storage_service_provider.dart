import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/supabase_client_api.dart';
import 'storage_service.dart';

/// Provider untuk StorageService
/// Menggunakan supabaseClientProvider sebagai dependency
final storageServiceProvider = Provider<StorageService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return StorageService(supabase);
});
