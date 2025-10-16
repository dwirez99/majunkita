import 'package:flutter/material.dart';

/// Menampilkan dialog sukses sederhana yang akan hilang setelah beberapa detik.
void showSuccessDialog(BuildContext context, {String message = 'Bukti Berhasil dikirim'}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      // Otomatis menutup dialog setelah 2 detik
      Future.delayed(const Duration(seconds: 2), () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });

      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text(
              'Bukti Berhasil dikirim',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    },
  );
}