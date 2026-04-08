import 'package:intl/intl.dart';

/// Helper class for consistent Indonesian Rupiah formatting
/// following EYD/PUEBI standards:
/// - 'Rp' directly before the number (no space)
/// - Period (.) as thousands separator
/// - Comma (,) as decimal separator
/// - Example: Rp100.000
class CurrencyHelper {
  CurrencyHelper._();

  /// Standard Rupiah formatter without decimals
  static final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Format a number as Rupiah string (e.g. Rp100.000)
  static String formatRupiah(num value) => currencyFormat.format(value);
}
