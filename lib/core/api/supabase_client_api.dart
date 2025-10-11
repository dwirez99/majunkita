// lib/core/api/supabase_client.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Dapatkan instance klien Supabase global
//    Instance ini baru akan aktif setelah Supabase diinisialisasi di main.dart
final supabaseClient = Supabase.instance.client;

// 2. Buat Provider untuk menyediakan instance klien
//    Ini adalah cara Riverpod agar kita bisa mengakses atau men-mock klien Supabase
//    dari mana saja di dalam aplikasi menggunakan ref.watch() atau ref.read().
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return supabaseClient;
});