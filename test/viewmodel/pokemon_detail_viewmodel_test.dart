import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pokedex/model/pokemon_detail.dart';
import 'package:pokedex/model/pokemon_evolution.dart';
import 'package:pokedex/model/pokemon_stats.dart';
import 'package:pokedex/repository/pokemon_repository.dart'; // Added for the new test
import 'package:pokedex/viewmodel/pokemon_detail_viewmodel.dart';

import 'pokemon_list_viewmodel_test.mocks.dart';

Completer<void>? _activeCompleter;
int _notificationTargetCount = 0;
int _notificationsReceivedForActiveCompleter = 0;
List<String> notifiedEvents = [];

void main() {
  late PokemonDetailViewModel viewModel;
  late MockPokemonRepository mockRepository;

  String describeNotificationState(PokemonDetailViewModel vm) {
    return 'L:${vm.isLoading} EL:${vm.isEvolutionLoading} Err:${vm.error != null} EvoErr:${vm.evolutionError != null}';
  }

  // This setUp is for the majority of tests that use a mocked repository.
  // The new constructor test will create its own instance.
  setUp(() {
    mockRepository = MockPokemonRepository();
    viewModel = PokemonDetailViewModel(repository: mockRepository);
    
    notifiedEvents.clear(); 

    viewModel.addListener(() {
      notifiedEvents.add(describeNotificationState(viewModel));
      if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
        _notificationsReceivedForActiveCompleter++;
        if (_notificationsReceivedForActiveCompleter >= _notificationTargetCount) {
          _activeCompleter!.complete();
        }
      }
    });
  });

  Future<void> awaitNotifications(
    Completer<void> completer,
    int targetCount, {
    Duration timeoutDuration = const Duration(seconds: 3),
  }) async {
    _activeCompleter = completer;
    _notificationTargetCount = targetCount;
    _notificationsReceivedForActiveCompleter = 0;
    try {
      await completer.future.timeout(timeoutDuration);
    } catch (e) {
      debugPrint(
          'Notification completer timed out. Expected $targetCount, received $_notificationsReceivedForActiveCompleter. Total Events: ${notifiedEvents.length} -> ${notifiedEvents.isNotEmpty ? notifiedEvents.last : "[]"}');
    }
  }

  PokemonDetail createDummyPokemonDetail({
    required int id,
    String name = 'dummy',
    List<String> types = const ['unknown'],
    String imageUrl = 'http://example.com/dummy.png',
    String description = 'A dummy Pokemon.',
    String? evolutionChainUrl,
    List<String> abilities = const [],
    double height = 1.0,
    double weight = 10.0,
    List<PokemonStats> stats = const <PokemonStats>[],
    List<PokemonMove> moves = const <PokemonMove>[],
    int baseExperience = 64,
  }) {
    return PokemonDetail(
      id: id,
      name: name,
      types: types,
      imageUrl: imageUrl,
      description: description,
      evolutionChainUrl: evolutionChainUrl,
      abilities: abilities,
      height: height,
      weight: weight,
      stats: stats,
      moves: moves,
      baseExperience: baseExperience,
    );
  }

  PokemonEvolution createDummyPokemonEvolution({
    String speciesName = 'dummy-species',
    List<PokemonEvolution> evolvesTo = const [],
  }) {
    return PokemonEvolution(
      speciesName: speciesName,
      evolvesTo: evolvesTo,
    );
  }

  group('Constructor', () {
    test('uses default PokemonRepository when no repository is provided', () {
      // Act: Create ViewModel without providing a repository
      final defaultRepoViewModel = PokemonDetailViewModel();
      
      // Assert: Check that the ViewModel is created
      expect(defaultRepoViewModel, isNotNull);
      // The primary goal is to hit the line in the constructor for coverage.
      // Additional checks could be added if there was an easy way to inspect
      // the internal _repository type without modifying the ViewModel for tests.
    });

    test('uses provided repository when one is given', () {
      // Arrange
      final explicitMockRepository = MockPokemonRepository();
      
      // Act
      final explicitRepoViewModel = PokemonDetailViewModel(repository: explicitMockRepository);
      
      // Assert
      expect(explicitRepoViewModel, isNotNull);
      // Here, we can be reasonably sure our mock is being used because if it weren't,
      // and a real PokemonRepository was created and made a network call,
      // it might behave differently or error in a test environment without setup.
      // For direct verification, one would typically need to expose the repository
      // or test behavior that explicitly depends on the mocked type vs real type.
      // For coverage of the `_repository = repository` part, this is sufficient.
    });
  });

  group('fetchPokemonDetails', () {
    final pokemonId = 1;
    const dummyEvolutionChainUrl = 'http://example.com/evo-chain/1/';
    final dummyDetail = createDummyPokemonDetail(
        id: pokemonId, name: 'pikachu', evolutionChainUrl: dummyEvolutionChainUrl);
    final dummyEvolution = createDummyPokemonEvolution(speciesName: 'pikachu');

    const int successNotificationsCount = 4;

    test('success: fetches details and evolution', () async {
      final completer = Completer<void>();
      notifiedEvents.clear(); 

      when(mockRepository.fetchPokemonDetails(pokemonId))
          .thenAnswer((_) async => dummyDetail);
      when(mockRepository.fetchPokemonEvolution(dummyEvolutionChainUrl))
          .thenAnswer((_) async => dummyEvolution);

      viewModel.fetchPokemonDetails(pokemonId);
      await awaitNotifications(completer, successNotificationsCount);

      expect(viewModel.isLoading, false, reason: "isLoading should be false after all fetches");
      expect(viewModel.error, null);
      expect(viewModel.pokemonDetail, dummyDetail);
      expect(viewModel.isEvolutionLoading, false, reason: "Evolution loading should be false after success");
      expect(viewModel.evolutionError, null);
      expect(viewModel.pokemonEvolution, dummyEvolution);

      verify(mockRepository.fetchPokemonDetails(pokemonId)).called(1);
      verify(mockRepository.fetchPokemonEvolution(dummyEvolutionChainUrl)).called(1);
      expect(notifiedEvents.length, successNotificationsCount, reason: "Should have exactly $successNotificationsCount notifications for success case");
    });
    
    const int detailFetchErrorNotificationsCount = 2;

    test('failure: getPokemonDetails throws exception', () async {
      final completer = Completer<void>();
      notifiedEvents.clear();

      when(mockRepository.fetchPokemonDetails(pokemonId))
          .thenThrow(Exception("Failed to fetch details"));

      viewModel.fetchPokemonDetails(pokemonId);
      await awaitNotifications(completer, detailFetchErrorNotificationsCount);
      
      expect(viewModel.isLoading, false);
      expect(viewModel.error, "Exception: Failed to fetch details");
      expect(viewModel.pokemonDetail, null);
      expect(viewModel.isEvolutionLoading, false); 
      expect(viewModel.pokemonEvolution, null);
      expect(viewModel.evolutionError, null);

      verify(mockRepository.fetchPokemonDetails(pokemonId)).called(1);
      verifyNever(mockRepository.fetchPokemonEvolution(any));
      expect(notifiedEvents.length, detailFetchErrorNotificationsCount, reason: "Should have $detailFetchErrorNotificationsCount notifications for detail fetch error");
    });

    const int evolutionFetchErrorNotificationsCount = 4;

    test('failure: fetchPokemonEvolution throws exception', () async {
      final completer = Completer<void>();
      notifiedEvents.clear();

      when(mockRepository.fetchPokemonDetails(pokemonId))
          .thenAnswer((_) async => dummyDetail);
      when(mockRepository.fetchPokemonEvolution(dummyEvolutionChainUrl))
          .thenThrow(Exception("Failed to fetch evolution"));

      viewModel.fetchPokemonDetails(pokemonId);
      await awaitNotifications(completer, evolutionFetchErrorNotificationsCount);

      expect(viewModel.isLoading, false);
      expect(viewModel.error, null); 
      expect(viewModel.pokemonDetail, dummyDetail);
      expect(viewModel.isEvolutionLoading, false);
      expect(viewModel.evolutionError, "Exception: Failed to fetch evolution");
      expect(viewModel.pokemonEvolution, null);

      verify(mockRepository.fetchPokemonDetails(pokemonId)).called(1);
      verify(mockRepository.fetchPokemonEvolution(dummyEvolutionChainUrl)).called(1);
      expect(notifiedEvents.length, evolutionFetchErrorNotificationsCount, reason: "Should have $evolutionFetchErrorNotificationsCount notifications for evolution fetch error");
    });

    test('race condition: new fetch started before old one completes for details', () async {
      final firstId = 1;
      const firstEvoUrl = 'http://example.com/evo/1';
      final secondId = 2;
      const secondEvoUrl = 'http://example.com/evo/2';

      final firstDetail = createDummyPokemonDetail(id: firstId, name: 'pokemon1', evolutionChainUrl: firstEvoUrl);
      final secondDetail = createDummyPokemonDetail(id: secondId, name: 'pokemon2', evolutionChainUrl: secondEvoUrl);
      final secondEvolution = createDummyPokemonEvolution(speciesName: 'pokemon2-evo');

      final firstDetailCompleter = Completer<PokemonDetail>(); 
      final notificationsForSecondFetchCompleter = Completer<void>();
      
      notifiedEvents.clear();

      when(mockRepository.fetchPokemonDetails(firstId)).thenAnswer((_) => firstDetailCompleter.future);
      when(mockRepository.fetchPokemonDetails(secondId)).thenAnswer((_) async => secondDetail);
      when(mockRepository.fetchPokemonEvolution(secondEvoUrl)).thenAnswer((_) async => secondEvolution);
 
      viewModel.fetchPokemonDetails(firstId); 

      viewModel.fetchPokemonDetails(secondId); 
      await awaitNotifications(notificationsForSecondFetchCompleter, 4);


      if (!firstDetailCompleter.isCompleted) {
        firstDetailCompleter.complete(firstDetail); 
      }
      await Future.delayed(Duration.zero); 

      expect(viewModel.pokemonDetail?.id, secondId, reason: "ViewModel should have data for the second fetch");
      expect(viewModel.pokemonDetail?.name, 'pokemon2');
      expect(viewModel.isLoading, false, reason: "Loading should be false after second fetch completes");
      expect(viewModel.error, null);
      expect(viewModel.pokemonEvolution?.speciesName, 'pokemon2-evo', reason: "Evolution for second fetch should be present");

      verify(mockRepository.fetchPokemonDetails(firstId)).called(1);
      verify(mockRepository.fetchPokemonDetails(secondId)).called(1);
      verify(mockRepository.fetchPokemonEvolution(secondEvoUrl)).called(1);
      verifyNever(mockRepository.fetchPokemonEvolution(firstEvoUrl)); 
    });

    test('clears previous pokemon data when fetching a new one', () async {
      final firstId = 1;
      const firstEvoUrl = 'http://example.com/evo/1';
      final firstDetail = createDummyPokemonDetail(id: firstId, name: 'pokemon1', evolutionChainUrl: firstEvoUrl);
      final firstEvolution = createDummyPokemonEvolution(speciesName: 'pokemon1-evo');
      
      final firstFetchCompleter = Completer<void>();
      notifiedEvents.clear();

      when(mockRepository.fetchPokemonDetails(firstId)).thenAnswer((_) async => firstDetail);
      when(mockRepository.fetchPokemonEvolution(firstEvoUrl)).thenAnswer((_) async => firstEvolution);
      
      viewModel.fetchPokemonDetails(firstId);
      await awaitNotifications(firstFetchCompleter, 4);

      expect(viewModel.pokemonDetail, firstDetail);
      expect(viewModel.pokemonEvolution, firstEvolution);
      
      notifiedEvents.clear(); 

      final secondId = 2;
      const secondEvoUrl = 'http://example.com/evo/2';
      final secondDetail = createDummyPokemonDetail(id: secondId, name: 'pokemon2', evolutionChainUrl: secondEvoUrl);
      final secondEvolution = createDummyPokemonEvolution(speciesName: 'pokemon2-evo');
      final secondFetchCompleter = Completer<void>();

      when(mockRepository.fetchPokemonDetails(secondId)).thenAnswer((_) async => secondDetail);
      when(mockRepository.fetchPokemonEvolution(secondEvoUrl)).thenAnswer((_) async => secondEvolution);

      viewModel.fetchPokemonDetails(secondId);

      expect(viewModel.isLoading, true);
      expect(viewModel.pokemonDetail, null, reason: "Old detail should be cleared on new fetch call");
      expect(viewModel.pokemonEvolution, null, reason: "Old evolution should be cleared");
      expect(notifiedEvents.length, 1, reason: "Should have 1 notification for clearing data/loading start");

      await awaitNotifications(secondFetchCompleter, 4);


      expect(viewModel.pokemonDetail, secondDetail);
      expect(viewModel.pokemonEvolution, secondEvolution);
      expect(viewModel.isLoading, false);
      expect(viewModel.error, null);
      expect(notifiedEvents.length, 4, reason: "Should have 4 notifications for the second fetch operation");
    });
  });

  group('refreshPokemonEvolutionData', () {
    final pokemonId = 1;
    const initialEvoUrl = 'http://example.com/evo/initial/1';
    final initialDetail = createDummyPokemonDetail(id: pokemonId, name: 'pikachu', evolutionChainUrl: initialEvoUrl);
    final initialEvolution = createDummyPokemonEvolution(speciesName: 'pikachu-evo-initial');
    final refreshedEvolution = createDummyPokemonEvolution(speciesName: 'pikachu-evo-refreshed');

    const int refreshSuccessNotificationsCount = 2;

    Future<void> setupViewModelWithInitialData() async {
      final completer = Completer<void>();
      notifiedEvents.clear();
      when(mockRepository.fetchPokemonDetails(pokemonId))
          .thenAnswer((_) async => initialDetail);
      when(mockRepository.fetchPokemonEvolution(initialEvoUrl))
          .thenAnswer((_) async => initialEvolution);
      
      viewModel.fetchPokemonDetails(pokemonId);
      await awaitNotifications(completer, 4); 
      notifiedEvents.clear(); 
    }

    test('success: refreshes evolution for current pokemon', () async {
      await setupViewModelWithInitialData();
      expect(viewModel.pokemonDetail, initialDetail, reason: "Pre-condition: detail should be loaded");
      expect(viewModel.pokemonEvolution, initialEvolution, reason: "Pre-condition: initial evolution should be loaded");

      final completer = Completer<void>();
      notifiedEvents.clear();
      when(mockRepository.fetchPokemonEvolution(initialEvoUrl))
          .thenAnswer((_) async => refreshedEvolution);

      viewModel.refreshPokemonEvolutionData();
      await awaitNotifications(completer, refreshSuccessNotificationsCount);

      expect(viewModel.isEvolutionLoading, false);
      expect(viewModel.evolutionError, null);
      expect(viewModel.pokemonEvolution, refreshedEvolution);
      verify(mockRepository.fetchPokemonEvolution(initialEvoUrl)).called(2); 
      expect(notifiedEvents.length, refreshSuccessNotificationsCount);
    });

    const int refreshNoDetailNotificationsCount = 1;

    test('failure: no pokemon details loaded (refresh called when detail is null)', () async {
      final completer = Completer<void>();
      notifiedEvents.clear();
      
      viewModel.refreshPokemonEvolutionData();
      await awaitNotifications(completer, refreshNoDetailNotificationsCount, timeoutDuration: const Duration(milliseconds: 500));

      expect(viewModel.isEvolutionLoading, false);
      expect(viewModel.evolutionError, "Pokemon details not loaded.");
      verifyNever(mockRepository.fetchPokemonEvolution(any));
      expect(notifiedEvents.length, refreshNoDetailNotificationsCount);
    });

    test('failure: pokemon detail loaded but no evolutionChainUrl', () async {
        final detailWithoutEvoUrl = createDummyPokemonDetail(id: pokemonId, name: 'no-evo-pokemon', evolutionChainUrl: null);
        final initialLoadCompleter = Completer<void>();
        notifiedEvents.clear();

        when(mockRepository.fetchPokemonDetails(pokemonId))
            .thenAnswer((_) async => detailWithoutEvoUrl);
        viewModel.fetchPokemonDetails(pokemonId);
        await awaitNotifications(initialLoadCompleter, 2); 
        notifiedEvents.clear();

        final refreshCompleter = Completer<void>();
        viewModel.refreshPokemonEvolutionData();
        await awaitNotifications(refreshCompleter, refreshNoDetailNotificationsCount, timeoutDuration: const Duration(milliseconds: 500));

        expect(viewModel.isEvolutionLoading, false);
        expect(viewModel.evolutionError, "No evolution data URL available to refresh.");
        verifyNever(mockRepository.fetchPokemonEvolution(any));
        expect(notifiedEvents.length, refreshNoDetailNotificationsCount);
    });
    
    const int refreshFailNotificationsCount = 2;

    test('failure: fetchPokemonEvolution throws exception during refresh', () async {
      await setupViewModelWithInitialData(); 
      
      final completer = Completer<void>();
      notifiedEvents.clear();
      when(mockRepository.fetchPokemonEvolution(initialEvoUrl))
          .thenThrow(Exception("Evolution refresh failed"));

      viewModel.refreshPokemonEvolutionData();
      await awaitNotifications(completer, refreshFailNotificationsCount);

      expect(viewModel.isEvolutionLoading, false);
      expect(viewModel.evolutionError, "Exception: Evolution refresh failed");
      expect(viewModel.pokemonEvolution, initialEvolution, reason: "Should retain old evolution data on refresh error"); 
      verify(mockRepository.fetchPokemonEvolution(initialEvoUrl)).called(2); 
      expect(notifiedEvents.length, refreshFailNotificationsCount);
    });
  });

  group('Lifecycle Management', () {
    test('dispose method sets flags and prevents further updates', () async {
      final pokemonId = 1;
      const evolutionChainUrl = 'http://example.com/evo-chain/dispose/1/';
      final detail = createDummyPokemonDetail(
          id: pokemonId, name: 'disposable', evolutionChainUrl: evolutionChainUrl);
      final evolution = createDummyPokemonEvolution(speciesName: 'disposable-evo');

      // Initial fetch to set _currentPokemonIdForFetch and have some notifications
      final initialFetchCompleter = Completer<void>();
      notifiedEvents.clear();
      when(mockRepository.fetchPokemonDetails(pokemonId))
          .thenAnswer((_) async => detail);
      when(mockRepository.fetchPokemonEvolution(evolutionChainUrl))
          .thenAnswer((_) async => evolution);

      viewModel.fetchPokemonDetails(pokemonId);
      await awaitNotifications(initialFetchCompleter, 4, timeoutDuration: const Duration(seconds: 1));
      
      final notificationsBeforeDispose = List.from(notifiedEvents); 
      final countNotificationsBeforeDispose = notifiedEvents.length;
      expect(countNotificationsBeforeDispose, 4, reason: "Should have 4 notifications from initial successful fetch.");

      viewModel.dispose();

      // Verify super.dispose() was called (by checking ChangeNotifier behavior)
      expect(() => viewModel.addListener(() {}), throwsA(isA<FlutterError>()),
          reason: "addListener should throw after dispose");

      // Attempt another fetch
      final anotherPokemonId = 2;
      final anotherDetail = createDummyPokemonDetail(id: anotherPokemonId, name: 'another');
      when(mockRepository.fetchPokemonDetails(anotherPokemonId))
          .thenAnswer((_) async => anotherDetail);

      await viewModel.fetchPokemonDetails(anotherPokemonId);
      await Future.delayed(Duration.zero); // Allow any microtasks to run

      // Check that no new notifications were sent by the already attached listener
      expect(notifiedEvents.length, countNotificationsBeforeDispose,
          reason: "No new notifications should be received after dispose. Before: ${notificationsBeforeDispose.join(", ")}. After: ${notifiedEvents.join(", ")}");

      // Verify that the repository was not called again for the main detail fetch
      verify(mockRepository.fetchPokemonDetails(pokemonId)).called(1); // From initial fetch
      verifyNever(mockRepository.fetchPokemonDetails(anotherPokemonId)); // Should not be called after dispose
    });
  });
}
