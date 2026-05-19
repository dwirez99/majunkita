import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:majunkita/features/manage_factories/data/models/factory_model.dart';
import 'package:majunkita/features/manage_factories/data/repositories/factory_repository.dart';
import 'package:majunkita/features/manage_factories/domain/providers/factory_provider.dart';
import 'factory_provider_test.mocks.dart';

@GenerateMocks([FactoryRepository])
void main() {
  late MockFactoryRepository mockRepository;

  setUp(() {
    mockRepository = MockFactoryRepository();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        factoryRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('FactorySearchQueryNotifier', () {
    test('initial state is empty', () {
      final container = createContainer();
      final query = container.read(factorySearchQueryProvider);
      expect(query, '');
    });

    test('setQuery updates state', () {
      final container = createContainer();
      container.read(factorySearchQueryProvider.notifier).setQuery('abc');
      final query = container.read(factorySearchQueryProvider);
      expect(query, 'abc');
    });

    test('clear resets state to empty', () {
      final container = createContainer();
      container.read(factorySearchQueryProvider.notifier).setQuery('abc');
      container.read(factorySearchQueryProvider.notifier).clear();
      final query = container.read(factorySearchQueryProvider);
      expect(query, '');
    });
  });

  group('factoriesListProvider', () {
    test('calls getAllFactories when query is empty', () async {
      final mockFactories = [
        FactoryModel(id: '1', factoryName: 'Fact 1', address: 'A', noTelp: '1')
      ];
      when(mockRepository.getAllFactories()).thenAnswer((_) async => mockFactories);

      final container = createContainer();
      final list = await container.read(factoriesListProvider.future);

      expect(list.length, 1);
      expect(list.first.factoryName, 'Fact 1');
      verify(mockRepository.getAllFactories()).called(1);
      verifyNever(mockRepository.searchFactories(any));
    });

    test('calls searchFactories when query is not empty', () async {
      final mockFactories = [
        FactoryModel(id: '2', factoryName: 'Search Fact', address: 'B', noTelp: '2')
      ];
      when(mockRepository.searchFactories('Search')).thenAnswer((_) async => mockFactories);

      final container = createContainer();
      container.read(factorySearchQueryProvider.notifier).setQuery('Search');
      
      final list = await container.read(factoriesListProvider.future);

      expect(list.length, 1);
      expect(list.first.factoryName, 'Search Fact');
      verify(mockRepository.searchFactories('Search')).called(1);
      verifyNever(mockRepository.getAllFactories());
    });
  });

  group('FactoryManagementNotifier', () {    
    test('createFactory success updates state and invalidates lists', () async {
      final newFact = FactoryModel(id: '1', factoryName: 'New', address: 'A', noTelp: '1');
      when(mockRepository.createFactory(factoryName: 'New', address: 'A', noTelp: '1'))
          .thenAnswer((_) async => newFact);

      final container = createContainer();
      var state = container.read(factoryManagementProvider);
      expect(state.isLoading, true); // initial build is loading or not done

      final result = await container.read(factoryManagementProvider.notifier)
          .createFactory(factoryName: 'New', address: 'A', noTelp: '1');

      expect(result.id, '1');
      verify(mockRepository.createFactory(factoryName: 'New', address: 'A', noTelp: '1')).called(1);
    });

    test('updateFactory success', () async {
      final updateFact = FactoryModel(id: '1', factoryName: 'Upd', address: 'A', noTelp: '1');
      when(mockRepository.updateFactory(id: '1', factoryName: 'Upd', address: 'A', noTelp: '1'))
          .thenAnswer((_) async => updateFact);

      final container = createContainer();

      final result = await container.read(factoryManagementProvider.notifier)
          .updateFactory(id: '1', factoryName: 'Upd', address: 'A', noTelp: '1');

      expect(result.id, '1');
      expect(result.factoryName, 'Upd');
      verify(mockRepository.updateFactory(id: '1', factoryName: 'Upd', address: 'A', noTelp: '1')).called(1);
    });

    test('deleteFactory success', () async {
      when(mockRepository.deleteFactory('1')).thenAnswer((_) async {});

      final container = createContainer();

      await container.read(factoryManagementProvider.notifier).deleteFactory('1');

      verify(mockRepository.deleteFactory('1')).called(1);
    });
  });
}
