import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/factory_models.dart';
import '../models/perca_stock_model.dart';

class PercaRepository {
  final SupabaseClient _supabase;

  PercaRepository(this._supabase);

  // 1. Mengambil daftar pabrik untuk dropdown
  Future<List<Pabrik>> getPabrikList() async {
    try {
      final data = await _supabase.from('pabrik').select('id, nama_pabrik');
      return data.map((item) => Pabrik.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar pabrik: $e');
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
  Future<void> saveStockToDatabase(PercaStock stockData) async {
    try {
      await _supabase.from('stok_perca').insert(stockData.toJson());
    } catch (e) {
      throw Exception('Gagal menyimpan stok ke database: $e');
    }
  }

  // 4. Simpan multiple stocks ke database
  Future<void> saveMultipleStocksToDatabase(List<PercaStock> stockList) async {
    try {
      final dataList = stockList.map((stock) => stock.toJson()).toList();
      await _supabase.from('stok_perca').insert(dataList);
    } catch (e) {
      throw Exception('Gagal menyimpan multiple stocks ke database: $e');
    }
  }
}