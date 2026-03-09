import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Utility untuk mengompresi gambar sebelum diunggah ke storage.
class ImageCompressor {
  /// Mengompresi [file] dan mengembalikan [File] terkompresi.
  ///
  /// Gambar dikompres dengan kualitas 80. Parameter [minWidth] dan [minHeight]
  /// adalah dimensi minimum hasil kompres (1024px): gambar yang lebih besar
  /// akan diperkecil hingga salah satu sisinya mencapai 1024px, sedangkan
  /// gambar yang sudah lebih kecil tidak akan diperbesar.
  /// File hasil kompres disimpan di direktori sementara perangkat.
  /// Jika kompres gagal, file asli dikembalikan.
  static Future<File> compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed${p.extension(file.path)}',
      );
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
      );
      return result != null ? File(result.path) : file;
    } catch (_) {
      // Jika kompres gagal, kembalikan file asli agar upload tetap berjalan
      return file;
    }
  }
}
