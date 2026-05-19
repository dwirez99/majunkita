import 'package:flutter_test/flutter_test.dart';```dart

import 'package:mockito/mockito.dart';import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/annotations.dart';import 'package:mockito/mockito.dart';

import 'package:supabase_flutter/supabase_flutter.dart';import 'package:mockito/annotations.dart';

import 'package:majunkita/features/Dashboard/data/repositories/dashboard_repository.dart';import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:majunkita/features/Dashboard/data/models/admin_dashboard_models.dart';import 'package:majunkita/features/Dashboard/data/repositories/dashboard_repository.dart';

import 'package:majunkita/features/Dashboard/data/models/admin_dashboard_models.dart';

import 'dashboard_repository_test.mocks.dart';

import 'dashboard_repository_test.mocks.dart';

@GenerateMocks([SupabaseClient, PostgrestFilterBuilder])

void main() {@GenerateMocks([SupabaseClient, GoTrueClient, PostgrestFilterBuilder, PostgrestTransformBuilder, User])

  late MockSupabaseClient mockSupabaseClient;void main() {

  late DashboardRepository repository;  late MockSupabaseClient mockSupabaseClient;

  late DashboardRepository repository;

  setUp(() {

    mockSupabaseClient = MockSupabaseClient();  setUp(() {

    repository = DashboardRepository(mockSupabaseClient);    mockSupabaseClient = MockSupabaseClient();

  });    repository = DashboardRepository(mockSupabaseClient);

  });

  group('DashboardRepository', () {

    test('getAdminDashboardSummary returns expected data on success', () async {  group('DashboardRepository', () {

      final mockData = {    test('getAdminDashboardSummary returns expected data on success', () async {

        'total_active_majun': 100,      final mockData = {

        'total_active_perca': 50,        'total_active_majun': 100,

      };        'total_active_perca': 50,

      };

      final mockFilterBuilder = MockPostgrestFilterBuilder<dynamic>();      

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabaseClient.rpc('get_admin_dashboard_summary'))      when(mockSupabaseClient.rpc('get_admin_dashboard_summary'))

          .thenReturn(mockFilterBuilder);          .thenReturn(mockFilterBuilder);

                when(mockFilterBuilder.then(any, onError: anyNamed('onError')))

      when(mockFilterBuilder.then(any, onError: anyNamed('onError')))          .thenAnswer((invocation) {

          .thenAnswer((invocation) {        final onValue = invocation.positionalArguments[0] as Function(dynamic);

        final onValue = invocation.positionalArguments[0] as Function(dynamic);        return Future.value(onValue(mockData));

        return Future.value(onValue(mockData));       });

      });

      final result = await repository.getAdminDashboardSummary();

      final result = await repository.getAdminDashboardSummary();

      expect(result, isA<AdminDashboardSummary>());

      expect(result, isA<AdminDashboardSummary>());      verify(mockSupabaseClient.rpc('get_admin_dashboard_summary')).called(1);

      verify(mockSupabaseClient.rpc('get_admin_dashboard_summary')).called(1);    });

    });

    test('getAdminDashboardSummary throws error on failure', () async {

    test('getAdminDashboardSummary throws error on failure', () async {      final mockFilterBuilder = MockPostgrestFilterBuilder();

      final mockFilterBuilder = MockPostgrestFilterBuilder<dynamic>();      when(mockSupabaseClient.rpc('get_admin_dashboard_summary'))

                .thenReturn(mockFilterBuilder);

      when(mockSupabaseClient.rpc('get_admin_dashboard_summary'))      when(mockFilterBuilder.then(any, onError: anyNamed('onError')))

          .thenReturn(mockFilterBuilder);          .thenThrow(Exception('RPC error'));

          

      when(mockFilterBuilder.then(any, onError: anyNamed('onError')))      expect(() => repository.getAdminDashboardSummary(), throwsException);

          .thenThrow(Exception('RPC error'));    });

  });

      expect(() => repository.getAdminDashboardSummary(), throwsException);}

    });```

  });
}