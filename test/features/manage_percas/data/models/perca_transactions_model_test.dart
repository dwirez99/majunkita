import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_percas/data/models/perca_transactions_model.dart';

void main() {
  group('PercaTransactionsModel', () {
    final testDate = DateTime(2024, 6, 20);
    const testId = 'perca-txn-001';
    const testStockId = 'stock-perca-001';
    const testTailorId = 'tailor-uuid-001';

    final validJson = {
      'id': testId,
      'id_stock_perca': testStockId,
      'id_tailors': testTailorId,
      'date_entry': '2024-06-20',
      'percas_type': 'kaos',
      'weight': '30.5',
      'staff_id': 'staff-001',
      'created_at': '2024-06-20T08:00:00.000Z',
    };

    late PercaTransactionsModel testModel;

    setUp(() {
      testModel = PercaTransactionsModel(
        id: testId,
        idStockPerca: testStockId,
        idTailors: testTailorId,
        dateEntry: testDate,
        percasType: 'kaos',
        weight: 30.5,
        staffId: 'staff-001',
      );
    });

    group('Constructor', () {
      test('should create model with all fields', () {
        expect(testModel.id, testId);
        expect(testModel.idStockPerca, testStockId);
        expect(testModel.idTailors, testTailorId);
        expect(testModel.percasType, 'kaos');
        expect(testModel.weight, 30.5);
        expect(testModel.staffId, 'staff-001');
      });

      test('should allow null id and staffId', () {
        final model = PercaTransactionsModel(
          idStockPerca: testStockId,
          idTailors: testTailorId,
          dateEntry: testDate,
          percasType: 'kain',
          weight: 20.0,
        );
        expect(model.id, isNull);
        expect(model.staffId, isNull);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final model = PercaTransactionsModel.fromJson(validJson);

        expect(model.id, testId);
        expect(model.idStockPerca, testStockId);
        expect(model.idTailors, testTailorId);
        expect(model.percasType, 'kaos');
        expect(model.weight, 30.5);
        expect(model.staffId, 'staff-001');
      });

      test('should handle null values gracefully', () {
        final model = PercaTransactionsModel.fromJson({});

        expect(model.id, isNull);
        expect(model.idStockPerca, '');
        expect(model.idTailors, '');
        expect(model.percasType, '');
        expect(model.weight, 0.0);
        expect(model.staffId, isNull);
      });

      test('should parse weight as double from string', () {
        final json = Map<String, dynamic>.from(validJson)
          ..['weight'] = '15.75';
        final model = PercaTransactionsModel.fromJson(json);
        expect(model.weight, 15.75);
      });

      test('should default weight to 0 for invalid string', () {
        final json = Map<String, dynamic>.from(validJson)
          ..['weight'] = 'not-a-number';
        final model = PercaTransactionsModel.fromJson(json);
        expect(model.weight, 0.0);
      });

      test('should parse date_entry correctly', () {
        final model = PercaTransactionsModel.fromJson(validJson);
        expect(model.dateEntry.year, 2024);
        expect(model.dateEntry.month, 6);
        expect(model.dateEntry.day, 20);
      });
    });

    group('toJson', () {
      test('should produce correct JSON for insert', () {
        final json = testModel.toJson();

        expect(json['id_stock_perca'], testStockId);
        expect(json['id_tailors'], testTailorId);
        expect(json['percas_type'], 'kaos');
        expect(json['weight'], 30.5);
        expect(json['id'], testId);
        expect(json['staff_id'], 'staff-001');
      });

      test('should not include id when null', () {
        final model = PercaTransactionsModel(
          idStockPerca: testStockId,
          idTailors: testTailorId,
          dateEntry: testDate,
          percasType: 'kaos',
          weight: 10.0,
        );
        final json = model.toJson();
        expect(json.containsKey('id'), isFalse);
      });

      test('should not include staff_id when null', () {
        final model = PercaTransactionsModel(
          idStockPerca: testStockId,
          idTailors: testTailorId,
          dateEntry: testDate,
          percasType: 'kaos',
          weight: 10.0,
        );
        final json = model.toJson();
        expect(json.containsKey('staff_id'), isFalse);
      });

      test('date_entry in JSON should be formatted as yyyy-MM-dd', () {
        final json = testModel.toJson();
        expect(json['date_entry'], '2024-06-20');
      });
    });

    group('copyWith', () {
      test('should return copy with updated weight', () {
        final updated = testModel.copyWith(weight: 99.9);
        expect(updated.weight, 99.9);
        expect(updated.id, testModel.id);
        expect(updated.percasType, testModel.percasType);
      });

      test('should return identical copy when no changes', () {
        final copy = testModel.copyWith();
        expect(copy.id, testModel.id);
        expect(copy.weight, testModel.weight);
        expect(copy.percasType, testModel.percasType);
      });
    });

    group('toString', () {
      test('should contain class name and key fields', () {
        final str = testModel.toString();
        expect(str, contains('PercaTransactionsModel'));
        expect(str, contains(testTailorId));
        expect(str, contains('kaos'));
      });
    });

    group('Equality', () {
      test('two models with same id should be equal', () {
        final a = PercaTransactionsModel(
          id: testId,
          idStockPerca: testStockId,
          idTailors: testTailorId,
          dateEntry: testDate,
          percasType: 'kaos',
          weight: 30.5,
        );
        final b = PercaTransactionsModel(
          id: testId,
          idStockPerca: 'different',
          idTailors: 'different',
          dateEntry: DateTime(2000),
          percasType: 'kain',
          weight: 99.0,
        );
        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('two models with different id should not be equal', () {
        final a = PercaTransactionsModel(
          id: testId,
          idStockPerca: testStockId,
          idTailors: testTailorId,
          dateEntry: testDate,
          percasType: 'kaos',
          weight: 30.5,
        );
        final b = PercaTransactionsModel(
          id: 'other-id',
          idStockPerca: testStockId,
          idTailors: testTailorId,
          dateEntry: testDate,
          percasType: 'kaos',
          weight: 30.5,
        );
        expect(a == b, isFalse);
      });
    });
  });
}
