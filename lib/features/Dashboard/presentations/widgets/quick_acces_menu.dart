// lib/features/dashboard/presentation/widgets/quick_access_buttons.dart
import 'package:flutter/material.dart';
import '../../../manage_percas/presentations/screens/add_perca_screen.dart';

class QuickAccessButtons extends StatelessWidget {
  const QuickAccessButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Akses Cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPercaScreen(),
                    ),
                  );
                },
                child: const Text('Ambil Perca', 
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Setor Majun',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
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