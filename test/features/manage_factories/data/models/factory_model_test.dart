import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/features/manage_factories/data/models/factory_model.dart';

void main() {
  group('FactoryModel', () {
    const testId = 'factory-123';
    const testFactoryName = 'PT Maju Jaya';
    const testAddress = 'Jl. Industri No. 123, Jakarta';
    const testNoTelp = '021-12345678';

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
      test('should create FactoryModel with required parameters', () {
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

      test('should handle null values in JSON', () {
        final jsonWithNulls = {
          'id': null,
          'factory_name': null,
          'address': null,
          'no_telp': null,
        };

        final factory = FactoryModel.fromJson(jsonWithNulls);

        expect(factory.id, '');
        expect(factory.factoryName, '');
        expect(factory.address, '');
        expect(factory.noTelp, '');
      });

      test('should handle missing keys in JSON', () {
        final incompleteJson = <String, dynamic>{};

        final factory = FactoryModel.fromJson(incompleteJson);

        expect(factory.id, '');
        expect(factory.factoryName, '');
        expect(factory.address, '');
        expect(factory.noTelp, '');
      });

      test('should handle partial JSON data', () {
        final partialJson = {
          'id': testId,
          'factory_name': testFactoryName,
          // address and no_telp missing
        };

        final factory = FactoryModel.fromJson(partialJson);

        expect(factory.id, testId);
        expect(factory.factoryName, testFactoryName);
        expect(factory.address, '');
        expect(factory.noTelp, '');
      });
    });

    group('toJson', () {
      test('should convert FactoryModel to JSON correctly', () {
        final json = testFactory.toJson();

        expect(json, testJson);
      });

      test('should handle empty FactoryModel', () {
        final emptyFactory = FactoryModel(
          id: '',
          factoryName: '',
          address: '',
          noTelp: '',
        );

        final json = emptyFactory.toJson();

        expect(json, {
          'id': '',
          'factory_name': '',
          'address': '',
          'no_telp': '',
        });
      });
    });

    group('copyWith', () {
      test('should return same object when no parameters provided', () {
        final copied = testFactory.copyWith();

        expect(copied, testFactory);
        expect(identical(copied, testFactory), isFalse); // Different instances
      });

      test('should copy with new id', () {
        const newId = 'factory-456';
        final copied = testFactory.copyWith(id: newId);

        expect(copied.id, newId);
        expect(copied.factoryName, testFactoryName);
        expect(copied.address, testAddress);
        expect(copied.noTelp, testNoTelp);
      });

      test('should copy with new factoryName', () {
        const newName = 'PT Baru Maju';
        final copied = testFactory.copyWith(factoryName: newName);

        expect(copied.id, testId);
        expect(copied.factoryName, newName);
        expect(copied.address, testAddress);
        expect(copied.noTelp, testNoTelp);
      });

      test('should copy with new address', () {
        const newAddress = 'Jl. Baru No. 456, Bandung';
        final copied = testFactory.copyWith(address: newAddress);

        expect(copied.id, testId);
        expect(copied.factoryName, testFactoryName);
        expect(copied.address, newAddress);
        expect(copied.noTelp, testNoTelp);
      });

      test('should copy with new noTelp', () {
        const newTelp = '022-87654321';
        final copied = testFactory.copyWith(noTelp: newTelp);

        expect(copied.id, testId);
        expect(copied.factoryName, testFactoryName);
        expect(copied.address, testAddress);
        expect(copied.noTelp, newTelp);
      });

      test('should copy with multiple new values', () {
        const newId = 'factory-789';
        const newName = 'PT Maju Terus';
        const newAddress = 'Jl. Maju Mundur No. 999';
        const newTelp = '031-99999999';

        final copied = testFactory.copyWith(
          id: newId,
          factoryName: newName,
          address: newAddress,
          noTelp: newTelp,
        );

        expect(copied.id, newId);
        expect(copied.factoryName, newName);
        expect(copied.address, newAddress);
        expect(copied.noTelp, newTelp);
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all properties are the same', () {
        final factory1 = FactoryModel(
          id: testId,
          factoryName: testFactoryName,
          address: testAddress,
          noTelp: testNoTelp,
        );

        final factory2 = FactoryModel(
          id: testId,
          factoryName: testFactoryName,
          address: testAddress,
          noTelp: testNoTelp,
        );

        expect(factory1, factory2);
        expect(factory1.hashCode, factory2.hashCode);
      });

      test('should not be equal when id is different', () {
        final factory1 = FactoryModel(
          id: testId,
          factoryName: testFactoryName,
          address: testAddress,
          noTelp: testNoTelp,
        );

        final factory2 = FactoryModel(
          id: 'different-id',
          factoryName: testFactoryName,
          address: testAddress,
          noTelp: testNoTelp,
        );

        expect(factory1, isNot(factory2));
        expect(factory1.hashCode, isNot(factory2.hashCode));
      });

      test('should be equal when only id matches (equality based on id only)', () {
        final factory1 = FactoryModel(
          id: testId,
          factoryName: testFactoryName,
          address: testAddress,
          noTelp: testNoTelp,
        );

        final factory2 = FactoryModel(
          id: testId, // Same id
          factoryName: 'Different Name',
          address: 'Different Address',
          noTelp: 'Different Telp',
        );

        // Should be equal because id is the same
        expect(factory1, factory2);
        expect(factory1.hashCode, factory2.hashCode);
      });

      test('should not be equal when id is different', () {
        final factory1 = FactoryModel(
          id: testId,
          factoryName: testFactoryName,
          address: testAddress,
          noTelp: testNoTelp,
        );

        final factory2 = FactoryModel(
          id: 'different-id',
          factoryName: testFactoryName,
          address: testAddress,
          noTelp: testNoTelp,
        );

        expect(factory1, isNot(factory2));
        expect(factory1.hashCode, isNot(factory2.hashCode));
      });
    });

    group('toString', () {
      test('should return correct string representation', () {
        final expectedString = 'FactoryModel(id: $testId, factoryName: $testFactoryName, address: $testAddress)';
        expect(testFactory.toString(), expectedString);
      });
    });
  });
}