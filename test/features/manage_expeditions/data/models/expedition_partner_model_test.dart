import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_expeditions/data/models/expedition_partner_model.dart';

void main() {
  group('ExpeditionPartnerModel', () {
    const testId = 'exp-partner-001';
    const testName = 'JNE Express';
    const testNoTelp = '021-12345678';
    const testAddress = 'Jl. Ekspedisi No. 1, Jakarta';

    final validJson = {
      'id': testId,
      'name': testName,
      'no_telp': testNoTelp,
      'address': testAddress,
    };

    late ExpeditionPartnerModel testModel;

    setUp(() {
      testModel = ExpeditionPartnerModel(
        id: testId,
        name: testName,
        noTelp: testNoTelp,
        address: testAddress,
      );
    });

    group('Constructor', () {
      test('should create model with all fields', () {
        expect(testModel.id, testId);
        expect(testModel.name, testName);
        expect(testModel.noTelp, testNoTelp);
        expect(testModel.address, testAddress);
      });

      test('should allow null noTelp and address', () {
        final model = ExpeditionPartnerModel(id: testId, name: testName);
        expect(model.noTelp, isNull);
        expect(model.address, isNull);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final model = ExpeditionPartnerModel.fromJson(validJson);

        expect(model.id, testId);
        expect(model.name, testName);
        expect(model.noTelp, testNoTelp);
        expect(model.address, testAddress);
      });

      test('should default id to empty string when null', () {
        final model = ExpeditionPartnerModel.fromJson({'id': null, 'name': null});
        expect(model.id, '');
        expect(model.name, 'Tanpa Nama');
      });

      test('should handle fully empty JSON', () {
        final model = ExpeditionPartnerModel.fromJson({});
        expect(model.id, '');
        expect(model.name, 'Tanpa Nama');
        expect(model.noTelp, isNull);
        expect(model.address, isNull);
      });

      test('should parse optional noTelp and address as null when missing', () {
        final minimalJson = {'id': testId, 'name': testName};
        final model = ExpeditionPartnerModel.fromJson(minimalJson);
        expect(model.noTelp, isNull);
        expect(model.address, isNull);
      });
    });

    group('toJson', () {
      test('should produce correct JSON with all fields', () {
        final json = testModel.toJson();

        expect(json['id'], testId);
        expect(json['name'], testName);
        expect(json['no_telp'], testNoTelp);
        expect(json['address'], testAddress);
      });

      test('should not include noTelp when null', () {
        final model = ExpeditionPartnerModel(id: testId, name: testName);
        final json = model.toJson();
        expect(json.containsKey('no_telp'), isFalse);
      });

      test('should not include address when null', () {
        final model = ExpeditionPartnerModel(id: testId, name: testName);
        final json = model.toJson();
        expect(json.containsKey('address'), isFalse);
      });
    });

    group('copyWith', () {
      test('should copy with new name', () {
        final updated = testModel.copyWith(name: 'TIKI');
        expect(updated.name, 'TIKI');
        expect(updated.id, testModel.id);
        expect(updated.noTelp, testModel.noTelp);
      });

      test('should return same fields when no changes provided', () {
        final copy = testModel.copyWith();
        expect(copy.id, testModel.id);
        expect(copy.name, testModel.name);
        expect(copy.noTelp, testModel.noTelp);
        expect(copy.address, testModel.address);
      });
    });

    group('toString', () {
      test('should contain class name and key fields', () {
        final str = testModel.toString();
        expect(str, contains('ExpeditionPartnerModel'));
        expect(str, contains(testId));
        expect(str, contains(testName));
      });
    });

    group('Equality', () {
      test('should be equal when ids are the same', () {
        final a = ExpeditionPartnerModel(id: testId, name: testName);
        final b = ExpeditionPartnerModel(
          id: testId,
          name: 'Different Name',
          noTelp: '999',
        );
        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('should not be equal when ids differ', () {
        final a = ExpeditionPartnerModel(id: testId, name: testName);
        final b = ExpeditionPartnerModel(id: 'other-id', name: testName);
        expect(a == b, isFalse);
      });
    });
  });
}
