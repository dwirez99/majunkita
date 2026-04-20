import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_expeditions/data/models/expedition_model.dart';

void main() {
  group('ExpeditionModel', () {
    const testId = 'expedition-001';
    const testPartnerId = 'partner-001';
    const testDestination = 'Surabaya';

    final testDate = DateTime(2024, 7, 1);

    final validJson = {
      'id': testId,
      'id_partner': testPartnerId,
      'expedition_date': '2024-07-01',
      'destination': testDestination,
      'sack_number': 10,
      'total_weight': 500,
      'proof_of_delivery': 'https://example.com/delivery.jpg',
      'id_expedition_partner': 'exp-partner-001',
      'profiles': {'name': 'Pak Budi'},
      'expedition_partners': {'name': 'JNE Express'},
    };

    late ExpeditionModel testModel;

    setUp(() {
      testModel = ExpeditionModel(
        id: testId,
        idPartner: testPartnerId,
        expeditionDate: testDate,
        destination: testDestination,
        sackNumber: 10,
        totalWeight: 500,
        proofOfDelivery: 'https://example.com/delivery.jpg',
        idExpeditionPartner: 'exp-partner-001',
        partnerName: 'Pak Budi',
        expeditionPartnerName: 'JNE Express',
      );
    });

    group('Constructor', () {
      test('should create ExpeditionModel with all fields', () {
        expect(testModel.id, testId);
        expect(testModel.idPartner, testPartnerId);
        expect(testModel.destination, testDestination);
        expect(testModel.sackNumber, 10);
        expect(testModel.totalWeight, 500);
        expect(testModel.partnerName, 'Pak Budi');
        expect(testModel.expeditionPartnerName, 'JNE Express');
      });

      test('should allow null optional fields', () {
        final model = ExpeditionModel(
          id: testId,
          idPartner: testPartnerId,
          expeditionDate: testDate,
          destination: testDestination,
          sackNumber: 5,
          totalWeight: 200,
          proofOfDelivery: '',
        );
        expect(model.idExpeditionPartner, isNull);
        expect(model.partnerName, isNull);
        expect(model.expeditionPartnerName, isNull);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final model = ExpeditionModel.fromJson(validJson);

        expect(model.id, testId);
        expect(model.idPartner, testPartnerId);
        expect(model.destination, testDestination);
        expect(model.sackNumber, 10);
        expect(model.totalWeight, 500);
        expect(model.idExpeditionPartner, 'exp-partner-001');
        expect(model.partnerName, 'Pak Budi');
        expect(model.expeditionPartnerName, 'JNE Express');
      });

      test('should handle missing optional fields gracefully', () {
        final minimalJson = {
          'id': testId,
          'id_partner': testPartnerId,
          'expedition_date': '2024-07-01',
          'destination': testDestination,
          'sack_number': 3,
          'total_weight': 100,
          'proof_of_delivery': '',
        };
        final model = ExpeditionModel.fromJson(minimalJson);

        expect(model.idExpeditionPartner, isNull);
        expect(model.partnerName, isNull);
        expect(model.expeditionPartnerName, isNull);
      });

      test('should handle null values gracefully', () {
        final model = ExpeditionModel.fromJson({
          'expedition_date': null,
        });

        expect(model.id, '');
        expect(model.sackNumber, 0);
        expect(model.totalWeight, 0);
        expect(model.proofOfDelivery, '');
      });

      test('should parse expedition_date as DateTime', () {
        final model = ExpeditionModel.fromJson(validJson);
        expect(model.expeditionDate.year, 2024);
        expect(model.expeditionDate.month, 7);
        expect(model.expeditionDate.day, 1);
      });

      test('should handle sack_number as double type (num)', () {
        final json = Map<String, dynamic>.from(validJson)
          ..['sack_number'] = 7.0;
        final model = ExpeditionModel.fromJson(json);
        expect(model.sackNumber, 7);
      });
    });

    group('toJson', () {
      test('should produce correct JSON', () {
        final json = testModel.toJson();

        expect(json['id'], testId);
        expect(json['id_partner'], testPartnerId);
        expect(json['destination'], testDestination);
        expect(json['sack_number'], 10);
        expect(json['total_weight'], 500);
        expect(json['proof_of_delivery'], 'https://example.com/delivery.jpg');
        expect(json['id_expedition_partner'], 'exp-partner-001');
      });

      test('expedition_date should be formatted as yyyy-MM-dd', () {
        final json = testModel.toJson();
        expect(json['expedition_date'], '2024-07-01');
      });

      test('should not include id_expedition_partner when null', () {
        final model = ExpeditionModel(
          id: testId,
          idPartner: testPartnerId,
          expeditionDate: testDate,
          destination: testDestination,
          sackNumber: 1,
          totalWeight: 50,
          proofOfDelivery: '',
        );
        final json = model.toJson();
        expect(json.containsKey('id_expedition_partner'), isFalse);
      });
    });

    group('copyWith', () {
      test('should copy with new destination', () {
        final updated = testModel.copyWith(destination: 'Jakarta');
        expect(updated.destination, 'Jakarta');
        expect(updated.id, testModel.id);
        expect(updated.sackNumber, testModel.sackNumber);
      });

      test('should return identical copy when no changes', () {
        final copy = testModel.copyWith();
        expect(copy.id, testModel.id);
        expect(copy.destination, testModel.destination);
      });
    });

    group('toString', () {
      test('should contain class name and key fields', () {
        final str = testModel.toString();
        expect(str, contains('ExpeditionModel'));
        expect(str, contains(testId));
        expect(str, contains(testDestination));
      });
    });

    group('Equality', () {
      test('should be equal when ids are the same', () {
        final a = ExpeditionModel(
          id: testId,
          idPartner: testPartnerId,
          expeditionDate: testDate,
          destination: testDestination,
          sackNumber: 10,
          totalWeight: 500,
          proofOfDelivery: '',
        );
        final b = ExpeditionModel(
          id: testId,
          idPartner: 'different',
          expeditionDate: DateTime(2000),
          destination: 'different',
          sackNumber: 99,
          totalWeight: 99,
          proofOfDelivery: '',
        );
        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('should not be equal when ids differ', () {
        final a = testModel;
        final b = testModel.copyWith(id: 'different-id');
        expect(a == b, isFalse);
      });
    });
  });
}
