import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_majun/data/model/majun_transactions_model.dart';

void main() {
  group('LimbahTransactionsModel', () {
    const testIdTailor = 'tailor-001';
    final testDateEntry = DateTime(2024, 7, 1);
    const testWeightLimbah = 50.0;
    const testStaffId = 'staff-001';
    const testDeliveryProof = 'https://example.com/limbah_proof.jpg';
    const testTailorName = 'John Doe';
    final testCreatedAt = DateTime(2024, 7, 1, 10, 30, 0);

    final testJson = {
      'id': 'limbah-001',
      'id_tailor': testIdTailor,
      'date_entry': '2024-07-01',
      'weight_limbah': testWeightLimbah,
      'staff_id': testStaffId,
      'delivery_proof': testDeliveryProof,
      'tailor_name': testTailorName,
      'created_at': '2024-07-01T10:30:00',
    };

    late LimbahTransactionsModel testModel;

    setUp(() {
      testModel = LimbahTransactionsModel(
        id: 'limbah-001',
        idTailor: testIdTailor,
        dateEntry: testDateEntry,
        weightLimbah: testWeightLimbah,
        staffId: testStaffId,
        deliveryProof: testDeliveryProof,
        createdAt: testCreatedAt,
        tailorName: testTailorName,
      );
    });

    group('Constructor', () {
      test('should create LimbahTransactionsModel with all fields', () {
        expect(testModel.id, 'limbah-001');
        expect(testModel.idTailor, testIdTailor);
        expect(testModel.dateEntry, testDateEntry);
        expect(testModel.weightLimbah, testWeightLimbah);
        expect(testModel.staffId, testStaffId);
        expect(testModel.deliveryProof, testDeliveryProof);
        expect(testModel.createdAt, testCreatedAt);
        expect(testModel.tailorName, testTailorName);
      });

      test('should create with nullable fields', () {
        final model = LimbahTransactionsModel(
          idTailor: testIdTailor,
          dateEntry: testDateEntry,
          weightLimbah: testWeightLimbah,
        );

        expect(model.id, isNull);
        expect(model.staffId, isNull);
        expect(model.deliveryProof, isNull);
        expect(model.createdAt, isNull);
        expect(model.tailorName, isNull);
      });
    });

    group('fromJson', () {
      test('should create from valid JSON', () {
        final model = LimbahTransactionsModel.fromJson(testJson);

        expect(model.id, 'limbah-001');
        expect(model.idTailor, testIdTailor);
        expect(model.weightLimbah, testWeightLimbah);
        expect(model.staffId, testStaffId);
        expect(model.deliveryProof, testDeliveryProof);
        expect(model.tailorName, testTailorName);
      });

      test('should handle missing fields', () {
        final model = LimbahTransactionsModel.fromJson({});

        expect(model.id, isNull);
        expect(model.idTailor, '');
        expect(model.weightLimbah, 0.0);
        expect(model.staffId, isNull);
      });

      test('should handle null dateEntry with fallback', () {
        final model = LimbahTransactionsModel.fromJson({
          'id_tailor': testIdTailor,
          'date_entry': null,
          'weight_limbah': testWeightLimbah,
        });

        expect(model.dateEntry, isNotNull);
      });

      test('should parse string weight as double', () {
        final model = LimbahTransactionsModel.fromJson({
          'id_tailor': testIdTailor,
          'date_entry': '2024-07-01',
          'weight_limbah': '75.5',
        });

        expect(model.weightLimbah, 75.5);
      });

      test('should convert id to string if not already', () {
        final model = LimbahTransactionsModel.fromJson({
          'id': 12345,
          'id_tailor': testIdTailor,
          'date_entry': '2024-07-01',
          'weight_limbah': testWeightLimbah,
        });

        expect(model.id, '12345');
      });
    });

    group('toInsertJson', () {
      test('should convert to insert JSON correctly', () {
        final json = testModel.toInsertJson();

        expect(json['id_tailor'], testIdTailor);
        expect(json['weight_limbah'], testWeightLimbah);
        expect(json.containsKey('date_entry'), true);
      });

      test('should include optional fields when present', () {
        final json = testModel.toInsertJson();

        expect(json['staff_id'], testStaffId);
        expect(json['delivery_proof'], testDeliveryProof);
      });

      test('should not include optional fields when null', () {
        final model = LimbahTransactionsModel(
          idTailor: testIdTailor,
          dateEntry: testDateEntry,
          weightLimbah: testWeightLimbah,
        );

        final json = model.toInsertJson();

        expect(json.containsKey('staff_id'), isFalse);
        expect(json.containsKey('delivery_proof'), isFalse);
      });

      test('should format date as date only', () {
        final json = testModel.toInsertJson();

        expect(json['date_entry'], '2024-07-01');
        expect(json['date_entry'], isNot(contains('T')));
      });
    });

    group('toString', () {
      test('should contain class name and key fields', () {
        final str = testModel.toString();

        expect(str, contains('LimbahTransactionsModel'));
        expect(str, contains('limbah-001'));
        expect(str, contains(testIdTailor));
        expect(str, contains('50'));
      });
    });

    group('Edge cases', () {
      test('should handle zero weight', () {
        final model = LimbahTransactionsModel(
          idTailor: testIdTailor,
          dateEntry: testDateEntry,
          weightLimbah: 0.0,
        );

        expect(model.weightLimbah, 0.0);
      });

      test('should handle very large weights', () {
        const largeWeight = 999999.99;
        final model = LimbahTransactionsModel(
          idTailor: testIdTailor,
          dateEntry: testDateEntry,
          weightLimbah: largeWeight,
        );

        expect(model.weightLimbah, largeWeight);
      });
    });
  });

  group('SetorMajunResult', () {
    const testTransactionId = 'trans-001';
    const testWeightMajun = 50.0;
    const testEarnedWage = 250000.0;

    final testJson = {
      'id': testTransactionId,
      'weight_majun': testWeightMajun,
      'earned_wage': testEarnedWage,
    };

    late SetorMajunResult testResult;

    setUp(() {
      testResult = SetorMajunResult(
        transactionId: testTransactionId,
        weightMajun: testWeightMajun,
        earnedWage: testEarnedWage,
      );
    });

    group('Constructor', () {
      test('should create SetorMajunResult with all fields', () {
        expect(testResult.transactionId, testTransactionId);
        expect(testResult.weightMajun, testWeightMajun);
        expect(testResult.earnedWage, testEarnedWage);
      });
    });

    group('fromJson', () {
      test('should create from valid JSON', () {
        final result = SetorMajunResult.fromJson(testJson);

        expect(result.transactionId, testTransactionId);
        expect(result.weightMajun, testWeightMajun);
        expect(result.earnedWage, testEarnedWage);
      });

      test('should handle missing fields with defaults', () {
        final result = SetorMajunResult.fromJson({});

        expect(result.transactionId, '');
        expect(result.weightMajun, 0.0);
        expect(result.earnedWage, 0.0);
      });

      test('should handle null values', () {
        final result = SetorMajunResult.fromJson({
          'id': null,
          'weight_majun': null,
          'earned_wage': null,
        });

        expect(result.transactionId, '');
        expect(result.weightMajun, 0.0);
        expect(result.earnedWage, 0.0);
      });

      test('should parse numeric values as doubles', () {
        final result = SetorMajunResult.fromJson({
          'id': 'trans-001',
          'weight_majun': 100,
          'earned_wage': 500000,
        });

        expect(result.weightMajun, 100.0);
        expect(result.earnedWage, 500000.0);
      });

      test('should parse string numeric values', () {
        final result = SetorMajunResult.fromJson({
          'id': 'trans-001',
          'weight_majun': '50.5',
          'earned_wage': '252500.75',
        });

        expect(result.weightMajun, 50.5);
        expect(result.earnedWage, 252500.75);
      });

      test('should convert id to string', () {
        final result = SetorMajunResult.fromJson({
          'id': 12345,
          'weight_majun': testWeightMajun,
          'earned_wage': testEarnedWage,
        });

        expect(result.transactionId, '12345');
      });

      test('should handle invalid numeric values', () {
        final result = SetorMajunResult.fromJson({
          'id': 'trans-001',
          'weight_majun': 'invalid',
          'earned_wage': 'not_a_number',
        });

        expect(result.weightMajun, 0.0);
        expect(result.earnedWage, 0.0);
      });
    });

    group('Properties', () {
      test('should have all required properties', () {
        expect(testResult.transactionId, isNotNull);
        expect(testResult.weightMajun, isNotNull);
        expect(testResult.earnedWage, isNotNull);
      });

      test('should store values correctly', () {
        final result = SetorMajunResult(
          transactionId: 'trans-123',
          weightMajun: 75.5,
          earnedWage: 377500.0,
        );

        expect(result.transactionId, 'trans-123');
        expect(result.weightMajun, 75.5);
        expect(result.earnedWage, 377500.0);
      });
    });

    group('Edge cases', () {
      test('should handle zero values', () {
        final result = SetorMajunResult(
          transactionId: 'trans-001',
          weightMajun: 0.0,
          earnedWage: 0.0,
        );

        expect(result.weightMajun, 0.0);
        expect(result.earnedWage, 0.0);
      });

      test('should handle large values', () {
        const largeValue = 999999999.99;
        final result = SetorMajunResult(
          transactionId: 'trans-001',
          weightMajun: largeValue,
          earnedWage: largeValue,
        );

        expect(result.weightMajun, largeValue);
        expect(result.earnedWage, largeValue);
      });

      test('should handle special characters in transaction ID', () {
        final result = SetorMajunResult(
          transactionId: 'trans-!@#$%',
          weightMajun: testWeightMajun,
          earnedWage: testEarnedWage,
        );

        expect(result.transactionId, contains('!@#$%'));
      });

      test('should handle empty transaction ID', () {
        final result = SetorMajunResult(
          transactionId: '',
          weightMajun: testWeightMajun,
          earnedWage: testEarnedWage,
        );

        expect(result.transactionId, '');
      });
    });

    group('JSON round-trip', () {
      test('should maintain data through fromJson', () {
        final original = testResult;
        final json = {
          'id': original.transactionId,
          'weight_majun': original.weightMajun,
          'earned_wage': original.earnedWage,
        };

        final restored = SetorMajunResult.fromJson(json);

        expect(restored.transactionId, original.transactionId);
        expect(restored.weightMajun, original.weightMajun);
        expect(restored.earnedWage, original.earnedWage);
      });
    });

    group('Integration scenarios', () {
      test('should correctly calculate wage for sample transaction', () {
        final result = SetorMajunResult(
          transactionId: 'trans-001',
          weightMajun: 100.0,
          earnedWage: 500000.0, // 5000 per kg
        );

        expect(result.weightMajun, 100.0);
        expect(result.earnedWage, 500000.0);
      });

      test('should handle multiple transactions', () {
        final transactions = [
          SetorMajunResult(
            transactionId: 'trans-001',
            weightMajun: 50.0,
            earnedWage: 250000.0,
          ),
          SetorMajunResult(
            transactionId: 'trans-002',
            weightMajun: 75.0,
            earnedWage: 375000.0,
          ),
          SetorMajunResult(
            transactionId: 'trans-003',
            weightMajun: 100.0,
            earnedWage: 500000.0,
          ),
        ];

        expect(transactions.length, 3);
        final totalWeight = transactions.fold(0.0, (sum, t) => sum + t.weightMajun);
        final totalEarned = transactions.fold(0.0, (sum, t) => sum + t.earnedWage);

        expect(totalWeight, 225.0);
        expect(totalEarned, 1125000.0);
      });
    });
  });
}
