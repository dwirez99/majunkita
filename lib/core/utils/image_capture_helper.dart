import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


/// Kelas helper untuk mengelola alur pengambilan gambar, pratinjau, dan pengiriman.
class ImageCaptureHelper {
  /// Fungsi utama yang mengorkestrasi seluruh proses.
  ///
  /// [context]: BuildContext untuk menampilkan dialog.
  /// [source]: Sumber gambar (kamera atau galeri). Default: kamera.
  /// [onSubmit]: Fungsi yang akan dijalankan saat tombol "GUNAKAN" ditekan.
  ///            Fungsi ini harus menerima File gambar dan bersifat async.
  static Future<void> showCaptureFlow({
    required BuildContext context,
    required Future<void> Function(File imageFile) onSubmit,
    ImageSource source = ImageSource.camera,
  }) async {
    final ImagePicker picker = ImagePicker();

    // Loop untuk handle "Foto Ulang"
    while (true) {
      // 1. Buka Kamera atau Galeri
      final XFile? imageXFile = await picker.pickImage(source: source);

      // Jika pengguna tidak mengambil gambar (menekan back), hentikan proses.
      if (imageXFile == null) return;

      final File imageFile = File(imageXFile.path);

      // Check if the context is still mounted before using it
      if (!context.mounted) return;

      // 2. Tampilkan Pop-out Pratinjau
      final bool? shouldSubmit = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Pengguna harus memilih salah satu tombol
        builder: (ctx) => _PreviewDialog(imageFile: imageFile),
      );

      // 3. Proses Aksi Pengguna
      if (shouldSubmit == true) {
        // Pengguna menekan "GUNAKAN"
        try {
          // Check if the context is still mounted before using it
          if (!context.mounted) return;

          // Tampilkan loading indicator di atas layar
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );

          // Jalankan fungsi onSubmit yang spesifik dari fitur
          await onSubmit(imageFile);

          // Check if the context is still mounted before using it
          if (!context.mounted) return;

          // Tutup loading indicator
          Navigator.of(context).pop();

          // Check if the context is still mounted before using it
          if (!context.mounted) return;

          // Tampilkan notifikasi sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil dikirim'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          // Check if the context is still mounted before using it
          if (!context.mounted) return;

          // Jika terjadi error saat submit, tutup loading dan tampilkan pesan
          Navigator.of(context).pop();

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim: ${e.toString()}')),
          );
        }
        break; // Keluar dari loop setelah berhasil
      } else if (shouldSubmit == false) {
        // Pengguna menekan "Foto Ulang", loop akan berlanjut
        continue;
      } else {
        // Pengguna menutup dialog (misal: back button), hentikan proses
        break;
      }
    }
  }
}

/// Widget internal untuk dialog pratinjau.
class _PreviewDialog extends StatelessWidget {
  final File imageFile;
  const _PreviewDialog({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pratinjau Kirim'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      content: Image.file(imageFile),
      actions: [
        // Tombol "Foto Ulang"
        TextButton(
          onPressed:
              () => Navigator.of(context).pop(false), // Mengembalikan false
          child: const Text('FOTO ULANG'),
        ),
        // Tombol "GUNAKAN"
        ElevatedButton(
          onPressed:
              () => Navigator.of(context).pop(true), // Mengembalikan true
          child: const Text('GUNAKAN'),
        ),
      ],
    );
  }
}
