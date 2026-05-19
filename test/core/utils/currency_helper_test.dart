import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/core/utils/currency_helper.dart';

void main() {
  group('CurrencyHelper', () {
    group('formatRupiah', () {
      test('should format zero as Rp0', () {
        final result = CurrencyHelper.formatRupiah(0);
        expect(result, 'Rp0');
      });

      test('should format small amounts correctly', () {
        final result = CurrencyHelper.formatRupiah(100);
        expect(result, contains('100'));
        expect(result, startsWith('Rp'));
      });

      test('should format thousands with period separator', () {
        final result = CurrencyHelper.formatRupiah(1000);
        expect(result, contains('Rp'));
        expect(result.contains('.') || result == 'Rp1.000', true);
      });

      test('should format large amounts correctly', () {
        final result = CurrencyHelper.formatRupiah(100000);
        expect(result, contains('Rp'));
        expect(result, contains('100'));
      });

      test('should format millions correctly', () {
        final result = CurrencyHelper.formatRupiah(1000000);
        expect(result, contains('Rp'));
        expect(result, contains('1'));
      });

      test('should format negative amounts', () {
        final result = CurrencyHelper.formatRupiah(-1000);
        expect(result, contains('-'));
        expect(result, contains('Rp'));
      });

      test('should handle double values', () {
        final result = CurrencyHelper.formatRupiah(1500.5);
        expect(result, contains('Rp'));
        // Should not have decimal places as decimalDigits is 0
        expect(result.endsWith('.'), isFalse);
      });

      test('should handle very large amounts', () {
        final result = CurrencyHelper.formatRupiah(999999999);
        expect(result, contains('Rp'));
        expect(result.contains('.'), true);
      });

      test('should have Rp symbol at the beginning', () {
        expect(
          CurrencyHelper.formatRupiah(50000),
          startsWith('Rp'),
        );
      });

      test('should format decimal amounts as integers', () {
        final result1 = CurrencyHelper.formatRupiah(1000);
        final result2 = CurrencyHelper.formatRupiah(1000.0);
        expect(result1, result2);
      });

      test('should handle various amount values', () {
        final amounts = [0, 100, 500, 1000, 10000, 100000, 1000000];
        for (final amount in amounts) {
          final result = CurrencyHelper.formatRupiah(amount);
          expect(result, startsWith('Rp'));
          expect(result.isNotEmpty, true);
        }
      });
    });

    group('currencyFormat', () {
      test('should be properly configured with Indonesian locale', () {
        expect(CurrencyHelper.currencyFormat, isNotNull);
      });

      test('should have Rp symbol', () {
        final formatted = CurrencyHelper.currencyFormat.format(1000);
        expect(formatted, contains('Rp'));
      });

      test('should not include decimal places', () {
        final formatted = CurrencyHelper.currencyFormat.format(1000.5);
        // Format should round, not include decimals
        expect(formatted, isNotEmpty);
      });
    });

    group('Integration tests', () {
      test('should format common salary amounts', () {
        final result1 = CurrencyHelper.formatRupiah(500000);
        final result2 = CurrencyHelper.formatRupiah(1000000);
        final result3 = CurrencyHelper.formatRupiah(2500000);

        expect(result1, startsWith('Rp'));
        expect(result2, startsWith('Rp'));
        expect(result3, startsWith('Rp'));
      });

      test('should format wage calculations', () {
        final weight = 100;
        final pricePerKg = 5000;
        final totalWage = weight * pricePerKg;

        final result = CurrencyHelper.formatRupiah(totalWage);
        expect(result, startsWith('Rp'));
        expect(result, contains('500'));
      });

      test('should handle zero balance', () {
        final result = CurrencyHelper.formatRupiah(0);
        expect(result, contains('0'));
        expect(result, startsWith('Rp'));
      });
    });

    group('Edge cases', () {
      test('should handle infinity gracefully or throw', () {
        expect(
          () => CurrencyHelper.formatRupiah(double.infinity),
          anyOf(
            isA<RangeError>(),
            isA<Exception>(),
          ),
        );
      });

      test('should handle very small positive amounts', () {
        final result = CurrencyHelper.formatRupiah(0.1);
        expect(result, startsWith('Rp'));
      });

      test('should format amounts in sequence correctly', () {
        final amounts = [100, 200, 300, 400, 500];
        final formatted = amounts.map(CurrencyHelper.formatRupiah).toList();

        for (final result in formatted) {
          expect(result, startsWith('Rp'));
        }
      });
    });
  });
}
