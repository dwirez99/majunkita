import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_tailors/domain/utils/prediction_model_utils.dart';

void main() {
  group('PredictionModelUtils – Rasio Efisiensi Historis (Reff)', () {
    // ── calculateReff ────────────────────────────────────────────────────────

    test('returns correct Reff for normal values', () {
      // Reff = 80 / 100 = 0.8
      final reff = PredictionModelUtils.calculateReff(
        totalMajunDisetor: 80,
        totalPercaDiambil: 100,
      );
      expect(reff, closeTo(0.8, 0.0001));
    });

    test('returns 0 when totalPercaDiambil is 0 (penjahit baru, divide-by-zero protection)', () {
      final reff = PredictionModelUtils.calculateReff(
        totalMajunDisetor: 50,
        totalPercaDiambil: 0,
      );
      expect(reff, 0.0);
    });

    test('returns 0 when totalPercaDiambil is negative', () {
      final reff = PredictionModelUtils.calculateReff(
        totalMajunDisetor: 50,
        totalPercaDiambil: -10,
      );
      expect(reff, 0.0);
    });

    test('returns 0 when both inputs are 0', () {
      final reff = PredictionModelUtils.calculateReff(
        totalMajunDisetor: 0,
        totalPercaDiambil: 0,
      );
      expect(reff, 0.0);
    });

    test('returns 0 when totalMajunDisetor is 0 but totalPercaDiambil is positive', () {
      final reff = PredictionModelUtils.calculateReff(
        totalMajunDisetor: 0,
        totalPercaDiambil: 100,
      );
      expect(reff, 0.0);
    });

    test('Reff can be greater than 1.0 if majun exceeds perca taken', () {
      // Edge case: majun output is somehow greater than perca input
      final reff = PredictionModelUtils.calculateReff(
        totalMajunDisetor: 120,
        totalPercaDiambil: 100,
      );
      expect(reff, closeTo(1.2, 0.0001));
    });

    test('Reff = 1.0 when majun equals perca (100% efficiency)', () {
      final reff = PredictionModelUtils.calculateReff(
        totalMajunDisetor: 100,
        totalPercaDiambil: 100,
      );
      expect(reff, closeTo(1.0, 0.0001));
    });

    test('handles fractional values correctly', () {
      final reff = PredictionModelUtils.calculateReff(
        totalMajunDisetor: 33.3,
        totalPercaDiambil: 66.6,
      );
      expect(reff, closeTo(0.5, 0.0001));
    });
  });

  group('PredictionModelUtils – Prediksi Produksi Majun', () {
    // ── calculatePrediksiMajun ───────────────────────────────────────────────

    test('returns correct prediction for normal values', () {
      // Prediksi = 200 kg * 0.8 = 160 kg
      final prediksi = PredictionModelUtils.calculatePrediksiMajun(
        sisaPerca: 200,
        reff: 0.8,
      );
      expect(prediksi, closeTo(160.0, 0.0001));
    });

    test('returns 0 when sisaPerca is 0 (no stock)', () {
      final prediksi = PredictionModelUtils.calculatePrediksiMajun(
        sisaPerca: 0,
        reff: 0.8,
      );
      expect(prediksi, 0.0);
    });

    test('returns 0 when reff is 0 (no historical data)', () {
      final prediksi = PredictionModelUtils.calculatePrediksiMajun(
        sisaPerca: 200,
        reff: 0,
      );
      expect(prediksi, 0.0);
    });

    test('returns 0 when both sisaPerca and reff are 0', () {
      final prediksi = PredictionModelUtils.calculatePrediksiMajun(
        sisaPerca: 0,
        reff: 0,
      );
      expect(prediksi, 0.0);
    });

    test('handles fractional sisaPerca and reff correctly', () {
      final prediksi = PredictionModelUtils.calculatePrediksiMajun(
        sisaPerca: 50.5,
        reff: 0.6,
      );
      expect(prediksi, closeTo(30.3, 0.0001));
    });
  });

  group('PredictionModelUtils – calculateEfficiencyStats (integrated flow)', () {
    test('returns correct reff and prediksi_majun for normal data', () {
      final stats = PredictionModelUtils.calculateEfficiencyStats(
        totalMajunDisetor: 80,
        totalPercaDiambil: 100,
        sisaPerca: 200,
      );
      expect(stats['reff'], closeTo(0.8, 0.0001));
      expect(stats['prediksi_majun'], closeTo(160.0, 0.0001));
    });

    test('returns zeros for new tailor with no history (totalPercaDiambil = 0)', () {
      final stats = PredictionModelUtils.calculateEfficiencyStats(
        totalMajunDisetor: 0,
        totalPercaDiambil: 0,
        sisaPerca: 50,
      );
      expect(stats['reff'], 0.0);
      expect(stats['prediksi_majun'], 0.0);
    });

    test('returns zero prediction when stock is 0 even with good reff', () {
      final stats = PredictionModelUtils.calculateEfficiencyStats(
        totalMajunDisetor: 80,
        totalPercaDiambil: 100,
        sisaPerca: 0,
      );
      expect(stats['reff'], closeTo(0.8, 0.0001));
      expect(stats['prediksi_majun'], 0.0);
    });

    test('full cycle: tailor with large stock and perfect efficiency', () {
      final stats = PredictionModelUtils.calculateEfficiencyStats(
        totalMajunDisetor: 500,
        totalPercaDiambil: 500,
        sisaPerca: 300,
      );
      expect(stats['reff'], closeTo(1.0, 0.0001));
      expect(stats['prediksi_majun'], closeTo(300.0, 0.0001));
    });
  });
}
