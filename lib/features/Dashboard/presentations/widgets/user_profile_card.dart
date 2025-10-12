// lib/features/dashboard/presentation/widgets/user_profile_card.dart
import 'package:flutter/material.dart';

class UserProfileCard extends StatelessWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: const Text('Doni Setiawan', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('ADMIN'),
      ),
    );
  }
}