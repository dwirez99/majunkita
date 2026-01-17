// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/Dashboard/presentations/screens/dashboard_admin_screen.dart';
import 'features/auth/presentations/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Validate that required environment variables are present
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }

    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }

    // Initialize Supabase
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    // Show error screen if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Configuration Error'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Konfigurasi Aplikasi Gagal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cara Memperbaiki:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text('1. Pastikan file .env ada di root project'),
                        SizedBox(height: 8),
                        Text('2. Isi SUPABASE_URL dan SUPABASE_ANON_KEY'),
                        SizedBox(height: 8),
                        Text('3. Restart aplikasi'),
                        SizedBox(height: 12),
                        Text(
                          'Lihat .env.example untuk template',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      // Start with AuthWrapper to check authentication state
      home: const AuthWrapper(),
    );
  }
}

// AuthWrapper: Checks if user is logged in and routes accordingly
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  User? _user;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _setupAuthListener();
  }

  // Check initial authentication state
  Future<void> _checkAuthState() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final user = session?.user;

      if (user != null) {
        // User is logged in, fetch their role
        final profile =
            await Supabase.instance.client
                .from('profiles')
                .select('role')
                .eq('id', user.id)
                .single();

        setState(() {
          _user = user;
          _userRole = profile['role'] as String?;
          _isLoading = false;
        });
      } else {
        // User is not logged in
        setState(() {
          _user = null;
          _userRole = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error fetching user data, treat as not logged in
      setState(() {
        _user = null;
        _userRole = null;
        _isLoading = false;
      });
    }
  }

  // Listen to auth state changes
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _checkAuthState();
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() {
          _user = null;
          _userRole = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking auth state
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // User is not logged in, show login screen
    if (_user == null) {
      return const LoginScreen();
    }

    // User is logged in, route to appropriate dashboard based on role
    return _getScreenForRole(_userRole);
  }

  Widget _getScreenForRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return const MainScreen(isAdmin: true);
      case 'manager':
        return const MainScreen(isAdmin: false);
      case 'driver':
        // TODO: Create driver dashboard
        return const Scaffold(
          body: Center(child: Text('Driver Dashboard (Coming Soon)')),
        );
      case 'partner_pabrik':
        // TODO: Create partner dashboard
        return const Scaffold(
          body: Center(child: Text('Partner Dashboard (Coming Soon)')),
        );
      default:
        // Unknown role, show error and logout
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Role tidak dikenali',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Hubungi administrator untuk bantuan'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class MainScreen extends StatefulWidget {
  final bool isAdmin;

  const MainScreen({super.key, required this.isAdmin});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

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
      bottomNavigationBar:
          widget.isAdmin
              ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                items: const <BottomNavigationBarItem>[
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
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                onTap: _onItemTapped,
              )
              : BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                onTap: _onItemTapped,
              ),
    );
  }
}
