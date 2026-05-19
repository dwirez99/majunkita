import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_tailors/domain/utils/prediction_model_utils.dart';

void main() {
  group('PredictionModelUtils', () {
    group('calculateReff', () {
      test('should calculate reff correctly with positive values', () {
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 100.0,
          totalPercaDiambil: 50.0,
        );

        expect(reff, 2.0);
      });

      test('should return 0.0 if totalPercaDiambil is 0', () {
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 100.0,
          totalPercaDiambil: 0.0,
        );

        expect(reff, 0.0);
      });

      test('should return 0.0 if totalPercaDiambil is negative', () {
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 100.0,
          totalPercaDiambil: -50.0,
        );

        expect(reff, 0.0);
      });

      test('should handle reff less than 1', () {
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 25.0,
          totalPercaDiambil: 50.0,
        );

        expect(reff, 0.5);
      });

      test('should handle reff greater than 1', () {
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 200.0,
          totalPercaDiambil: 50.0,
        );

        expect(reff, 4.0);
      });

      test('should handle zero totalMajunDisetor', () {
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 0.0,
          totalPercaDiambil: 50.0,
        );

        expect(reff, 0.0);
      });

      test('should handle decimal values', () {
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 75.5,
          totalPercaDiambil: 25.2,
        );

        expect(reff.toStringAsFixed(2), '3.00');
      });

      test('should handle very small numbers', () {
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 0.1,
          totalPercaDiambil: 0.2,
        );

        expect(reff, closeTo(0.5, 0.0001));
      });

      test('should handle very large numbers', () {
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 1000000.0,
          totalPercaDiambil: 100000.0,
        );

        expect(reff, 10.0);
      });

      test('should be consistent for same inputs', () {
        final reff1 = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 100.0,
          totalPercaDiambil: 50.0,
        );

        final reff2 = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 100.0,
          totalPercaDiambil: 50.0,
        );

        expect(reff1, reff2);
      });

      test('should handle negative totalMajunDisetor', () {
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: -100.0,
          totalPercaDiambil: 50.0,
        );

        expect(reff, -2.0);
      });
    });

    group('calculatePrediksiMajun', () {
      test('should calculate prediksi majun correctly', () {
        final prediksi = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 100.0,
          reff: 2.0,
        );

        expect(prediksi, 200.0);
      });

      test('should return 0.0 if sisaPerca is 0', () {
        final prediksi = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 0.0,
          reff: 2.0,
        );

        expect(prediksi, 0.0);
      });

      test('should return 0.0 if reff is 0', () {
        final prediksi = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 100.0,
          reff: 0.0,
        );

        expect(prediksi, 0.0);
      });

      test('should return 0.0 if both are 0', () {
        final prediksi = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 0.0,
          reff: 0.0,
        );

        expect(prediksi, 0.0);
      });

      test('should handle decimal values', () {
        final prediksi = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 50.5,
          reff: 1.5,
        );

        expect(prediksi, closeTo(75.75, 0.0001));
      });

      test('should handle reff less than 1', () {
        final prediksi = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 100.0,
          reff: 0.5,
        );

        expect(prediksi, 50.0);
      });

      test('should handle reff greater than 1', () {
        final prediksi = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 50.0,
          reff: 4.0,
        );

        expect(prediksi, 200.0);
      });

      test('should handle very large numbers', () {
        final prediksi = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 1000000.0,
          reff: 10.0,
        );

        expect(prediksi, 10000000.0);
      });

      test('should handle negative sisaPerca', () {
        final prediksi = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: -100.0,
          reff: 2.0,
        );

        expect(prediksi, -200.0);
      });

      test('should handle negative reff', () {
        final prediksi = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 100.0,
          reff: -2.0,
        );

        expect(prediksi, -200.0);
      });
    });

    group('calculateEfficiencyStats', () {
      test('should return correct stats for normal case', () {
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 100.0,
          totalPercaDiambil: 50.0,
          sisaPerca: 100.0,
        );

        expect(stats['reff'], 2.0);
        expect(stats['prediksi_majun'], 200.0);
      });

      test('should return reff 0 if totalPercaDiambil is 0', () {
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 100.0,
          totalPercaDiambil: 0.0,
          sisaPerca: 100.0,
        );

        expect(stats['reff'], 0.0);
        expect(stats['prediksi_majun'], 0.0);
      });

      test('should include both required keys', () {
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 100.0,
          totalPercaDiambil: 50.0,
          sisaPerca: 100.0,
        );

        expect(stats.containsKey('reff'), true);
        expect(stats.containsKey('prediksi_majun'), true);
        expect(stats.length, 2);
      });

      test('should handle case with no perca taken yet (new tailor)', () {
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 0.0,
          totalPercaDiambil: 0.0,
          sisaPerca: 0.0,
        );

        expect(stats['reff'], 0.0);
        expect(stats['prediksi_majun'], 0.0);
      });

      test('should handle case where tailor has perca but no transaction yet', () {
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 0.0,
          totalPercaDiambil: 50.0,
          sisaPerca: 100.0,
        );

        expect(stats['reff'], 0.0);
        expect(stats['prediksi_majun'], 0.0);
      });

      test('should calculate stats with decimal values', () {
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 75.5,
          totalPercaDiambil: 25.2,
          sisaPerca: 50.5,
        );

        expect(stats['reff'], greaterThan(0));
        expect(stats['prediksi_majun'], greaterThan(0));
      });

      test('should return correct structure for high efficiency tailor', () {
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 500.0,
          totalPercaDiambil: 100.0,
          sisaPerca: 50.0,
        );

        expect(stats['reff'], 5.0);
        expect(stats['prediksi_majun'], 250.0);
      });

      test('should return correct structure for low efficiency tailor', () {
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 50.0,
          totalPercaDiambil: 100.0,
          sisaPerca: 100.0,
        );

        expect(stats['reff'], 0.5);
        expect(stats['prediksi_majun'], 50.0);
      });

      test('should be deterministic (same input = same output)', () {
        final stats1 = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 100.0,
          totalPercaDiambil: 50.0,
          sisaPerca: 100.0,
        );

        final stats2 = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 100.0,
          totalPercaDiambil: 50.0,
          sisaPerca: 100.0,
        );

        expect(stats1['reff'], stats2['reff']);
        expect(stats1['prediksi_majun'], stats2['prediksi_majun']);
      });

      test('should handle large-scale production numbers', () {
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 50000.0,
          totalPercaDiambil: 10000.0,
          sisaPerca: 5000.0,
        );

        expect(stats['reff'], 5.0);
        expect(stats['prediksi_majun'], 25000.0);
      });
    });

    group('Class structure', () {
      test('calculateReff should be static', () {
        expect(PredictionModelUtils.calculateReff, isNotNull);
      });

      test('calculatePrediksiMajun should be static', () {
        expect(PredictionModelUtils.calculatePrediksiMajun, isNotNull);
      });

      test('calculateEfficiencyStats should be static', () {
        expect(PredictionModelUtils.calculateEfficiencyStats, isNotNull);
      });
    });

    group('Real-world scenarios', () {
      test('should calculate stats for experienced tailor with good track record', () {
        // Tailor has processed lots of perca and consistently converts it
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 1000.0, // 1000kg majun submitted
          totalPercaDiambil: 500.0,  // from 500kg perca
          sisaPerca: 100.0,           // currently has 100kg perca left
        );

        expect(stats['reff'], 2.0);
        expect(stats['prediksi_majun'], 200.0);
      });

      test('should calculate stats for new tailor with limited history', () {
        // New tailor, just starting
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 0.0,
          totalPercaDiambil: 0.0,
          sisaPerca: 50.0,
        );

        expect(stats['reff'], 0.0);
        expect(stats['prediksi_majun'], 0.0);
      });

      test('should calculate stats for tailor with mixed efficiency', () {
        // Tailor has processed perca with varying efficiency
        final stats = PredictionModelUtils.calculateEfficiencyStats(
          totalMajunDisetor: 750.0,  // submitted 750kg majun
          totalPercaDiambil: 1000.0, // but took 1000kg perca (75% efficiency)
          sisaPerca: 200.0,
        );

        expect(stats['reff'], 0.75);
        expect(stats['prediksi_majun'], 150.0);
      });

      test('should calculate predictions across batch operations', () {
        // Multiple transactions
        final reff = PredictionModelUtils.calculateReff(
          totalMajunDisetor: 300.0,
          totalPercaDiambil: 100.0,
        );

        final prediksi1 = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 50.0,
          reff: reff,
        );

        final prediksi2 = PredictionModelUtils.calculatePrediksiMajun(
          sisaPerca: 75.0,
          reff: reff,
        );

        expect(prediksi1, 150.0);
        expect(prediksi2, 225.0);
        expect(prediksi2 - prediksi1, 75.0);
      });
    });
  });
}
