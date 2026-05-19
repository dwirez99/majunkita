import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:majunkita/features/manage_factories/data/repositories/factory_repository.dart';
import 'package:majunkita/features/manage_factories/data/models/factory_model.dart';
import 'factory_repository_test.mocks.dart';

@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder, PostgrestTransformBuilder])
void main() {
  late MockSupabaseClient mockSupabaseClient;
  late FactoryRepository repository;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    repository = FactoryRepository(mockSupabaseClient);
  });

  group('FactoryRepository', () {
    test('getAllFactories returns list of FactoryModel on success', () async {
      final mockData = [{'id': '1', 'factory_name': 'Factory A', 'address': 'Almt A', 'no_telp': '08111'}];

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder1 = MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      when(mockSupabaseClient.from('factories')).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select('id, factory_name, address, no_telp')).thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.order('factory_name', ascending: true)).thenAnswer((_) => mockTransformBuilder1);
      when(mockTransformBuilder1.range(any, any)).thenAnswer((_) => mockTransformBuilder1);
      
      when(mockTransformBuilder1.then(any, onError: anyNamed('onError'))).thenAnswer((invocation) {
        final onValue = invocation.positionalArguments[0];
        onValue(mockData);
        return Future.value();
      });

      final result = await repository.getAllFactories(page: 1, limit: 10);
      expect(result.length, 1);
      expect(result.first.factoryName, 'Factory A');
    });
  });
}
