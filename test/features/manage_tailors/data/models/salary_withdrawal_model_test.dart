import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_tailors/data/models/salary_withdrawal_model.dart';

void main() {
  group('SalaryWithdrawalModel', () {
    final testCreatedAt = DateTime(2024, 8, 1, 10, 30);
    final testDateEntry = DateTime(2024, 8, 1);
    const testId = 42;
    const testTailorId = 'tailor-uuid-001';
    const testAmount = 250000.0;

    final validJson = {
      'id': testId,
      'created_at': '2024-08-01T10:30:00.000Z',
      'id_tailor': testTailorId,
      'amount': '250000.0',
      'date_entry': '2024-08-01',
    };

    late SalaryWithdrawalModel testModel;

    setUp(() {
      testModel = SalaryWithdrawalModel(
        id: testId,
        createdAt: testCreatedAt,
        idTailor: testTailorId,
        amount: testAmount,
        dateEntry: testDateEntry,
      );
    });

    group('Constructor', () {
      test('should create model with all required fields', () {
        expect(testModel.id, testId);
        expect(testModel.idTailor, testTailorId);
        expect(testModel.amount, testAmount);
        expect(testModel.createdAt, testCreatedAt);
        expect(testModel.dateEntry, testDateEntry);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final model = SalaryWithdrawalModel.fromJson(validJson);

        expect(model.id, testId);
        expect(model.idTailor, testTailorId);
        expect(model.amount, 250000.0);
      });

      test('should default id to 0 when null', () {
        final json = Map<String, dynamic>.from(validJson)..['id'] = null;
        final model = SalaryWithdrawalModel.fromJson(json);
        expect(model.id, 0);
      });

      test('should default idTailor to empty string when missing', () {
        final model = SalaryWithdrawalModel.fromJson({
          'id': 1,
          'amount': '50000',
          'date_entry': '2024-01-01',
        });
        expect(model.idTailor, '');
      });

      test('should default amount to 0 for invalid amount string', () {
        final json = Map<String, dynamic>.from(validJson)
          ..['amount'] = 'invalid';
        final model = SalaryWithdrawalModel.fromJson(json);
        expect(model.amount, 0.0);
      });

      test('should use DateTime.now() when created_at is null', () {
        final before = DateTime.now();
        final json = Map<String, dynamic>.from(validJson)
          ..['created_at'] = null;
        final model = SalaryWithdrawalModel.fromJson(json);
        final after = DateTime.now();

        expect(
          model.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          model.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('should parse numeric amount correctly', () {
        final json = Map<String, dynamic>.from(validJson)..['amount'] = 75000;
        final model = SalaryWithdrawalModel.fromJson(json);
        expect(model.amount, 75000.0);
      });
    });

    group('toJson', () {
      test('should produce correct JSON for insert', () {
        final json = testModel.toJson();

        expect(json['id_tailor'], testTailorId);
        expect(json['amount'], testAmount);
        expect(json['date_entry'], '2024-08-01');
        // id and created_at are managed by DB, should not be in insert payload
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
      });

      test('date_entry should be formatted as yyyy-MM-dd', () {
        final json = testModel.toJson();
        expect(json['date_entry'], '2024-08-01');
      });
    });

    group('copyWith', () {
      test('should copy with new amount', () {
        final updated = testModel.copyWith(amount: 500000.0);
        expect(updated.amount, 500000.0);
        expect(updated.id, testModel.id);
        expect(updated.idTailor, testModel.idTailor);
      });

      test('should copy with new dateEntry', () {
        final newDate = DateTime(2024, 9, 15);
        final updated = testModel.copyWith(dateEntry: newDate);
        expect(updated.dateEntry, newDate);
        expect(updated.amount, testModel.amount);
      });

      test('should return identical copy when no changes provided', () {
        final copy = testModel.copyWith();
        expect(copy.id, testModel.id);
        expect(copy.idTailor, testModel.idTailor);
        expect(copy.amount, testModel.amount);
      });
    });

    group('toString', () {
      test('should contain class name and key fields', () {
        final str = testModel.toString();
        expect(str, contains('SalaryWithdrawalModel'));
        expect(str, contains(testTailorId));
        expect(str, contains('$testAmount'));
      });
    });

    group('Equality', () {
      test('should be equal when ids are the same', () {
        final a = SalaryWithdrawalModel(
          id: testId,
          createdAt: testCreatedAt,
          idTailor: testTailorId,
          amount: testAmount,
          dateEntry: testDateEntry,
        );
        final b = SalaryWithdrawalModel(
          id: testId,
          createdAt: DateTime(2000),
          idTailor: 'different',
          amount: 999.0,
          dateEntry: DateTime(2000),
        );
        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('should not be equal when ids differ', () {
        final a = testModel;
        final b = testModel.copyWith(id: 99);
        expect(a == b, isFalse);
      });
    });
  });
}
