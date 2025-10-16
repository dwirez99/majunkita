import 'dart:io'; // Untuk tipe data File
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/factory_models.dart';
import '../models/perca_stock_model.dart';
import '../../../../core/services/drive_uploader_services.dart';

class PercaRepository {
  final SupabaseClient _supabase;
  final DriveUploaderService _driveUploader; 

  PercaRepository(this._supabase, this._driveUploader); // <-- UPDATE CONSTRUCTOR

  // 1. Mengambil daftar pabrik untuk dropdown
  Future<List<Pabrik>> getPabrikList() async {
    try {
      final data = await _supabase.from('pabrik').select('id, nama_pabrik');
      return data.map((item) => Pabrik.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar pabrik: $e');
    }
  }

  // 2. Menambahkan entri stok perca baru (proses bisnis inti)
   Future<void> addPercaStock(PercaStock stockData, File imageFile) async {
    try {
      // Langkah A: Upload gambar ke Google Drive menggunakan service kita
      const driveFolderId = '1ZX8ktBSzK3T2f6pdVyD7dvw-Ar13__0o';
      final driveFileId = await _driveUploader.uploadFile(imageFile, driveFolderId);

      if (driveFileId == null) {
        throw Exception('Gagal mengunggah bukti ke Google Drive.');
      }

      // Langkah B: Buat URL sederhana atau simpan ID-nya
      // Google Drive tidak punya URL publik sesederhana Supabase.
      // Menyimpan ID adalah yang paling umum.
      final buktiUrl = 'https://drive.google.com/file/d/$driveFileId';

      // Langkah C: Buat objek PercaStock final dengan URL/ID dari Drive
      final finalStockData = PercaStock(
        idPabrik: stockData.idPabrik,
        tglMasuk: stockData.tglMasuk,
        jenis: stockData.jenis,
        berat: stockData.berat,
        buktiAmbilUrl: buktiUrl, // Simpan URL/ID Drive
      );

      // Langkah D: Simpan data ke tabel 'stok_perca' di Supabase
      await _supabase.from('stok_perca').insert(finalStockData.toJson());

    } catch (e) {
      throw Exception('Gagal menambahkan stok perca: $e');
    }
  }
}