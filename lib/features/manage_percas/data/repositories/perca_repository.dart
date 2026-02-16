import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../manage_factories/data/models/factory_model.dart';
import '../models/perca_stock_model.dart';

class PercaRepository {
  final SupabaseClient _supabase;

  PercaRepository(this._supabase);

  // 1. Mengambil daftar Factory untuk dropdown
  Future<List<FactoryModel>> getFactoryList() async {
    try {
      final data = await _supabase.from('factories').select('id, factory_name, address, no_telp');
      return data.map((item) => FactoryModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar Factory: $e');
    }
  }

  // 2. Upload gambar ke Supabase Storage
  Future<String> uploadImageToStorage(File imageFile) async {
    try {
      // Generate unique filenamet: konsep Anda benar tapi ada beberapa detail yang perlu diperbaiki agar aman dan kompatibel dengan Supabase Flutter SDK.
      final fileName = 'bukti_perca_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload ke bucket 'majunkita' folder 'stok_perca'
      final response = await _supabase.storage
          .from('majunkita')
          .upload('stok_perca/$fileName', imageFile);
      
      if (response.isEmpty) {
        throw Exception("Failed to upload image to Supabase Storage");
      }
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from('majunkita')
          .getPublicUrl('stok_perca/$fileName');
      
      return publicUrl;
    } catch (e) {
      throw Exception('Gagal upload gambar: $e');
    }
  }

  // 3. Simpan data stok ke database
  Future<void> saveStockToDatabase(PercasStock stockData) async {
    try {
      await _supabase.from('percas_stock').insert(stockData.toJson());
    } catch (e) {
      throw Exception('Gagal menyimpan stok ke database: $e');
    }
  }

  // 4. Simpan multiple stocks ke database
  Future<void> saveMultipleStocksToDatabase(List<PercasStock> stockList) async {
    try {
      final dataList = stockList.map((stock) => stock.toJson()).toList();
      await _supabase.from('percas_stock').insert(dataList);
    } catch (e) {
      throw Exception('Gagal menyimpan multiple stocks ke database: $e');
    }
  }

  // 5. Mengambil statistik perca per bulan
  Future<Map<String, double>> getMonthlyPercaStats() async {
    try {
      // Ambil data dari 12 bulan terakhir
      final thirteenMonthsAgo = DateTime.now().subtract(const Duration(days: 365));
      
      final data = await _supabase
          .from('percas_stock')
          .select('date_entry, weight')
          .gte('date_entry', thirteenMonthsAgo.toIso8601String().split('T')[0]);
      
      // Group by month dan sum weight
      final Map<String, double> monthlyStats = {};
      
      for (var item in data) {
        final dateEntry = DateTime.parse(item['date_entry'] as String);
        final monthKey = '${dateEntry.year}-${dateEntry.month.toString().padLeft(2, '0')}';
        final weight = double.tryParse(item['weight'].toString()) ?? 0;
        
        monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + weight;
      }
      
      return monthlyStats;
    } catch (e) {
      throw Exception('Gagal mengambil statistik perca: $e');
    }
  }
}