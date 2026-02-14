import 'package:flutter_test/flutter_test.dart';
import '../../../../lib/features/manage_factories/data/models/factory_model.dart';

/// Mock Provider class for testing business logic
/// Since the actual provider uses Riverpod notifiers, we'll test the core logic
class MockFactoryProvider {
  List<FactoryModel> _factories = [];
  List<FactoryModel> _filteredFactories = [];
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  bool get isLoading => _isLoading;
  List<FactoryModel> get factories => _factories;
  List<FactoryModel> get filteredFactories => _filteredFactories;
  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get errorMessage => _errorMessage;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterFactories();
  }

  void setCurrentPage(int page) => _currentPage = page;
  void setTotalPages(int pages) => _totalPages = pages;
  void setErrorMessage(String? message) => _errorMessage = message;
  void clearErrorMessage() => _errorMessage = null;
  void setLoading(bool loading) => _isLoading = loading;

  void setFactories(List<FactoryModel> factories) {
    _factories = factories;
    _filterFactories();
  }

  void addFactory(FactoryModel factory) {
    _factories.add(factory);
    _filterFactories();
  }

  void updateFactory(FactoryModel updatedFactory) {
    final index = _factories.indexWhere((f) => f.id == updatedFactory.id);
    if (index != -1) {
      _factories[index] = updatedFactory;
      _filterFactories();
    }
  }

  void removeFactory(String id) {
    _factories.removeWhere((f) => f.id == id);
    _filterFactories();
  }

  void reset() {
    _factories = [];
    _filteredFactories = [];
    _searchQuery = '';
    _currentPage = 1;
    _errorMessage = null;
    _isLoading = false;
  }

  void _filterFactories() {
    if (_searchQuery.isEmpty) {
      _filteredFactories = List.from(_factories);
    } else {
      _filteredFactories = _factories
          .where((factory) =>
              factory.factoryName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }
}

void main() {
  group('FactoryProvider Logic Tests', () {
    late MockFactoryProvider provider;

    setUp(() {
      provider = MockFactoryProvider();
    });

    test('initial state should be correct', () {
      expect(provider.isLoading, false);
      expect(provider.factories, isEmpty);
      expect(provider.filteredFactories, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.currentPage, 1);
      expect(provider.totalPages, 1);
      expect(provider.errorMessage, isNull);
    });

    test('setSearchQuery should update search query and filtered factories', () {
      // Arrange
      final factories = [
        FactoryModel(
          id: '1',
          factoryName: 'PT Maju Jaya',
          address: 'Address 1',
          noTelp: '021-12345678',
        ),
        FactoryModel(
          id: '2',
          factoryName: 'PT Sukses Makmur',
          address: 'Address 2',
          noTelp: '021-87654321',
        ),
      ];

      // Set factories first
      provider.setFactories(factories);

      // Act
      provider.setSearchQuery('Maju');

      // Assert
      expect(provider.searchQuery, 'Maju');
      expect(provider.filteredFactories.length, 1);
      expect(provider.filteredFactories.first.factoryName, 'PT Maju Jaya');
    });

    test('setSearchQuery with empty query should show all factories', () {
      // Arrange
      final factories = [
        FactoryModel(
          id: '1',
          factoryName: 'PT Maju Jaya',
          address: 'Address 1',
          noTelp: '021-12345678',
        ),
        FactoryModel(
          id: '2',
          factoryName: 'PT Sukses Makmur',
          address: 'Address 2',
          noTelp: '021-87654321',
        ),
      ];

      provider.setFactories(factories);

      // Act
      provider.setSearchQuery('');

      // Assert
      expect(provider.searchQuery, '');
      expect(provider.filteredFactories.length, 2);
    });

    test('setSearchQuery should be case insensitive', () {
      // Arrange
      final factories = [
        FactoryModel(
          id: '1',
          factoryName: 'PT Maju Jaya',
          address: 'Address 1',
          noTelp: '021-12345678',
        ),
      ];

      provider.setFactories(factories);

      // Act
      provider.setSearchQuery('maju');

      // Assert
      expect(provider.filteredFactories.length, 1);
      expect(provider.filteredFactories.first.factoryName, 'PT Maju Jaya');
    });

    test('setCurrentPage should update current page', () {
      // Act
      provider.setCurrentPage(3);

      // Assert
      expect(provider.currentPage, 3);
    });

    test('setTotalPages should update total pages', () {
      // Act
      provider.setTotalPages(5);

      // Assert
      expect(provider.totalPages, 5);
    });

    test('setErrorMessage should update error message', () {
      // Act
      provider.setErrorMessage('Test error');

      // Assert
      expect(provider.errorMessage, 'Test error');
    });

    test('clearErrorMessage should clear error message', () {
      // Arrange
      provider.setErrorMessage('Test error');

      // Act
      provider.clearErrorMessage();

      // Assert
      expect(provider.errorMessage, isNull);
    });

    test('setLoading should update loading state', () {
      // Act
      provider.setLoading(true);

      // Assert
      expect(provider.isLoading, true);

      // Act
      provider.setLoading(false);

      // Assert
      expect(provider.isLoading, false);
    });

    test('setFactories should update factories and filtered factories', () {
      // Arrange
      final factories = [
        FactoryModel(
          id: '1',
          factoryName: 'PT Maju Jaya',
          address: 'Address 1',
          noTelp: '021-12345678',
        ),
      ];

      // Act
      provider.setFactories(factories);

      // Assert
      expect(provider.factories, factories);
      expect(provider.filteredFactories, factories);
    });

    test('addFactory should add factory to list', () {
      // Arrange
      final factory = FactoryModel(
        id: '1',
        factoryName: 'PT Maju Jaya',
        address: 'Address 1',
        noTelp: '021-12345678',
      );

      // Act
      provider.addFactory(factory);

      // Assert
      expect(provider.factories.length, 1);
      expect(provider.factories.first, factory);
      expect(provider.filteredFactories.length, 1);
      expect(provider.filteredFactories.first, factory);
    });

    test('updateFactory should update existing factory', () {
      // Arrange
      final originalFactory = FactoryModel(
        id: '1',
        factoryName: 'PT Maju Jaya',
        address: 'Address 1',
        noTelp: '021-12345678',
      );

      final updatedFactory = FactoryModel(
        id: '1',
        factoryName: 'PT Maju Baru',
        address: 'Address 1 Updated',
        noTelp: '021-99999999',
      );

      provider.addFactory(originalFactory);

      // Act
      provider.updateFactory(updatedFactory);

      // Assert
      expect(provider.factories.length, 1);
      expect(provider.factories.first.factoryName, 'PT Maju Baru');
      expect(provider.factories.first.address, 'Address 1 Updated');
      expect(provider.factories.first.noTelp, '021-99999999');
    });

    test('updateFactory should not add factory if not found', () {
      // Arrange
      final factory = FactoryModel(
        id: '1',
        factoryName: 'PT Maju Jaya',
        address: 'Address 1',
        noTelp: '021-12345678',
      );

      // Act
      provider.updateFactory(factory);

      // Assert
      expect(provider.factories, isEmpty);
    });

    test('removeFactory should remove factory from list', () {
      // Arrange
      final factory = FactoryModel(
        id: '1',
        factoryName: 'PT Maju Jaya',
        address: 'Address 1',
        noTelp: '021-12345678',
      );

      provider.addFactory(factory);

      // Act
      provider.removeFactory('1');

      // Assert
      expect(provider.factories, isEmpty);
      expect(provider.filteredFactories, isEmpty);
    });

    test('removeFactory should not affect list if factory not found', () {
      // Arrange
      final factory = FactoryModel(
        id: '1',
        factoryName: 'PT Maju Jaya',
        address: 'Address 1',
        noTelp: '021-12345678',
      );

      provider.addFactory(factory);

      // Act
      provider.removeFactory('non-existent');

      // Assert
      expect(provider.factories.length, 1);
    });

    test('reset should clear all data', () {
      // Arrange
      final factory = FactoryModel(
        id: '1',
        factoryName: 'PT Maju Jaya',
        address: 'Address 1',
        noTelp: '021-12345678',
      );

      provider.addFactory(factory);
      provider.setSearchQuery('test');
      provider.setCurrentPage(2);
      provider.setErrorMessage('error');
      provider.setLoading(true);

      // Act
      provider.reset();

      // Assert
      expect(provider.factories, isEmpty);
      expect(provider.filteredFactories, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.currentPage, 1);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
    });
  });
}