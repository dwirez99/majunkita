import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/success_dialog.dart'; // Impor dialog sukses kita

/// Kelas helper untuk mengelola alur pengambilan gambar, pratinjau, dan pengiriman.
class ImageCaptureHelper {
  /// Fungsi utama yang mengorkestrasi seluruh proses.
  ///
  /// [context]: BuildContext untuk menampilkan dialog.
  /// [onSubmit]: Fungsi yang akan dijalankan saat tombol "Kirim Bukti" ditekan.
  ///            Fungsi ini harus menerima File gambar dan bersifat async.
  static Future<void> showCaptureFlow({
    required BuildContext context,
    required Future<void> Function(File imageFile) onSubmit,
  }) async {
    final ImagePicker picker = ImagePicker();

    // Loop untuk handle "Foto Ulang"
    while (true) {
      // 1. Buka Kamera
      final XFile? imageXFile = await picker.pickImage(source: ImageSource.camera);

      // Jika pengguna tidak mengambil gambar (menekan back), hentikan proses.
      if (imageXFile == null) return;

      final File imageFile = File(imageXFile.path);

      // 2. Tampilkan Pop-out Pratinjau
      final bool? shouldSubmit = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Pengguna harus memilih salah satu tombol
        builder: (ctx) => _PreviewDialog(imageFile: imageFile),
      );

      // 3. Proses Aksi Pengguna
      if (shouldSubmit == true) {
        // Pengguna menekan "Kirim Bukti"
        try {
          // Tampilkan loading indicator di atas layar
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );

          // Jalankan fungsi onSubmit yang spesifik dari fitur
          await onSubmit(imageFile);

          // Tutup loading indicator
          Navigator.of(context).pop();

          // Tampilkan notifikasi sukses
          showSuccessDialog(context);
        } catch (e) {
          // Jika terjadi error saat submit, tutup loading dan tampilkan pesan
          Navigator.of(context).pop();
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
          onPressed: () => Navigator.of(context).pop(false), // Mengembalikan false
          child: const Text('FOTO ULANG'),
        ),
        // Tombol "Kirim Bukti"
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true), // Mengembalikan true
          child: const Text('KIRIM BUKTI'),
        ),
      ],
    );
  }
}