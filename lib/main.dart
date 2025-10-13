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
      
      
      home: const MainScreen(),
    );
    
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  // For now, assuming admin role is true. You can modify this based on your authentication logic
  bool isAdmin = true;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(), // Index 0
    Text('Halaman Ambil Perca'), // Index 1
    Text('Halaman Ambil Majun'), // Index 2
    Text('Halaman Pengiriman'), // Index 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: isAdmin ? BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // This ensures all tabs are visible
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Menu Awal'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Ambil Perca'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Ambil Majun'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Pengiriman'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ) : null, // Only show bottom navigation bar for admin users
    );
  }
}