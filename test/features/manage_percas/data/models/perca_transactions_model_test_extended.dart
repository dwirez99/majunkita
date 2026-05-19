import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_percas/data/models/perca_transactions_model.dart';

void main() {
  group('PercaTransactionsModel', () {
    const testIdStockPerca = 'stock-perca-001';
    const testIdTailors = 'tailor-001';
    final testDateEntry = DateTime(2024, 7, 1);
    const testPercasType = 'kaos';
    const testWeight = 50.0;
    const testStaffId = 'staff-001';
    final testCreatedAt = DateTime(2024, 7, 1, 10, 30, 0);

    final testJson = {
      'id': 'trans-001',
      'id_stock_perca': testIdStockPerca,
      'id_tailors': testIdTailors,
      'date_entry': '2024-07-01',
      'percas_type': testPercasType,
      'weight': testWeight,
      'staff_id': testStaffId,
      'created_at': '2024-07-01T10:30:00',
    };

    late PercaTransactionsModel testModel;

    setUp(() {
      testModel = PercaTransactionsModel(
        id: 'trans-001',
        idStockPerca: testIdStockPerca,
        idTailors: testIdTailors,
        dateEntry: testDateEntry,
        percasType: testPercasType,
        weight: testWeight,
        staffId: testStaffId,
        createdAt: testCreatedAt,
      );
    });

    group('Constructor', () {
      test('should create PercaTransactionsModel with all fields', () {
        expect(testModel.id, 'trans-001');
        expect(testModel.idStockPerca, testIdStockPerca);
        expect(testModel.idTailors, testIdTailors);
        expect(testModel.dateEntry, testDateEntry);
        expect(testModel.percasType, testPercasType);
        expect(testModel.weight, testWeight);
        expect(testModel.staffId, testStaffId);
        expect(testModel.createdAt, testCreatedAt);
      });

      test('should create with nullable id', () {
        final model = PercaTransactionsModel(
          idStockPerca: testIdStockPerca,
          idTailors: testIdTailors,
          dateEntry: testDateEntry,
          percasType: testPercasType,
          weight: testWeight,
        );
        expect(model.id, isNull);
        expect(model.staffId, isNull);
        expect(model.createdAt, isNull);
      });
    });

    group('fromJson', () {
      test('should create PercaTransactionsModel from valid JSON', () {
        final model = PercaTransactionsModel.fromJson(testJson);

        expect(model.id, 'trans-001');
        expect(model.idStockPerca, testIdStockPerca);
        expect(model.idTailors, testIdTailors);
        expect(model.percasType, testPercasType);
        expect(model.weight, testWeight);
        expect(model.staffId, testStaffId);
      });

      test('should handle missing fields with defaults', () {
        final model = PercaTransactionsModel.fromJson({});

        expect(model.id, isNull);
        expect(model.idStockPerca, '');
        expect(model.idTailors, '');
        expect(model.percasType, '');
        expect(model.weight, 0.0);
        expect(model.staffId, isNull);
        expect(model.createdAt, isNull);
      });

      test('should handle null dateEntry with fallback to now', () {
        final model = PercaTransactionsModel.fromJson({
          'id_stock_perca': testIdStockPerca,
          'id_tailors': testIdTailors,
          'date_entry': null,
          'percas_type': testPercasType,
          'weight': testWeight,
        });

        expect(model.dateEntry, isNotNull);
        expect(model.dateEntry.year, DateTime.now().year);
      });

      test('should parse string weight as double', () {
        final model = PercaTransactionsModel.fromJson({
          'id_stock_perca': testIdStockPerca,
          'id_tailors': testIdTailors,
          'date_entry': '2024-07-01',
          'percas_type': testPercasType,
          'weight': '75.5',
        });

        expect(model.weight, 75.5);
      });

      test('should handle invalid weight with default 0.0', () {
        final model = PercaTransactionsModel.fromJson({
          'id_stock_perca': testIdStockPerca,
          'id_tailors': testIdTailors,
          'date_entry': '2024-07-01',
          'percas_type': testPercasType,
          'weight': 'invalid',
        });

        expect(model.weight, 0.0);
      });

      test('should parse date strings correctly', () {
        final model = PercaTransactionsModel.fromJson({
          'id_stock_perca': testIdStockPerca,
          'id_tailors': testIdTailors,
          'date_entry': '2024-07-15',
          'percas_type': testPercasType,
          'weight': testWeight,
          'created_at': '2024-07-15T14:30:00',
        });

        expect(model.dateEntry.day, 15);
        expect(model.createdAt?.day, 15);
      });
    });

    group('toJson', () {
      test('should convert PercaTransactionsModel to JSON', () {
        final json = testModel.toJson();

        expect(json['id_stock_perca'], testIdStockPerca);
        expect(json['id_tailors'], testIdTailors);
        expect(json['percas_type'], testPercasType);
        expect(json['weight'], testWeight);
        expect(json['staff_id'], testStaffId);
      });

      test('should include id in JSON if present', () {
        final json = testModel.toJson();
        expect(json['id'], 'trans-001');
      });

      test('should not include id in JSON if null', () {
        final model = PercaTransactionsModel(
          idStockPerca: testIdStockPerca,
          idTailors: testIdTailors,
          dateEntry: testDateEntry,
          percasType: testPercasType,
          weight: testWeight,
        );

        final json = model.toJson();
        expect(json.containsKey('id'), isFalse);
      });

      test('should include staff_id only if present', () {
        final modelWithStaffId = PercaTransactionsModel(
          idStockPerca: testIdStockPerca,
          idTailors: testIdTailors,
          dateEntry: testDateEntry,
          percasType: testPercasType,
          weight: testWeight,
          staffId: testStaffId,
        );

        final jsonWithStaff = modelWithStaffId.toJson();
        expect(jsonWithStaff['staff_id'], testStaffId);

        final modelWithoutStaffId = PercaTransactionsModel(
          idStockPerca: testIdStockPerca,
          idTailors: testIdTailors,
          dateEntry: testDateEntry,
          percasType: testPercasType,
          weight: testWeight,
        );

        final jsonWithoutStaff = modelWithoutStaffId.toJson();
        expect(jsonWithoutStaff.containsKey('staff_id'), isFalse);
      });

      test('should format date as date only (no time)', () {
        final json = testModel.toJson();
        expect(json['date_entry'], '2024-07-01');
        expect(json['date_entry'], isNot(contains('T')));
      });
    });

    group('copyWith', () {
      test('should copy with new weight', () {
        final updated = testModel.copyWith(weight: 100.0);

        expect(updated.weight, 100.0);
        expect(updated.id, testModel.id);
        expect(updated.idTailors, testModel.idTailors);
      });

      test('should copy with new percas type', () {
        final updated = testModel.copyWith(percasType: 'kain');

        expect(updated.percasType, 'kain');
        expect(updated.id, testModel.id);
        expect(updated.weight, testModel.weight);
      });

      test('should copy with new tailor ID', () {
        final updated = testModel.copyWith(idTailors: 'tailor-002');

        expect(updated.idTailors, 'tailor-002');
        expect(updated.id, testModel.id);
      });

      test('should copy with multiple changes', () {
        final updated = testModel.copyWith(
          weight: 75.0,
          percasType: 'kain',
          idTailors: 'tailor-003',
        );

        expect(updated.weight, 75.0);
        expect(updated.percasType, 'kain');
        expect(updated.idTailors, 'tailor-003');
        expect(updated.id, testModel.id);
      });

      test('should return identical copy when no changes', () {
        final copy = testModel.copyWith();

        expect(copy.id, testModel.id);
        expect(copy.weight, testModel.weight);
        expect(copy.percasType, testModel.percasType);
      });

      test('should not modify original when using copyWith', () {
        final original = PercaTransactionsModel(
          id: 'trans-001',
          idStockPerca: 'stock-001',
          idTailors: 'tailor-001',
          dateEntry: DateTime(2024, 7, 1),
          percasType: 'kaos',
          weight: 50.0,
        );

        final modified = original.copyWith(weight: 100.0);

        expect(original.weight, 50.0);
        expect(modified.weight, 100.0);
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final str = testModel.toString();

        expect(str, contains('PercaTransactionsModel'));
        expect(str, contains('trans-001'));
        expect(str, contains('tailor-001'));
        expect(str, contains('kaos'));
        expect(str, contains('50'));
      });
    });

    group('Equality', () {
      test('should be equal when ids are the same', () {
        final a = PercaTransactionsModel(
          id: 'trans-001',
          idStockPerca: 'stock-a',
          idTailors: 'tailor-a',
          dateEntry: DateTime(2024, 7, 1),
          percasType: 'kaos',
          weight: 50.0,
        );

        final b = PercaTransactionsModel(
          id: 'trans-001',
          idStockPerca: 'stock-b',
          idTailors: 'tailor-b',
          dateEntry: DateTime(2024, 7, 2),
          percasType: 'kain',
          weight: 75.0,
        );

        expect(a == b, isTrue);
      });

      test('should not be equal when ids differ', () {
        final a = testModel;
        final b = testModel.copyWith(id: 'trans-002');

        expect(a == b, isFalse);
      });

      test('should be equal when fields match and id is null', () {
        final a = PercaTransactionsModel(
          idStockPerca: testIdStockPerca,
          idTailors: testIdTailors,
          dateEntry: testDateEntry,
          percasType: testPercasType,
          weight: testWeight,
        );

        final b = PercaTransactionsModel(
          idStockPerca: testIdStockPerca,
          idTailors: testIdTailors,
          dateEntry: testDateEntry,
          percasType: testPercasType,
          weight: testWeight,
        );

        expect(a == b, isTrue);
      });

      test('should have same hashCode when ids are equal', () {
        final a = PercaTransactionsModel(
          id: 'trans-001',
          idStockPerca: 'stock-a',
          idTailors: 'tailor-a',
          dateEntry: DateTime(2024, 7, 1),
          percasType: 'kaos',
          weight: 50.0,
        );

        final b = PercaTransactionsModel(
          id: 'trans-001',
          idStockPerca: 'stock-b',
          idTailors: 'tailor-b',
          dateEntry: DateTime(2024, 7, 2),
          percasType: 'kain',
          weight: 75.0,
        );

        expect(a.hashCode, b.hashCode);
      });

      test('should compute hashCode from fields when id is null', () {
        final model1 = PercaTransactionsModel(
          idStockPerca: 'stock-001',
          idTailors: 'tailor-001',
          dateEntry: DateTime(2024, 7, 1),
          percasType: 'kaos',
          weight: 50.0,
        );

        final model2 = PercaTransactionsModel(
          idStockPerca: 'stock-001',
          idTailors: 'tailor-001',
          dateEntry: DateTime(2024, 7, 1),
          percasType: 'kaos',
          weight: 50.0,
        );

        expect(model1.hashCode, model2.hashCode);
      });
    });

    group('JSON round-trip', () {
      test('should maintain data through fromJson -> toJson -> fromJson', () {
        final original = testModel;
        final json = original.toJson();
        final restored = PercaTransactionsModel.fromJson(json);

        expect(restored.idStockPerca, original.idStockPerca);
        expect(restored.idTailors, original.idTailors);
        expect(restored.percasType, original.percasType);
        expect(restored.weight, original.weight);
      });
    });

    group('Edge cases', () {
      test('should handle zero weight', () {
        final model = PercaTransactionsModel(
          idStockPerca: testIdStockPerca,
          idTailors: testIdTailors,
          dateEntry: testDateEntry,
          percasType: testPercasType,
          weight: 0.0,
        );

        expect(model.weight, 0.0);
        final json = model.toJson();
        expect(json['weight'], 0.0);
      });

      test('should handle very large weights', () {
        const largeWeight = 999999.99;
        final model = PercaTransactionsModel(
          idStockPerca: testIdStockPerca,
          idTailors: testIdTailors,
          dateEntry: testDateEntry,
          percasType: testPercasType,
          weight: largeWeight,
        );

        expect(model.weight, largeWeight);
      });

      test('should handle special characters in ids', () {
        final model = PercaTransactionsModel(
          id: 'trans-!@#$%',
          idStockPerca: 'stock-!@#$%',
          idTailors: 'tailor-!@#$%',
          dateEntry: testDateEntry,
          percasType: testPercasType,
          weight: testWeight,
        );

        expect(model.id, contains('!@#$%'));
        expect(model.idStockPerca, contains('!@#$%'));
      });
    });
  });
}
