// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Pastikan Flutter binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase! Ini adalah langkah krusial.
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',       // Ganti dengan URL Anda
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // Ganti dengan Anon Key Anda
  );

  runApp(
    // ProviderScope diperlukan agar semua provider Riverpod berfungsi
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ... sisa kode aplikasi Anda
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Supabase Setup')),
        body: const Center(child: Text('Setup Berhasil!')),
      ),
    );
  }
}