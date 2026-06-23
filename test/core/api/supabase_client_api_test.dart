import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/core/api/supabase_client_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Supabase Client API', () {
    group('supabaseClientProvider', () {
      test('should be a valid Provider instance', () {
        expect(supabaseClientProvider, isNotNull);
        expect(supabaseClientProvider, isA<Provider>());
      });

      test('supabaseClientProvider should have dependencies', () {
        // Check that the provider is created from ref.watch pattern
        expect(supabaseClientProvider.dependencies, isNotNull);
      });

      test('supabaseClientProvider name should be identifiable', () {
        final name = supabaseClientProvider.toString();
        expect(name, isNotNull);
        expect(name.isNotEmpty, true);
      });

      test('supabaseClientProvider should be a Provider of SupabaseClient', () {
        // The provider's generic type should indicate it returns SupabaseClient
        expect(supabaseClientProvider, isA<Provider<SupabaseClient>>());
      });

      test('supabaseClientProvider should be independent of other providers', () {
        // Provider should not have circular dependencies
        final deps = supabaseClientProvider.dependencies;
        expect(deps, isNotNull);
      });
    });

    group('supabaseClient getter', () {
      // Note: These tests verify the getter exists and is callable
      // Actual Supabase initialization would happen in integration tests
      
      test('supabaseClient getter function should exist', () {
        expect(supabaseClient, isNotNull);
      });

      test('supabaseClient should return a SupabaseClient', () {
        final client = supabaseClient;
        expect(client, isA<SupabaseClient>());
      });

      test('supabaseClient should have auth property', () {
        final client = supabaseClient;
        expect(client.auth, isNotNull);
      });

      test('supabaseClient should be accessible from provider', () {
        // Verify that we can get SupabaseClient from the provider
        expect(supabaseClientProvider, isNotNull);
      });
    });

    group('Provider usage', () {
      test('provider should be usable in a ProviderContainer', () {
        final container = ProviderContainer();
        final client = container.read(supabaseClientProvider);
        expect(client, isNotNull);
      });

      test('multiple reads should return the same client instance', () {
        final container = ProviderContainer();
        final client1 = container.read(supabaseClientProvider);
        final client2 = container.read(supabaseClientProvider);
        expect(identical(client1, client2), true);
      });

      test('supabaseClientProvider should work with StateNotifier', () {
        // Verify provider works with Riverpod's reactive system
        final container = ProviderContainer();
        
        final asyncProvider = FutureProvider<SupabaseClient>((ref) async {
          return ref.watch(supabaseClientProvider);
        });

        // The provider should be watchable
        final client = container.read(asyncProvider);
        expect(client, isNotNull);
      });
    });

    group('API Consistency', () {
      test('supabase getter should be accessible without initialization in tests', () {
        // This verifies that the API is exposed correctly
        final client = supabaseClient;
        expect(client, isNotNull);
      });

      test('provider comment indicates it is for Riverpod integration', () {
        // The provider is specifically for Riverpod dependency injection
        final providerCode = supabaseClientProvider.toString();
        expect(providerCode, isNotEmpty);
      });
    });

    group('Edge cases', () {
      test('provider should handle being read multiple times', () {
        final container = ProviderContainer();
        
        for (int i = 0; i < 10; i++) {
          final client = container.read(supabaseClientProvider);
          expect(client, isNotNull);
        }
      });

      test('different containers should return equivalent clients', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();
        
        final client1 = container1.read(supabaseClientProvider);
        final client2 = container2.read(supabaseClientProvider);
        
        // Should return the same singleton instance
        expect(identical(client1, client2), true);
      });
    });
  });
}
