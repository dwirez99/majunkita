import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_factories/data/models/factory_model.dart';

void main() {
  group('FactoryModel', () {
    const testId = 'factory-001';
    const testFactoryName = 'PT. Tekstil Indonesia';
    const testAddress = 'Jl. Industri No. 123, Bandung';
    const testNoTelp = '0274-123456';

    final testJson = {
      'id': testId,
      'factory_name': testFactoryName,
      'address': testAddress,
      'no_telp': testNoTelp,
    };

    late FactoryModel testFactory;

    setUp(() {
      testFactory = FactoryModel(
        id: testId,
        factoryName: testFactoryName,
        address: testAddress,
        noTelp: testNoTelp,
      );
    });

    group('Constructor', () {
      test('should create FactoryModel with all required fields', () {
        expect(testFactory.id, testId);
        expect(testFactory.factoryName, testFactoryName);
        expect(testFactory.address, testAddress);
        expect(testFactory.noTelp, testNoTelp);
      });
    });

    group('fromJson', () {
      test('should create FactoryModel from valid JSON', () {
        final factory = FactoryModel.fromJson(testJson);

        expect(factory.id, testId);
        expect(factory.factoryName, testFactoryName);
        expect(factory.address, testAddress);
        expect(factory.noTelp, testNoTelp);
      });

      test('should handle missing fields with empty strings', () {
        final factory = FactoryModel.fromJson({});

        expect(factory.id, '');
        expect(factory.factoryName, '');
        expect(factory.address, '');
        expect(factory.noTelp, '');
      });

      test('should handle null values gracefully', () {
        final factory = FactoryModel.fromJson({
          'id': null,
          'factory_name': null,
          'address': null,
          'no_telp': null,
        });

        expect(factory.id, '');
        expect(factory.factoryName, '');
        expect(factory.address, '');
        expect(factory.noTelp, '');
      });

      test('should handle partial JSON data', () {
        final factory = FactoryModel.fromJson({
          'id': testId,
          'factory_name': testFactoryName,
        });

        expect(factory.id, testId);
        expect(factory.factoryName, testFactoryName);
        expect(factory.address, '');
        expect(factory.noTelp, '');
      });
    });

    group('toJson', () {
      test('should convert FactoryModel to JSON correctly', () {
        final json = testFactory.toJson();

        expect(json['id'], testId);
        expect(json['factory_name'], testFactoryName);
        expect(json['address'], testAddress);
        expect(json['no_telp'], testNoTelp);
      });

      test('should include all fields in JSON output', () {
        final json = testFactory.toJson();

        expect(json.containsKey('id'), true);
        expect(json.containsKey('factory_name'), true);
        expect(json.containsKey('address'), true);
        expect(json.containsKey('no_telp'), true);
        expect(json.length, 4);
      });

      test('should preserve values in toJson', () {
        final factory = FactoryModel(
          id: 'test-123',
          factoryName: 'Test Factory',
          address: 'Test Address',
          noTelp: '081234567890',
        );

        final json = factory.toJson();
        final restored = FactoryModel.fromJson(json);

        expect(restored.id, factory.id);
        expect(restored.factoryName, factory.factoryName);
        expect(restored.address, factory.address);
        expect(restored.noTelp, factory.noTelp);
      });
    });

    group('copyWith', () {
      test('should copy with new factory name', () {
        final updated = testFactory.copyWith(factoryName: 'PT. Tekstil Baru');

        expect(updated.id, testFactory.id);
        expect(updated.factoryName, 'PT. Tekstil Baru');
        expect(updated.address, testFactory.address);
        expect(updated.noTelp, testFactory.noTelp);
      });

      test('should copy with new address', () {
        final updated = testFactory.copyWith(address: 'Jl. Baru No. 456');

        expect(updated.id, testFactory.id);
        expect(updated.factoryName, testFactory.factoryName);
        expect(updated.address, 'Jl. Baru No. 456');
        expect(updated.noTelp, testFactory.noTelp);
      });

      test('should copy with new phone number', () {
        final updated = testFactory.copyWith(noTelp: '0274-654321');

        expect(updated.id, testFactory.id);
        expect(updated.factoryName, testFactory.factoryName);
        expect(updated.address, testFactory.address);
        expect(updated.noTelp, '0274-654321');
      });

      test('should copy with multiple changes', () {
        final updated = testFactory.copyWith(
          factoryName: 'New Factory',
          address: 'New Address',
          noTelp: '0274-999999',
        );

        expect(updated.id, testFactory.id); // id should not change
        expect(updated.factoryName, 'New Factory');
        expect(updated.address, 'New Address');
        expect(updated.noTelp, '0274-999999');
      });

      test('should return identical copy when no changes provided', () {
        final copy = testFactory.copyWith();

        expect(copy.id, testFactory.id);
        expect(copy.factoryName, testFactory.factoryName);
        expect(copy.address, testFactory.address);
        expect(copy.noTelp, testFactory.noTelp);
      });

      test('should not modify original when using copyWith', () {
        final original = FactoryModel(
          id: 'id-1',
          factoryName: 'Original',
          address: 'Original Address',
          noTelp: '0274-111111',
        );

        final modified = original.copyWith(factoryName: 'Modified');

        expect(original.factoryName, 'Original');
        expect(modified.factoryName, 'Modified');
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final str = testFactory.toString();

        expect(str, contains('FactoryModel'));
        expect(str, contains(testId));
        expect(str, contains(testFactoryName));
        expect(str, contains(testAddress));
      });

      test('should include factory information', () {
        final factory = FactoryModel(
          id: 'factory-001',
          factoryName: 'PT. Test',
          address: 'Test Address',
          noTelp: '081234567890',
        );

        expect(factory.toString(), contains('PT. Test'));
        expect(factory.toString(), contains('Test Address'));
      });
    });

    group('Equality', () {
      test('should be equal when ids are the same', () {
        final a = FactoryModel(
          id: testId,
          factoryName: 'Name A',
          address: 'Address A',
          noTelp: '081111111111',
        );

        final b = FactoryModel(
          id: testId,
          factoryName: 'Name B',
          address: 'Address B',
          noTelp: '082222222222',
        );

        expect(a == b, isTrue);
      });

      test('should not be equal when ids differ', () {
        final a = testFactory;
        final b = testFactory.copyWith(id: 'factory-002');

        expect(a == b, isFalse);
      });

      test('should have same hashCode when ids are equal', () {
        final a = FactoryModel(
          id: testId,
          factoryName: 'Name A',
          address: 'Address A',
          noTelp: '081111111111',
        );

        final b = FactoryModel(
          id: testId,
          factoryName: 'Name B',
          address: 'Address B',
          noTelp: '082222222222',
        );

        expect(a.hashCode, b.hashCode);
      });

      test('should have different hashCode when ids differ', () {
        final a = FactoryModel(
          id: 'id-1',
          factoryName: 'Name',
          address: 'Address',
          noTelp: '081111111111',
        );

        final b = FactoryModel(
          id: 'id-2',
          factoryName: 'Name',
          address: 'Address',
          noTelp: '081111111111',
        );

        expect(a.hashCode, isNot(b.hashCode));
      });

      test('should support equality in collections', () {
        final factory1 = FactoryModel(
          id: 'id-1',
          factoryName: 'Factory 1',
          address: 'Address 1',
          noTelp: '081111111111',
        );

        final factory2 = FactoryModel(
          id: 'id-1',
          factoryName: 'Factory 1 Updated',
          address: 'Address 1 Updated',
          noTelp: '081111111111',
        );

        final list = [factory1];
        expect(list.contains(factory2), isTrue);
      });
    });

    group('JSON round-trip', () {
      test('should maintain data through fromJson -> toJson -> fromJson', () {
        final original = testFactory;
        final json = original.toJson();
        final restored = FactoryModel.fromJson(json);

        expect(restored, original);
        expect(restored.id, original.id);
        expect(restored.factoryName, original.factoryName);
        expect(restored.address, original.address);
        expect(restored.noTelp, original.noTelp);
      });
    });

    group('Edge cases', () {
      test('should handle empty string values', () {
        final factory = FactoryModel(
          id: '',
          factoryName: '',
          address: '',
          noTelp: '',
        );

        expect(factory.id, '');
        expect(factory.factoryName, '');
        expect(factory.address, '');
        expect(factory.noTelp, '');
      });

      test('should handle very long strings', () {
        final longString = 'A' * 1000;
        final factory = FactoryModel(
          id: longString,
          factoryName: longString,
          address: longString,
          noTelp: longString,
        );

        expect(factory.id.length, 1000);
        expect(factory.factoryName.length, 1000);
      });

      test('should handle special characters in strings', () {
        final factory = FactoryModel(
          id: 'id-123!@#$%',
          factoryName: 'Pabrik Tekstil & Garmen "ABC"',
          address: 'Jl. Sukabumi No. 123 - 456, Kota Bandung',
          noTelp: '+62-274-123-456 ext.789',
        );

        expect(factory.id, contains('!@#$%'));
        expect(factory.factoryName, contains('&'));
        expect(factory.address, contains('-'));
        expect(factory.noTelp, contains('+'));
      });
    });
  });
}
