import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../../manage_factories/data/models/factory_model.dart';
import '../../data/models/perca_stock_model.dart';
import '../../data/repositories/perca_repository.dart';

// 1. Provider untuk Repository
final percaRepositoryProvider = Provider<PercaRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PercaRepository(supabase);
});

// 2. Provider untuk mengambil daftar Factory (untuk form dropdown)
final factoryListProvider = FutureProvider<List<FactoryModel>>((ref) {
  return ref.watch(percaRepositoryProvider).getFactoryList();
});

// 2b. Provider untuk mengambil riwayat pengambilan perca
final percaHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(percaRepositoryProvider).getPercaHistory();
});

// 2c. Provider untuk statistik bulanan
final percaMonthlyStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  final history = await ref.watch(percaHistoryProvider.future);
  
  Map<String, double> stats = {};
  
  for (var item in history) {
    if (item['date_entry'] != null && item['weight'] != null) {
      try {
        final date = DateTime.parse(item['date_entry'].toString());
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        final weight = double.tryParse(item['weight'].toString()) ?? 0.0;
        
        if (stats.containsKey(monthKey)) {
          stats[monthKey] = stats[monthKey]! + weight;
        } else {
          stats[monthKey] = weight;
        }
      } catch (e) {
        // Skip invalid date
      }
    }
  }
  
  return stats;
});

// 3. Notifier untuk menangani proses penambahan stok
final addPercaNotifierProvider =
    AsyncNotifierProvider<AddPercaNotifier, void>(AddPercaNotifier.new);

class AddPercaNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Tidak ada state awal yang perlu dibangun
  }

  // Business logic: Menambah single stock
  Future<void> addSinglePercasStock(PercasStock data, File imageFile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(percaRepositoryProvider);
      
      // 1. Upload gambar dan dapatkan URL
      final imageUrl = await repository.uploadImageToStorage(imageFile);
      
      // 2. Buat stock object final dengan URL gambar
      final finalStock = PercasStock(
        idFactory: data.idFactory,
        dateEntry: data.dateEntry,
        percaType: data.percaType,
        weight: data.weight,
        deliveryProof: imageUrl,
      );
      
      // 3. Simpan ke database
      await repository.saveStockToDatabase(finalStock);
    });
  }

  // Business logic: Menambah multiple stocks dengan satu bukti gambar
  Future<void> addMultiplePercaStocks(List<Map<String, dynamic>> stockList, File imageFile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Logging untuk debug - akan dihapus di production
      // print("Starting to add multiple stocks: ${stockList.length} items");
      
      final repository = ref.read(percaRepositoryProvider);
      
      // 1. Upload gambar sekali dan dapatkan URL
      // print("Uploading image to Supabase Storage...");
      final imageUrl = await repository.uploadImageToStorage(imageFile);
      // print("Image uploaded successfully: $imageUrl");
      
      // 2. Konversi raw data menjadi PercasStock objects dengan URL yang sama
      final List<PercasStock> stockObjects = [];
      for (int i = 0; i < stockList.length; i++) {
        final stockData = stockList[i];
        // print("Processing stock ${i + 1}/${stockList.length}: ${stockData['jenis']}");
        
        final stock = PercasStock(
          idFactory: stockData['idFactory'],
          dateEntry: stockData['dateEntry'],
          percaType: stockData['jenis'],
          weight: stockData['weight'],
          deliveryProof: imageUrl, // URL yang sama untuk semua stok
        );
        
        stockObjects.add(stock);
      }
      
      // 3. Simpan semua stocks ke database sekaligus
      // print("Saving all stocks to database...");
      await repository.saveMultipleStocksToDatabase(stockObjects);
      // print("All stocks saved successfully!");
    });
  }
}