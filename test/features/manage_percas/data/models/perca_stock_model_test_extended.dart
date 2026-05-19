import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_percas/data/models/perca_stock_model.dart';

void main() {
  group('PercasStock', () {
    const testIdFactory = 'factory-001';
    final testDateEntry = DateTime(2024, 7, 1);
    const testPercaType = 'kaos';
    const testWeight = 50.0;
    const testDeliveryProof = 'https://example.com/proof.jpg';
    const testSackCode = 'K-50';

    late PercasStock testStock;

    setUp(() {
      testStock = PercasStock(
        idFactory: testIdFactory,
        dateEntry: testDateEntry,
        percaType: testPercaType,
        weight: testWeight,
        deliveryProof: testDeliveryProof,
        sackCode: testSackCode,
      );
    });

    group('Constructor', () {
      test('should create PercasStock with all required fields', () {
        expect(testStock.idFactory, testIdFactory);
        expect(testStock.dateEntry, testDateEntry);
        expect(testStock.percaType, testPercaType);
        expect(testStock.weight, testWeight);
        expect(testStock.deliveryProof, testDeliveryProof);
        expect(testStock.sackCode, testSackCode);
      });

      test('should create instance with valid kaos type', () {
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: DateTime.now(),
          percaType: 'kaos',
          weight: 25.0,
          deliveryProof: 'https://example.com/proof1.jpg',
          sackCode: 'K-25',
        );
        expect(stock.percaType, 'kaos');
      });

      test('should create instance with valid kain type', () {
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: DateTime.now(),
          percaType: 'kain',
          weight: 30.0,
          deliveryProof: 'https://example.com/proof2.jpg',
          sackCode: 'B-30',
        );
        expect(stock.percaType, 'kain');
      });
    });

    group('generateSackCode', () {
      test('should generate sack code for kaos with integer weight', () {
        final code = PercasStock.generateSackCode('kaos', 50.0);
        expect(code, 'K-50');
      });

      test('should generate sack code for kain with integer weight', () {
        final code = PercasStock.generateSackCode('kain', 50.0);
        expect(code, 'B-50');
      });

      test('should generate sack code for kaos with decimal weight', () {
        final code = PercasStock.generateSackCode('kaos', 50.5);
        expect(code, 'K-50.50');
      });

      test('should generate sack code for kain with decimal weight', () {
        final code = PercasStock.generateSackCode('kain', 25.75);
        expect(code, 'B-25.75');
      });

      test('should handle lowercase kaos', () {
        final code = PercasStock.generateSackCode('kaos', 45.0);
        expect(code, startsWith('K-'));
      });

      test('should handle lowercase kain', () {
        final code = PercasStock.generateSackCode('kain', 35.0);
        expect(code, startsWith('B-'));
      });

      test('should handle uppercase KAOS', () {
        final code = PercasStock.generateSackCode('KAOS', 45.0);
        expect(code, startsWith('K-'));
      });

      test('should handle uppercase KAIN', () {
        final code = PercasStock.generateSackCode('KAIN', 35.0);
        expect(code, startsWith('B-'));
      });

      test('should handle mixed case', () {
        final code1 = PercasStock.generateSackCode('Kaos', 45.0);
        final code2 = PercasStock.generateSackCode('Kain', 35.0);
        expect(code1, startsWith('K-'));
        expect(code2, startsWith('B-'));
      });

      test('should use B for any non-kaos type', () {
        final code = PercasStock.generateSackCode('bahan', 50.0);
        expect(code, startsWith('B-'));
      });

      test('should handle very small weights', () {
        final code = PercasStock.generateSackCode('kaos', 0.1);
        expect(code, 'K-0.10');
      });

      test('should handle large weights', () {
        final code = PercasStock.generateSackCode('kaos', 999.0);
        expect(code, 'K-999');
      });

      test('should handle large decimal weights', () {
        final code = PercasStock.generateSackCode('kaos', 999.99);
        expect(code, 'K-999.99');
      });

      test('should generate consistent codes for same inputs', () {
        final code1 = PercasStock.generateSackCode('kaos', 50.0);
        final code2 = PercasStock.generateSackCode('kaos', 50.0);
        expect(code1, code2);
      });

      test('should handle zero weight', () {
        final code = PercasStock.generateSackCode('kaos', 0.0);
        expect(code, 'K-0');
      });
    });

    group('toJson', () {
      test('should convert PercasStock to JSON correctly', () {
        final json = testStock.toJson();

        expect(json['id_factory'], testIdFactory);
        expect(json['perca_type'], testPercaType);
        expect(json['weight'], testWeight);
        expect(json['delivery_proof'], testDeliveryProof);
        expect(json['sack_code'], testSackCode);
      });

      test('should format date_entry as ISO 8601 string', () {
        final json = testStock.toJson();

        expect(json['date_entry'], contains('2024'));
        expect(json['date_entry'], contains('07'));
        expect(json['date_entry'], isA<String>());
      });

      test('should include all required fields', () {
        final json = testStock.toJson();

        expect(json.containsKey('id_factory'), true);
        expect(json.containsKey('date_entry'), true);
        expect(json.containsKey('perca_type'), true);
        expect(json.containsKey('weight'), true);
        expect(json.containsKey('delivery_proof'), true);
        expect(json.containsKey('sack_code'), true);
        expect(json.length, 6);
      });

      test('should preserve values in toJson', () {
        final stock = PercasStock(
          idFactory: 'factory-test',
          dateEntry: DateTime(2024, 6, 15),
          percaType: 'kain',
          weight: 75.5,
          deliveryProof: 'https://example.com/test.jpg',
          sackCode: 'B-75.50',
        );

        final json = stock.toJson();

        expect(json['id_factory'], 'factory-test');
        expect(json['perca_type'], 'kain');
        expect(json['weight'], 75.5);
        expect(json['sack_code'], 'B-75.50');
      });

      test('should handle date conversion correctly', () {
        final dateTime = DateTime(2024, 12, 25, 14, 30, 45);
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: dateTime,
          percaType: 'kaos',
          weight: 50.0,
          deliveryProof: 'https://example.com/proof.jpg',
          sackCode: 'K-50',
        );

        final json = stock.toJson();
        final parsedDate = DateTime.parse(json['date_entry']);

        expect(parsedDate.year, 2024);
        expect(parsedDate.month, 12);
        expect(parsedDate.day, 25);
      });
    });

    group('Integration tests', () {
      test('should create stock with auto-generated sack code', () {
        final sackCode = PercasStock.generateSackCode('kaos', 60.0);
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: DateTime.now(),
          percaType: 'kaos',
          weight: 60.0,
          deliveryProof: 'https://example.com/proof.jpg',
          sackCode: sackCode,
        );

        expect(stock.sackCode, 'K-60');
      });

      test('should support multiple perca types in collection', () {
        final kaosStock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: DateTime.now(),
          percaType: 'kaos',
          weight: 50.0,
          deliveryProof: 'https://example.com/proof1.jpg',
          sackCode: 'K-50',
        );

        final kainStock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: DateTime.now(),
          percaType: 'kain',
          weight: 60.0,
          deliveryProof: 'https://example.com/proof2.jpg',
          sackCode: 'B-60',
        );

        final stocks = [kaosStock, kainStock];
        expect(stocks.length, 2);
        expect(stocks[0].percaType, 'kaos');
        expect(stocks[1].percaType, 'kain');
      });

      test('should handle JSON serialization round-trip', () {
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: DateTime(2024, 7, 1),
          percaType: 'kaos',
          weight: 50.0,
          deliveryProof: 'https://example.com/proof.jpg',
          sackCode: 'K-50',
        );

        final json = stock.toJson();
        
        expect(json['id_factory'], stock.idFactory);
        expect(json['perca_type'], stock.percaType);
        expect(json['weight'], stock.weight);
        expect(json['sack_code'], stock.sackCode);
      });
    });

    group('Edge cases', () {
      test('should handle special characters in factory ID', () {
        final stock = PercasStock(
          idFactory: 'factory-!@#$%',
          dateEntry: DateTime.now(),
          percaType: 'kaos',
          weight: 50.0,
          deliveryProof: 'https://example.com/proof.jpg',
          sackCode: 'K-50',
        );

        expect(stock.idFactory, contains('!@#$%'));
      });

      test('should handle special characters in URL', () {
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: DateTime.now(),
          percaType: 'kaos',
          weight: 50.0,
          deliveryProof: 'https://example.com/proof?id=123&token=abc%20def',
          sackCode: 'K-50',
        );

        expect(stock.deliveryProof, contains('?'));
        expect(stock.deliveryProof, contains('%'));
      });

      test('should handle very large decimal weights', () {
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: DateTime.now(),
          percaType: 'kaos',
          weight: 99999.999,
          deliveryProof: 'https://example.com/proof.jpg',
          sackCode: 'K-99999.99',
        );

        expect(stock.weight, 99999.999);
        expect(stock.sackCode, 'K-99999.99');
      });

      test('should handle past dates', () {
        final pastDate = DateTime(2000, 1, 1);
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: pastDate,
          percaType: 'kaos',
          weight: 50.0,
          deliveryProof: 'https://example.com/proof.jpg',
          sackCode: 'K-50',
        );

        expect(stock.dateEntry.year, 2000);
      });

      test('should handle future dates', () {
        final futureDate = DateTime(2050, 12, 31);
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: futureDate,
          percaType: 'kaos',
          weight: 50.0,
          deliveryProof: 'https://example.com/proof.jpg',
          sackCode: 'K-50',
        );

        expect(stock.dateEntry.year, 2050);
      });
    });
  });
}
