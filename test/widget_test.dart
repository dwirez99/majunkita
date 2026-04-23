// Basic smoke test for Majunkita app.
// Ensures the app can be constructed without crashing.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:majunkita/main.dart';
import 'package:majunkita/features/auth/domain/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mockito/mockito.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // MyApp requires a ProviderScope ancestor for Riverpod providers.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
          authStateProvider.overrideWith(
            (ref) =>
                Stream.value(AuthState(AuthChangeEvent.initialSession, null)),
          ),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the app renders (LoginScreen shows 'MAJUNKITA' title).
    expect(find.text('MAJUNKITA'), findsOneWidget);
  });
}
