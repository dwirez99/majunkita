import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:majunkita/features/manage_majun/data/repositories/majun_repository.dart';
import 'package:majunkita/features/manage_majun/domain/providers/majun_provider.dart';
import 'package:majunkita/features/manage_majun/data/model/majun_transactions_model.dart';
import 'package:majunkita/features/manage_tailors/data/models/tailor_model.dart';
import 'majun_provider_test.mocks.dart';

@GenerateMocks([MajunRepository, File])
void main() {
  late MockMajunRepository mockRepository;

  setUp(() {
    mockRepository = MockMajunRepository();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        majunRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('majunPricePerKgProvider', () {
    test('fetches majun price on init', () async {
      when(mockRepository.getMajunPricePerKg()).thenAnswer((_) async => 2500.0);
      
      final container = createContainer();
      final price = await container.read(majunPricePerKgProvider.future);
      
      expect(price, 2500.0);
      verify(mockRepository.getMajunPricePerKg()).called(1);
    });
  });

  group('updatePriceNotifierProvider', () {
    test('updatePrice success calls repo', () async {
      when(mockRepository.updateMajunPricePerKg(3000.0)).thenAnswer((_) async {});

      final container = createContainer();
      final notifier = container.read(updatePriceNotifierProvider.notifier);

      await notifier.updatePrice(3000.0);

      verify(mockRepository.updateMajunPricePerKg(3000.0)).called(1);
    });
  });
}
