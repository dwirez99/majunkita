@TestOn('vm')
import 'package:test/test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:majunkita/features/manage_percas/data/repositories/perca_transactions_repository.dart';
import 'package:majunkita/features/manage_tailors/data/models/tailor_model.dart';
import 'perca_transactions_repository_test.mocks.dart';

@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late PercaTransactionsRepository repository;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    repository = PercaTransactionsRepository(mockSupabaseClient);
  });

  group('PercaTransactionsRepository', () {
    test('getTailorList returns list of TailorModel', () async {
      final mockData = [
        {
          'id': '1',
          'name': 'Budi',
          'address': 'Jl. Mawar',
          'no_telp': '08123',
          'created_at': '2026-05-19',
          'tailor_images': 'image.png',
          'total_stock': 5,
        },
      ];

      final qb = MockSupabaseQueryBuilder();
      final fb = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

  when(mockSupabaseClient.from('tailors')).thenAnswer((_) => qb);
      when(
        qb.select(
          'id, name, address, no_telp, created_at, tailor_images, total_stock',
        ),
  ).thenAnswer((_) => fb);
      when(
        fb.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final onValue = invocation.positionalArguments[0] as Function;
        return Future.value(onValue(mockData));
      });

      final result = await repository.getTailorList();

      expect(result, isA<List<TailorModel>>());
      expect(result.first.name, 'Budi');
    });

    test('getAvailableSackSummary returns list of summary maps', () async {
      final response = [
        {
          'sack_code': 'K-5',
          'perca_type': 'kaos',
          'total_sacks': 2,
          'total_weight': 10.0,
        },
      ];

      final fb = MockPostgrestFilterBuilder<dynamic>();

    when(mockSupabaseClient.rpc('get_available_sack_summary'))
      .thenAnswer((_) => fb);
      when(
        fb.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final onValue = invocation.positionalArguments[0] as Function;
        return Future.value(onValue(response));
      });

      final result = await repository.getAvailableSackSummary();

      expect(result.length, 1);
      expect(result.first['sack_code'], 'K-5');
    });

    test('getAvailableSackCount returns number of available sacks', () async {
      final qb = MockSupabaseQueryBuilder();
      final fb = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

  when(mockSupabaseClient.from('percas_stock')).thenAnswer((_) => qb);
  when(qb.select('id')).thenAnswer((_) => fb);
  when(fb.eq('sack_code', 'K-5')).thenAnswer((_) => fb);
  when(fb.eq('status', 'tersedia')).thenAnswer((_) => fb);
      when(
        fb.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final onValue = invocation.positionalArguments[0] as Function;
        return Future.value(onValue([{ 'id': 1 }, { 'id': 2 }]));
      });

      final result = await repository.getAvailableSackCount('K-5');

      expect(result, 2);
    });

    test('processTransactionBySackCode returns RPC response', () async {
      final response = {'success': true, 'processed': 2};
      final fb = MockPostgrestFilterBuilder<dynamic>();
      final dateEntry = DateTime(2026, 5, 19);

      when(
        mockSupabaseClient.rpc(
          'process_transaction_by_sack_code',
          params: anyNamed('params'),
        ),
      ).thenAnswer((_) => fb);
      when(
        fb.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final onValue = invocation.positionalArguments[0] as Function;
        return Future.value(onValue(response));
      });

      final result = await repository.processTransactionBySackCode(
        idTailor: '1',
        staffId: 'staff-1',
        sackCode: 'K-5',
        sackCount: 2,
        dateEntry: dateEntry,
      );

      expect(result['success'], true);
      final captured =
          verify(
            mockSupabaseClient.rpc(
              'process_transaction_by_sack_code',
              params: captureAnyNamed('params'),
            ),
          ).captured;
      final params = captured.first as Map<String, dynamic>;
      expect(params['p_date_entry'], '2026-05-19');
    });

    test('getMonthlyTransactionStats aggregates weights by month', () async {
      final qb = MockSupabaseQueryBuilder();
      final fb = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

  when(mockSupabaseClient.from('perca_transactions')).thenAnswer((_) => qb);
  when(qb.select('date_entry, weight')).thenAnswer((_) => fb);
  when(fb.order('date_entry', ascending: true)).thenAnswer((_) => fb);
      when(
        fb.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final onValue = invocation.positionalArguments[0] as Function;
        return Future.value(
          onValue([
            {'date_entry': '2026-05-01', 'weight': 5},
            {'date_entry': '2026-05-10', 'weight': 3.5},
            {'date_entry': 'invalid', 'weight': 10},
          ]),
        );
      });

      final result = await repository.getMonthlyTransactionStats();

      expect(result['2026-05'], closeTo(8.5, 0.0001));
    });

    test('getTotalWeightPerTailor aggregates weight by tailor', () async {
      final qb = MockSupabaseQueryBuilder();
      final fb = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

  when(mockSupabaseClient.from('perca_transactions')).thenAnswer((_) => qb);
  when(qb.select('id_tailors, weight, tailors(name)')).thenAnswer((_) => fb);
      when(
        fb.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final onValue = invocation.positionalArguments[0] as Function;
        return Future.value(
          onValue([
            {
              'id_tailors': '1',
              'weight': 5,
              'tailors': {'name': 'Budi'},
            },
            {
              'id_tailors': '1',
              'weight': 2.5,
              'tailors': {'name': 'Budi'},
            },
            {
              'id_tailors': '2',
              'weight': 4,
              'tailors': {'name': 'Sari'},
            },
          ]),
        );
      });

      final result = await repository.getTotalWeightPerTailor();

      expect(result['Budi'], closeTo(7.5, 0.0001));
      expect(result['Sari'], closeTo(4, 0.0001));
    });
  });
}