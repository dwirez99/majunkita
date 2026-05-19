import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:majunkita/features/manage_majun/data/repositories/majun_repository.dart';
import 'package:majunkita/features/manage_majun/data/model/majun_transactions_model.dart';
import 'package:majunkita/features/manage_tailors/data/models/tailor_model.dart';
import 'majun_repository_test.mocks.dart';

@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder, PostgrestTransformBuilder, GoTrueClient, User])
void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MajunRepository repository;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    repository = MajunRepository(mockSupabaseClient);
  });

  group('MajunRepository', () {
    test('getTailorList returns list of TailorModel', () async {
      final mockData = [{'id': '1', 'name': 'Budi', 'total_stock': 10}];
      
      final qb = MockSupabaseQueryBuilder();
      final fb = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

      when(mockSupabaseClient.from('tailors')).thenAnswer((_) => qb);
      when(qb.select('id, name, address, no_telp, created_at, tailor_images, total_stock, balance')).thenAnswer((_) => fb);
      
      when(fb.then(any, onError: anyNamed('onError'))).thenAnswer((invocation) {
        final onValue = invocation.positionalArguments[0];
        onValue(mockData);
        return Future.value();
      });

      final result = await repository.getTailorList();
      expect(result.length, 1);
      expect(result.first.name, 'Budi');
    });
  });
}
