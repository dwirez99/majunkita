import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:majunkita/features/manage_percas/data/repositories/perca_transactions_repository.dart';
import 'package:majunkita/features/manage_percas/domain/providers/perca_transactions_provider.dart';

import 'perca_transactions_provider_test.mocks.dart';

@GenerateMocks([PercaTransactionsRepository])

void main() {
  test('percaTransactionMonthlyStatsProvider returns repository stats',
      () async {
    final mockRepository = MockPercaTransactionsRepository();
    when(mockRepository.getMonthlyTransactionStats()).thenAnswer(
      (_) async => {'2026-05': 10.0},
    );

    final container = ProviderContainer(
      overrides: [
        percaTransactionsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    final result =
        await container.read(percaTransactionMonthlyStatsProvider.future);

    expect(result['2026-05'], 10.0);
  });

  test('percaWeightPerTailorProvider returns repository data', () async {
    final mockRepository = MockPercaTransactionsRepository();
    when(mockRepository.getTotalWeightPerTailor()).thenAnswer(
      (_) async => {'Budi': 12.5},
    );

    final container = ProviderContainer(
      overrides: [
        percaTransactionsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(percaWeightPerTailorProvider.future);

    expect(result['Budi'], 12.5);
  });

  test('percaTransactionsByTailorProvider fetches by tailor ID', () async {
    final mockRepository = MockPercaTransactionsRepository();
    when(mockRepository.getTransactionsByTailor('1')).thenAnswer(
      (_) async => [
        {'id': 'tx-1'},
      ],
    );

    final container = ProviderContainer(
      overrides: [
        percaTransactionsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(
      percaTransactionsByTailorProvider('1').future,
    );

    expect(result.first['id'], 'tx-1');
  });

  test('percaTransactionDetailProvider fetches detail by ID', () async {
    final mockRepository = MockPercaTransactionsRepository();
    when(mockRepository.getPercaTransactionById('tx-1')).thenAnswer(
      (_) async => {'id': 'tx-1', 'weight': 5},
    );

    final container = ProviderContainer(
      overrides: [
        percaTransactionsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(
      percaTransactionDetailProvider('tx-1').future,
    );

    expect(result['weight'], 5);
  });

  test('updatePercaTransaction delegates to repository', () async {
    final mockRepository = MockPercaTransactionsRepository();
    when(mockRepository.updatePercaTransaction(any, any))
        .thenAnswer((_) async => null);

    final container = ProviderContainer(
      overrides: [
        percaTransactionsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier =
        container.read(percaTransactionNotifierProvider.notifier);
    await notifier.updatePercaTransaction(
      transactionId: 'tx-1',
      updateData: {'weight': 10},
    );

    verify(mockRepository.updatePercaTransaction('tx-1', {'weight': 10}))
        .called(1);
  });

  test('deletePercaTransaction delegates to repository', () async {
    final mockRepository = MockPercaTransactionsRepository();
    when(mockRepository.deletePercaTransaction(any))
        .thenAnswer((_) async => null);

    final container = ProviderContainer(
      overrides: [
        percaTransactionsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier =
        container.read(percaTransactionNotifierProvider.notifier);
    await notifier.deletePercaTransaction('tx-1');

    verify(mockRepository.deletePercaTransaction('tx-1')).called(1);
  });
}