import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_majun/data/model/majun_transactions_model.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // MajunTransactionsModel
  // ────────────────────────────────────────────────────────────────────────────
  group('MajunTransactionsModel', () {
    final testDate = DateTime(2024, 6, 15);
    const testTailorId = 'tailor-uuid-001';
    const testId = 'txn-uuid-001';

    final validJson = {
      'id': testId,
      'id_tailor': testTailorId,
      'date_entry': '2024-06-15',
      'weight_majun': '25.5',
      'earned_wage': '127500.0',
      'staff_id': 'staff-uuid-001',
      'delivery_proof': 'https://example.com/proof.jpg',
      'created_at': '2024-06-15T10:00:00.000Z',
      'tailor_name': 'Ibu Siti',
    };

    group('Constructor', () {
      test('should create model with all fields', () {
        final model = MajunTransactionsModel(
          id: testId,
          idTailor: testTailorId,
          dateEntry: testDate,
          weightMajun: 25.5,
          earnedWage: 127500.0,
          staffId: 'staff-uuid-001',
          deliveryProof: 'https://example.com/proof.jpg',
          tailorName: 'Ibu Siti',
        );

        expect(model.id, testId);
        expect(model.idTailor, testTailorId);
        expect(model.weightMajun, 25.5);
        expect(model.earnedWage, 127500.0);
      });

      test('should use default earnedWage of 0 when not provided', () {
        final model = MajunTransactionsModel(
          idTailor: testTailorId,
          dateEntry: testDate,
          weightMajun: 10.0,
        );
        expect(model.earnedWage, 0.0);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final model = MajunTransactionsModel.fromJson(validJson);

        expect(model.id, testId);
        expect(model.idTailor, testTailorId);
        expect(model.weightMajun, 25.5);
        expect(model.earnedWage, 127500.0);
        expect(model.staffId, 'staff-uuid-001');
        expect(model.deliveryProof, 'https://example.com/proof.jpg');
        expect(model.tailorName, 'Ibu Siti');
      });

      test('should handle null id in JSON', () {
        final json = Map<String, dynamic>.from(validJson)..['id'] = null;
        final model = MajunTransactionsModel.fromJson(json);
        expect(model.id, isNull);
      });

      test('should default to empty string for missing id_tailor', () {
        final json = <String, dynamic>{
          'date_entry': '2024-06-15',
          'weight_majun': '10.0',
        };
        final model = MajunTransactionsModel.fromJson(json);
        expect(model.idTailor, '');
        expect(model.weightMajun, 10.0);
      });

      test('should use DateTime.now() when date_entry is null', () {
        final before = DateTime.now();
        final json = <String, dynamic>{
          'id_tailor': testTailorId,
          'weight_majun': '5.0',
        };
        final model = MajunTransactionsModel.fromJson(json);
        final after = DateTime.now();

        expect(
          model.dateEntry.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          model.dateEntry.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('should handle invalid weight_majun gracefully', () {
        final json = Map<String, dynamic>.from(validJson)
          ..['weight_majun'] = 'invalid';
        final model = MajunTransactionsModel.fromJson(json);
        expect(model.weightMajun, 0.0);
      });
    });

    group('toInsertJson', () {
      test('should produce correct insert JSON', () {
        final model = MajunTransactionsModel(
          idTailor: testTailorId,
          dateEntry: testDate,
          weightMajun: 25.5,
          staffId: 'staff-uuid-001',
          deliveryProof: 'https://example.com/proof.jpg',
        );

        final json = model.toInsertJson();

        expect(json['id_tailor'], testTailorId);
        expect(json['date_entry'], '2024-06-15');
        expect(json['weight_majun'], 25.5);
        expect(json['staff_id'], 'staff-uuid-001');
        expect(json['delivery_proof'], 'https://example.com/proof.jpg');
        // id, earned_wage, created_at should NOT be in insert JSON
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('earned_wage'), isFalse);
      });

      test('should not include null staff_id in insert JSON', () {
        final model = MajunTransactionsModel(
          idTailor: testTailorId,
          dateEntry: testDate,
          weightMajun: 10.0,
        );

        final json = model.toInsertJson();

        expect(json.containsKey('staff_id'), isFalse);
        expect(json.containsKey('delivery_proof'), isFalse);
      });
    });

    group('toString', () {
      test('should return readable string', () {
        final model = MajunTransactionsModel(
          id: testId,
          idTailor: testTailorId,
          dateEntry: testDate,
          weightMajun: 25.5,
          earnedWage: 127500.0,
        );
        final str = model.toString();
        expect(str, contains('MajunTransactionsModel'));
        expect(str, contains(testId));
        expect(str, contains('25.5'));
      });
    });

    group('Equality', () {
      test('should be equal when both have same id', () {
        final a = MajunTransactionsModel(
          id: testId,
          idTailor: testTailorId,
          dateEntry: testDate,
          weightMajun: 25.5,
        );
        final b = MajunTransactionsModel(
          id: testId,
          idTailor: 'different-tailor',
          dateEntry: DateTime(2000),
          weightMajun: 99.9,
        );
        expect(a == b, isTrue);
        expect(a.hashCode == b.hashCode, isTrue);
      });

      test('should not be equal when ids differ', () {
        final a = MajunTransactionsModel(
          id: testId,
          idTailor: testTailorId,
          dateEntry: testDate,
          weightMajun: 25.5,
        );
        final b = MajunTransactionsModel(
          id: 'different-id',
          idTailor: testTailorId,
          dateEntry: testDate,
          weightMajun: 25.5,
        );
        expect(a == b, isFalse);
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // LimbahTransactionsModel
  // ────────────────────────────────────────────────────────────────────────────
  group('LimbahTransactionsModel', () {
    final testDate = DateTime(2024, 6, 15);
    const testTailorId = 'tailor-uuid-001';

    final validJson = {
      'id': 'limbah-txn-001',
      'id_tailor': testTailorId,
      'date_entry': '2024-06-15',
      'weight_limbah': '5.0',
      'staff_id': 'staff-uuid-001',
      'delivery_proof': 'https://example.com/proof2.jpg',
      'created_at': '2024-06-15T10:00:00.000Z',
      'tailor_name': 'Ibu Siti',
    };

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final model = LimbahTransactionsModel.fromJson(validJson);

        expect(model.id, 'limbah-txn-001');
        expect(model.idTailor, testTailorId);
        expect(model.weightLimbah, 5.0);
        expect(model.staffId, 'staff-uuid-001');
        expect(model.tailorName, 'Ibu Siti');
      });

      test('should handle missing keys gracefully', () {
        final model = LimbahTransactionsModel.fromJson({});

        expect(model.idTailor, '');
        expect(model.weightLimbah, 0.0);
      });
    });

    group('toInsertJson', () {
      test('should produce correct insert JSON', () {
        final model = LimbahTransactionsModel(
          idTailor: testTailorId,
          dateEntry: testDate,
          weightLimbah: 5.0,
          staffId: 'staff-uuid-001',
        );

        final json = model.toInsertJson();

        expect(json['id_tailor'], testTailorId);
        expect(json['date_entry'], '2024-06-15');
        expect(json['weight_limbah'], 5.0);
        expect(json['staff_id'], 'staff-uuid-001');
      });

      test('should omit staff_id when null', () {
        final model = LimbahTransactionsModel(
          idTailor: testTailorId,
          dateEntry: testDate,
          weightLimbah: 5.0,
        );
        final json = model.toInsertJson();
        expect(json.containsKey('staff_id'), isFalse);
      });
    });

    group('toString', () {
      test('should contain class name and key values', () {
        final model = LimbahTransactionsModel(
          idTailor: testTailorId,
          dateEntry: testDate,
          weightLimbah: 5.0,
        );
        final str = model.toString();
        expect(str, contains('LimbahTransactionsModel'));
        expect(str, contains(testTailorId));
        expect(str, contains('5.0'));
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // SetorMajunResult
  // ────────────────────────────────────────────────────────────────────────────
  group('SetorMajunResult', () {
    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final json = {
          'id': 'result-uuid-001',
          'weight_majun': '30.0',
          'earned_wage': '150000.0',
        };
        final result = SetorMajunResult.fromJson(json);

        expect(result.transactionId, 'result-uuid-001');
        expect(result.weightMajun, 30.0);
        expect(result.earnedWage, 150000.0);
      });

      test('should use empty string for missing id', () {
        final result = SetorMajunResult.fromJson({});

        expect(result.transactionId, '');
        expect(result.weightMajun, 0.0);
        expect(result.earnedWage, 0.0);
      });

      test('should handle numeric values (int) in JSON', () {
        final json = {
          'id': 'result-uuid-002',
          'weight_majun': 20,
          'earned_wage': 100000,
        };
        final result = SetorMajunResult.fromJson(json);
        expect(result.weightMajun, 20.0);
        expect(result.earnedWage, 100000.0);
      });
    });
  });
}
