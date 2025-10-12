// lib/features/dashboard/presentation/widgets/quick_access_buttons.dart
import 'package:flutter/material.dart';

class QuickAccessButtons extends StatelessWidget {
  const QuickAccessButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Akses Cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0, // Jarak horizontal antar tombol
          runSpacing: 8.0, // Jarak vertical jika tombol pindah baris
          children: [
            SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 3, // 48 = padding + spacing
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Ambil Perca', 
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 3,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Setor Majun',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 3,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Kirim Majun',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ],
    );
  }
}