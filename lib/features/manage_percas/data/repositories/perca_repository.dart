import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../manage_factories/data/models/factory_model.dart';
import '../models/perca_stock_model.dart';
import '../../../../core/utils/image_compressor.dart';

class PercaRepository {
  final SupabaseClient _supabase;

  PercaRepository(this._supabase);

  // 1. Mengambil daftar Factory untuk dropdown
  Future<List<FactoryModel>> getFactoryList() async {
    try {
      final data = await _supabase
          .from('factories')
          .select('id, factory_name, address, no_telp');
      return data.map((item) => FactoryModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar Factory: $e');
    }
  }

  // 2. Upload gambar ke Supabase Storage
  Future<String> uploadImageToStorage(File imageFile) async {
    try {
      // Compress image before uploading
      final compressedFile = await ImageCompressor.compressImage(imageFile);

      // Generate unique filename
      final fileName =
          'bukti_perca_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload ke bucket 'majunkita' folder 'stok_perca'
      final response = await _supabase.storage
          .from('majunkita')
          .upload('stok_perca/$fileName', compressedFile);

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

  // 5. Ambil riwayat pengambilan perca
  Future<List<Map<String, dynamic>>> getPercaHistory() async {
    try {
      final data = await _supabase
          .from('percas_stock')
          .select(
            'id, id_factory, date_entry, perca_type, weight, delivery_proof, sack_code, status, created_at, factories(factory_name)',
          )
          .order('date_entry', ascending: false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Gagal mengambil riwayat perca: $e');
    }
  }
}
