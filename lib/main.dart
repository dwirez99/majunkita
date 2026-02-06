// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentations/screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // validasi key
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null ||
        supabaseUrl.isEmpty ||
        supabaseAnonKey == null ||
        supabaseAnonKey.isEmpty) {
      throw Exception(
        'Supabase URL atau Anon Key tidak ditemukan dalam file .env',
      );
    }
    // Initialize Supabase
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    // Run the app within ProviderScope for Riverpod
    runApp(const ProviderScope(child: MyApp()));
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
                const Text(
                  'Error during app initialization:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
      home: const AuthWrapper(), // Use AuthWrapper instead of LoginScreen
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
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      setState(() {
        userRole = response['role'] as String?;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<BottomNavigationBarItem> _getNavigationItems() {
    if (userRole == 'admin') {
      return const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Menu Awal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Ambil Perca',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Ambil Majun',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.delivery_dining),
          label: 'Pengiriman',
        ),
      ];
    } else if (userRole == 'manager') {
      return const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Menu Awal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Laporan',
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
         body: Center(
           child: Text('Selected Index: $_selectedIndex'),
         ),
      bottomNavigationBar: userRole != null
          ? BottomNavigationBar(
              type: BottomNavigationBarType
                  .fixed, // This ensures all tabs are visible
              items: _getNavigationItems(),
              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.green,
              showUnselectedLabels: true,
              onTap: _onItemTapped,
            )
          : null,
    );
  }
}
