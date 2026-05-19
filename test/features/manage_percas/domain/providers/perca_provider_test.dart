import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:majunkita/features/manage_percas/data/models/perca_stock_model.dart';
import 'package:majunkita/features/manage_percas/data/repositories/perca_repository.dart';
import 'package:majunkita/features/manage_percas/domain/providers/perca_provider.dart';

import 'perca_provider_test.mocks.dart';

@GenerateMocks([PercaRepository])

void main() {
  test('percaMonthlyStatsProvider aggregates totals by month and type',
      () async {
    final history = [
      {
        'date_entry': '2026-05-01',
        'perca_type': 'kain',
        'weight': 10,
      },
      {
        'date_entry': '2026-05-02',
        'perca_type': 'kaos',
        'weight': 5,
      },
      {
        'date_entry': '2026-06-01',
        'perca_type': 'kain',
        'weight': 3,
      },
    ];

    final container = ProviderContainer(
      overrides: [
        percaHistoryProvider.overrideWith((ref) => Future.value(history)),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(percaMonthlyStatsProvider.future);

    expect(result['2026-05']?['total'], 15);
    expect(result['2026-05']?['kain'], 10);
    expect(result['2026-05']?['kaos'], 5);
    expect(result['2026-06']?['total'], 3);
  });

  test('addSinglePercasStock uploads image and saves stock', () async {
    final mockRepository = MockPercaRepository();
    final container = ProviderContainer(
      overrides: [
        percaRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    when(mockRepository.uploadImageToStorage(any)).thenAnswer(
      (_) async => 'https://example.com/image.jpg',
    );
  when(mockRepository.saveStockToDatabase(any))
    .thenAnswer((_) async => null);

    final notifier = container.read(addPercaNotifierProvider.notifier);
    final stock = PercasStock(
      idFactory: '1',
      dateEntry: DateTime(2026, 5, 19),
      percaType: 'kaos',
      weight: 10.5,
      deliveryProof: '',
      sackCode: '',
    );

    await notifier.addSinglePercasStock(stock, File('dummy.jpg'));

    final captured =
        verify(mockRepository.saveStockToDatabase(captureAny)).captured;
    final savedStock = captured.first as PercasStock;
    expect(savedStock.deliveryProof, 'https://example.com/image.jpg');
    expect(savedStock.sackCode, 'K-10.50');
  });

  test('addMultiplePercaStocks uploads once and saves bulk data', () async {
    final mockRepository = MockPercaRepository();
    final container = ProviderContainer(
      overrides: [
        percaRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    when(mockRepository.uploadImageToStorage(any)).thenAnswer(
      (_) async => 'https://example.com/image.jpg',
    );
  when(mockRepository.saveMultipleStocksToDatabase(any))
    .thenAnswer((_) async => null);

    final notifier = container.read(addPercaNotifierProvider.notifier);

    await notifier.addMultiplePercaStocks(
      [
        {
          'idFactory': '1',
          'dateEntry': DateTime(2026, 5, 19),
          'jenis': 'kaos',
          'weight': 5.0,
        },
        {
          'idFactory': '1',
          'dateEntry': DateTime(2026, 5, 19),
          'jenis': 'kain',
          'weight': 3.25,
        },
      ],
      File('dummy.jpg'),
    );

    final captured =
        verify(mockRepository.saveMultipleStocksToDatabase(captureAny))
            .captured;
    final savedStocks = captured.first as List<PercasStock>;
    expect(savedStocks.length, 2);
    expect(savedStocks.first.sackCode, 'K-5');
    expect(savedStocks.last.sackCode, 'B-3.25');
  });
}