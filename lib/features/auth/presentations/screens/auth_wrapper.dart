import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/auth_provider.dart';
import '../../../Dashboard/presentations/screens/dashboard_admin_screen.dart';
import '../../../Dashboard/presentations/screens/dashboard_manager_screen.dart';
import '../../../Dashboard/presentations/screens/dashboard_driver_screen.dart';
import 'login_screen.dart';

/// AuthWrapper: Wrapper yang mendengarkan status autentikasi
/// dan menampilkan screen yang sesuai
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state provider
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (authData) {
        final user = authData.session?.user;

        // Jika tidak ada user, tampilkan Login Screen
        if (user == null) {
          return const LoginScreen();
        }

        // Jika ada user, ambil profil untuk cek role
        final userProfileAsync = ref.watch(userProfileProvider);

        return userProfileAsync.when(
          data: (profile) {
            if (profile == null) {
              // Profile belum ada, tampilkan loading
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = profile['role'] as String?;

            // Route berdasarkan role
            switch (role) {
              case 'manager':
                return const DashboardManagerScreen();
              case 'admin':
                return const DashboarAdminScreen();
              case 'driver':
                return const DashboardDriverScreen();
              default:
                // Role tidak dikenal
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Role tidak valid',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Role: ${role ?? "Unknown"}'),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            await ref.read(authRepositoryProvider).signOut();
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  ),
                );
            }
          },
          loading:
              () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
          error:
              (error, stack) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          await ref.read(authRepositoryProvider).signOut();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Authentication Error',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
    );
  }
}
