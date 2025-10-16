import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/supabase_client_api.dart';
import '../data/models/factory_models.dart';
import '../data/models/perca_stock_model.dart';
import '../data/repositories/perca_repository.dart';
import '../../../core/services/drive_uploader_services.dart';


final driveUploaderProvider = Provider<DriveUploaderService>((ref) {
  return DriveUploaderService();
});

// 1. Provider untuk Repository
final percaRepositoryProvider = Provider<PercaRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final driveUploader = ref.watch(driveUploaderProvider); // <-- Ambil service-nya
  return PercaRepository(supabase, driveUploader); // <-- Berikan ke constructor
});

// 2. Provider untuk mengambil daftar pabrik (untuk form dropdown)
final pabrikListProvider = FutureProvider<List<Pabrik>>((ref) {
  return ref.watch(percaRepositoryProvider).getPabrikList();
});


// 3. Notifier untuk menangani proses penambahan stok
//    Menggunakan AsyncNotifier untuk menangani state loading/error/data dari sebuah aksi
final addPercaNotifierProvider =
    AsyncNotifierProvider<AddPercaNotifier, void>(AddPercaNotifier.new);

class AddPercaNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Tidak ada state awal yang perlu dibangun
  }

  Future<void> addPercaStock(PercaStock stockData, File imageFile) async {
    state = const AsyncValue.loading(); // Set state menjadi loading
    state = await AsyncValue.guard(() async {
      // Panggil method repository
      await ref.read(percaRepositoryProvider).addPercaStock(stockData, imageFile);
    });
  }
}