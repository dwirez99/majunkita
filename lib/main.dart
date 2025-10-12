// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/Dashboard/presentations/screens/dashboard_admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
    } catch (envError) {
      // Fallback: set environment variables directly
      dotenv.env['SUPABASE_URL'] = 'https://fswmiqldurziscghckpc.supabase.co';
      dotenv.env['SUPABASE_ANON_KEY'] = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzd21pcWxkdXJ6aXNjZ2hja3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5ODg0MDQsImV4cCI6MjA3NDU2NDQwNH0.5XHO6Da8wydaGn3_fqYrN21REXL2IKfSExcMXKJTnZ4';
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    
  } catch (e) {
    // Show error screen if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Initialization Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error during app initialization:', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Majunkita',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DashboardScreen(),
    );
  }
}