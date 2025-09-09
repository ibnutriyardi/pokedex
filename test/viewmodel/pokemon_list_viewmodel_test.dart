import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pokedex/model/pokemon.dart';
import 'package:pokedex/model/pokemon_list.dart';
import 'package:pokedex/repository/pokemon_repository.dart';
import 'package:pokedex/viewmodel/pokemon_list_viewmodel.dart';

@GenerateMocks([PokemonRepository])
import 'pokemon_list_viewmodel_test.mocks.dart';

void main() {
  late PokemonListViewModel viewModel;
  late MockPokemonRepository mockRepository;

  final Uri dummyUri = Uri.parse('http://dummy.api/call');

  Pokemon createDummyPokemon({required int id, required String name, List<String>? types}) {
    return Pokemon(
        id: id, name: name, imageUrl: 'http://example.com/$name.png', types: types ?? ['unknown']);
  }

  PokemonList createDummyPokemonList({
    int count = 100,
    String? next,
    List<Pokemon>? results,
  }) {
    final defaultResults = [
      createDummyPokemon(id: 1, name: 'bulbasaur', types: ['grass', 'poison']),
      createDummyPokemon(id: 2, name: 'ivysaur', types: ['grass', 'poison']),
    ];
    return PokemonList(
      count: count,
      next: next,
      results: results ?? defaultResults,
    );
  }

  group('ViewModel Initialization (Constructor)', () {
    testWidgets('initial state is loading, then success, and hasMore is true if next is present', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final localMockRepository = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        final Completer<void> loadingCompleter = Completer<void>();

        final initialList = createDummyPokemonList(next: 'some_next_url', results: [
          createDummyPokemon(id: 1, name: 'pikachu')
        ]);

        when(localMockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return initialList;
        });

        final localViewModel = PokemonListViewModel(repository: localMockRepository);
        localViewModel.addListener(() {
          recordedLoadingStates.add(localViewModel.isLoading);
          if (recordedLoadingStates.length == 2 && !loadingCompleter.isCompleted) {
            loadingCompleter.complete();
          }
        });

        await tester.pump(); 
        try {
          await loadingCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) {
          debugPrint('Loading completer timed out. States: $recordedLoadingStates');
        }
        await tester.pumpAndSettle();

        expect(recordedLoadingStates, [true, false], reason: "Should have notified isLoading=true, then isLoading=false for success");
        expect(localViewModel.isLoading, false, reason: "isLoading should be false after fetch");
        expect(localViewModel.error, null, reason: "error should be null on successful fetch");
        expect(localViewModel.pokemons.length, 1, reason: "Should have one Pokemon after initial fetch");
        expect(localViewModel.pokemons.first.name, 'pikachu', reason: "Pokemon name mismatch");
        expect(localViewModel.hasMore, true, reason: "hasMore should be true as 'next' was provided in mock");
        
        expect(localViewModel.pokemonList, isNotNull, reason: "pokemonList getter should return a non-null object after successful fetch.");
        expect(localViewModel.pokemonList, equals(initialList), reason: "pokemonList getter should return the exact PokemonList object that was fetched.");
        expect(localViewModel.pokemonList?.results.first.name, 'pikachu', reason: "Name of first pokemon in list from pokemonList getter should match.");
        expect(localViewModel.pokemonList?.next, 'some_next_url', reason: "The 'next' URL from pokemonList getter should match the mock.");

        verify(localMockRepository.fetchPokemons(limit: 20, nextUrl: null)).called(1);
      });
    });

    testWidgets('initial state is loading, then error with NetworkException', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final localMockRepository = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        final Completer<void> loadingCompleter = Completer<void>();
        final testException = NetworkException("Network error", statusCode: 500, uri: dummyUri);

        when(localMockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          throw testException;
        });

        final localViewModel = PokemonListViewModel(repository: localMockRepository);
        localViewModel.addListener(() {
          recordedLoadingStates.add(localViewModel.isLoading);
          if (recordedLoadingStates.length == 2 && !loadingCompleter.isCompleted) {
            loadingCompleter.complete();
          }
        });

        await tester.pump(); 
        try {
          await loadingCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) {
          debugPrint('Loading completer timed out. States: $recordedLoadingStates');
        }
        await tester.pumpAndSettle();

        expect(recordedLoadingStates, [true, false],
            reason: "Should have notified isLoading=true, then isLoading=false for error");
        expect(localViewModel.isLoading, false,
            reason: "isLoading should be false after fetch completes with an error");
        expect(localViewModel.error, isNotNull);
        expect(localViewModel.error, testException.toString(), reason: "Error message should match NetworkException.toString()");
        expect(localViewModel.pokemons.isEmpty, true);
        expect(localViewModel.pokemonList, isNull, reason: "pokemonList getter should be null after a fetch error.");
        verify(localMockRepository.fetchPokemons(limit: 20, nextUrl: null)).called(1);
      });
    });

    testWidgets('constructor uses default PokemonRepository when none is provided', (WidgetTester tester) async {
      await tester.runAsync(() async {
        late PokemonListViewModel localViewModelUsingDefaultRepo;
        final Completer<void> loadingCompleter = Completer<void>();
        int listenerCallCount = 0;

        localViewModelUsingDefaultRepo = PokemonListViewModel(); 

        localViewModelUsingDefaultRepo.addListener(() {
          listenerCallCount++;
          if (!localViewModelUsingDefaultRepo.isLoading && listenerCallCount >= 2 && !loadingCompleter.isCompleted) {
            loadingCompleter.complete();
          }
        });
        
        try {
          await loadingCompleter.future.timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('Default repository constructor test loading completer timed out or errored. isLoading: ${localViewModelUsingDefaultRepo.isLoading}, Error: ${localViewModelUsingDefaultRepo.error}');
        }
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(localViewModelUsingDefaultRepo.isLoading, false, 
          reason: "isLoading should eventually be false after constructor's initial fetch attempt with default repository. Actual error: ${localViewModelUsingDefaultRepo.error}");
      });
    });
  });

  group('fetchInitialPokemons (explicit call / re-fetch)', () {
    setUp(() {});

    testWidgets('success', (WidgetTester tester) async {
      await tester.runAsync(() async {
        mockRepository = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        Completer<void> currentCompleter = Completer<void>();
        PokemonList? firstFetchedList;
        PokemonList? secondFetchedList;

        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          firstFetchedList = createDummyPokemonList(results: [], next: null);
          return firstFetchedList!;
        });

        viewModel = PokemonListViewModel(repository: mockRepository);
        viewModel.addListener(() {
          recordedLoadingStates.add(viewModel.isLoading);
          if (recordedLoadingStates.length == 2 && !currentCompleter.isCompleted) {
            currentCompleter.complete();
          }
        });

        await tester.pump(); 
        try {
          await currentCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) {
          debugPrint('Constructor load completer timeout. States: $recordedLoadingStates');
        }
        await tester.pumpAndSettle();
        expect(recordedLoadingStates, [true, false], reason: "Constructor load: isLoading true, then false");
        expect(viewModel.pokemonList, equals(firstFetchedList), reason: "pokemonList should be the first fetched list after constructor.");
        
        recordedLoadingStates.clear();
        currentCompleter = Completer<void>(); 

        secondFetchedList = createDummyPokemonList(next: 'next_page', results: [
          createDummyPokemon(id: 3, name: 'charmander')
        ]);

        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return secondFetchedList!;
        });

        await viewModel.fetchInitialPokemons(); 
        await tester.pump(); 
        try {
          await currentCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) {
           debugPrint('Explicit fetch completer timeout. States: $recordedLoadingStates');
        }
        await tester.pumpAndSettle();

        expect(recordedLoadingStates, [true, false], reason: "Explicit fetch: loading true, then false");
        expect(viewModel.isLoading, false);
        expect(viewModel.error, null);
        expect(viewModel.pokemons.length, 1);
        expect(viewModel.pokemons.first.name, 'charmander');
        expect(viewModel.hasMore, true);
        expect(viewModel.pokemonList, equals(secondFetchedList), reason: "pokemonList should be the second fetched list after explicit call.");
        verify(mockRepository.fetchPokemons(limit: 20, nextUrl: null)).called(2);
      });
    });

    testWidgets('failure with DataParsingException', (WidgetTester tester) async {
      await tester.runAsync(() async {
        mockRepository = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        Completer<void> currentCompleter = Completer<void>();
        final testException = DataParsingException("Failed to parse data");
        PokemonList? firstFetchedListOnErrorCase;

        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          firstFetchedListOnErrorCase = createDummyPokemonList(results: [], next: null);
          return firstFetchedListOnErrorCase!;
        });

        viewModel = PokemonListViewModel(repository: mockRepository);
        viewModel.addListener(() {
          recordedLoadingStates.add(viewModel.isLoading);
          if ((recordedLoadingStates.length == 2 || recordedLoadingStates.length == 4) && !currentCompleter.isCompleted) {
            currentCompleter.complete();
          }
        });

        await tester.pump(); 
        try {
          await currentCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) {
           debugPrint('Constructor load completer timeout. States: $recordedLoadingStates');
        }
        await tester.pumpAndSettle();
        expect(recordedLoadingStates.take(2).toList(), [true, false], reason: "Constructor load for failure test");
        expect(viewModel.pokemonList, equals(firstFetchedListOnErrorCase), reason: "pokemonList should be the initial list before explicit fetch failure.");

        recordedLoadingStates.clear(); 
        currentCompleter = Completer<void>();

        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          throw testException;
        });

        await viewModel.fetchInitialPokemons();
        await tester.pump();
        try {
          await currentCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) {
           debugPrint('Explicit fetch failure completer timeout. States: $recordedLoadingStates');
        }
        await tester.pumpAndSettle();

        expect(recordedLoadingStates, [true, false], reason: "Explicit fetch failure: loading true, then false");
        expect(viewModel.isLoading, false);
        expect(viewModel.error, testException.toString());
        expect(viewModel.pokemons.isEmpty, true); 
        expect(viewModel.pokemonList, equals(firstFetchedListOnErrorCase), reason: "pokemonList should still hold the list from the successful constructor fetch, even if explicit re-fetch fails.");
        verify(mockRepository.fetchPokemons(limit: 20, nextUrl: null)).called(2);
      });
    });
  });

  group('fetchMorePokemons', () {
    testWidgets('success and appends data, updates pokemonList', (WidgetTester tester) async {
      await tester.runAsync(() async {
        mockRepository = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        Completer<void> currentCompleter = Completer<void>();
        PokemonList? initialListForFetchMore;
        PokemonList? morePokemonDataForFetchMore;

        initialListForFetchMore = createDummyPokemonList(
            results: [createDummyPokemon(id: 1, name: 'pidgey')],
            next: 'http://initial.next.page/api?page=2');
        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return initialListForFetchMore!;
        });

        viewModel = PokemonListViewModel(repository: mockRepository);
        viewModel.addListener(() {
          recordedLoadingStates.add(viewModel.isLoading);
          if (recordedLoadingStates.length == 2 && !currentCompleter.isCompleted) {
            currentCompleter.complete();
          }
        });

        await tester.pump();
        try {
            await currentCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) { debugPrint('fetchMore success constructor load completer timeout. States: $recordedLoadingStates'); }
        await tester.pumpAndSettle();
        expect(recordedLoadingStates, [true, false], reason: "fetchMore success: Constructor load");
        expect(viewModel.pokemonList, equals(initialListForFetchMore), reason: "pokemonList after constructor load in fetchMore test");

        recordedLoadingStates.clear();
        currentCompleter = Completer<void>();

        morePokemonDataForFetchMore = createDummyPokemonList(
            results: [createDummyPokemon(id: 2, name: 'rattata')],
            next: 'http://another.next.page/api?page=3');
        final expectedNextUrl = 'http://initial.next.page/api?page=2';

        when(mockRepository.fetchPokemons(nextUrl: expectedNextUrl))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return morePokemonDataForFetchMore!;
        });

        await viewModel.fetchMorePokemons();
        await tester.pump();
        try {
            await currentCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) { debugPrint('fetchMore success actual fetch completer timeout. States: $recordedLoadingStates'); }
        await tester.pumpAndSettle();

        expect(recordedLoadingStates, [true, false], reason: "fetchMore success: actual fetchMore part");
        expect(viewModel.isLoading, false);
        expect(viewModel.error, null);
        expect(viewModel.pokemons.length, 2);
        expect(viewModel.pokemons[0].name, 'pidgey');
        expect(viewModel.pokemons[1].name, 'rattata');
        expect(viewModel.hasMore, true);
        expect(viewModel.pokemonList, equals(morePokemonDataForFetchMore), reason: "pokemonList should be updated after successful fetchMorePokemons.");
        verify(mockRepository.fetchPokemons(nextUrl: expectedNextUrl)).called(1);
      });
    });

    testWidgets('failure during fetch more, pokemonList remains unchanged', (WidgetTester tester) async {
      await tester.runAsync(() async {
        mockRepository = MockPokemonRepository();
        List<bool> recordedLoadingStates = [];
        Completer<void> currentCompleter = Completer<void>();
        final testException = PokemonNotFoundException("More Pokemon not found", uri: dummyUri);
        PokemonList? initialListBeforeErrorInFetchMore;

        initialListBeforeErrorInFetchMore = createDummyPokemonList(
            results: [createDummyPokemon(id: 1, name: 'pidgey')],
            next: 'http://initial.next.page/api?page=2');
        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return initialListBeforeErrorInFetchMore!;
        });

        viewModel = PokemonListViewModel(repository: mockRepository);
        viewModel.addListener(() {
          recordedLoadingStates.add(viewModel.isLoading);
          if (recordedLoadingStates.length == 2 && !currentCompleter.isCompleted) {
            currentCompleter.complete();
          }
        });
        
        await tester.pump();
        try {
            await currentCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) { debugPrint('fetchMore failure constructor load completer timeout. States: $recordedLoadingStates'); }
        await tester.pumpAndSettle();
        expect(recordedLoadingStates, [true, false], reason: "fetchMore failure: Constructor load");
        final pokemonListBeforeFailedFetchMore = viewModel.pokemonList;
        expect(pokemonListBeforeFailedFetchMore, equals(initialListBeforeErrorInFetchMore));

        recordedLoadingStates.clear();
        currentCompleter = Completer<void>();

        final expectedNextUrl = 'http://initial.next.page/api?page=2';
        when(mockRepository.fetchPokemons(nextUrl: expectedNextUrl))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          throw testException;
        });

        final pokemonsBeforeFetchMore = List<Pokemon>.from(viewModel.pokemons);
        await viewModel.fetchMorePokemons();
        await tester.pump();
        try {
            await currentCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) { debugPrint('fetchMore failure actual fetch completer timeout. States: $recordedLoadingStates'); }
        await tester.pumpAndSettle();

        expect(recordedLoadingStates, [true, false], reason: "fetchMore failure: actual fetchMore part");
        expect(viewModel.isLoading, false);
        expect(viewModel.error, testException.toString());
        expect(viewModel.pokemons.length, pokemonsBeforeFetchMore.length, reason: "Pokemon list should not change on fetchMore error");
        expect(viewModel.pokemons, equals(pokemonsBeforeFetchMore), reason: "Pokemon list content should be identical after fetchMore error");
        expect(viewModel.pokemonList, equals(pokemonListBeforeFailedFetchMore), reason: "pokemonList should NOT change if fetchMorePokemons fails.");
        verify(mockRepository.fetchPokemons(nextUrl: expectedNextUrl)).called(1);
      });
    });

    testWidgets('does not fetch if isLoading is true', (WidgetTester tester) async {
      await tester.runAsync(() async {
        mockRepository = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        Completer<void> constructorLoadCompleter = Completer<void>();

        final initialListFromConstructor = createDummyPokemonList(
            results: [createDummyPokemon(id: 1, name: 'pidgey')],
            next: 'http://initial.next.page/api?page=2');
        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return initialListFromConstructor;
        });

        viewModel = PokemonListViewModel(repository: mockRepository);
        
        Completer<void> currentCompleter = constructorLoadCompleter;
        viewModel.addListener(() {
          recordedLoadingStates.add(viewModel.isLoading);
          if (recordedLoadingStates.length % 2 == 0 && !currentCompleter.isCompleted) {
            currentCompleter.complete();
          }
        });
        
        await tester.pump(); 
        try {
            await constructorLoadCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) { debugPrint('isLoading guard constructor load completer timeout. States: $recordedLoadingStates'); }
        await tester.pumpAndSettle();
        expect(recordedLoadingStates.take(2).toList(), [true, false], reason: "isLoading guard: Constructor load");
        
        recordedLoadingStates.clear();
        currentCompleter = Completer<void>(); 

        final initialNextUrl = 'http://initial.next.page/api?page=2';
        when(mockRepository.fetchPokemons(nextUrl: initialNextUrl))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100)); 
          return createDummyPokemonList(results: [createDummyPokemon(id:99, name:'slowpoke')], next: null);
        });

        final firstFetchFuture = viewModel.fetchMorePokemons(); 
        final secondFetchFuture = viewModel.fetchMorePokemons(); 
        
        await tester.pump(); 
        try {
          await currentCompleter.future.timeout(const Duration(seconds: 2)); 
        } catch (e) {
          debugPrint('First fetchMore in isLoading guard test timed out. States: $recordedLoadingStates');
        }

        await Future.wait([firstFetchFuture, secondFetchFuture]);
        await tester.pumpAndSettle(); 

        expect(recordedLoadingStates, [true, false], reason: "Only the first call should proceed and notify [true, false]. Second call is guarded.");
        verify(mockRepository.fetchPokemons(nextUrl: initialNextUrl)).called(1);
      });
    });

    testWidgets('does not fetch if hasMore is false', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final localMockRepo = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        final Completer<void> loadingCompleter = Completer<void>();

        when(localMockRepo.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return createDummyPokemonList(results: [createDummyPokemon(id: 1, name: 'nomore')], next: null);
        });

        final localViewModel = PokemonListViewModel(repository: localMockRepo);
        localViewModel.addListener(() {
          recordedLoadingStates.add(localViewModel.isLoading);
          if (recordedLoadingStates.length == 2 && !loadingCompleter.isCompleted) {
            loadingCompleter.complete();
          }
        });

        await tester.pump();
        try {
            await loadingCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) { debugPrint('hasMore guard constructor load completer timeout. States: $recordedLoadingStates'); }
        await tester.pumpAndSettle();
        expect(recordedLoadingStates, [true, false], reason: "hasMore guard: Constructor load");
        
        recordedLoadingStates.clear();

        expect(localViewModel.hasMore, false, reason: "hasMore should be false for this test setup");
        expect(localViewModel.pokemonList, isNotNull, reason: "pokemonList should still be accessible even if hasMore is false");

        await localViewModel.fetchMorePokemons();
        await tester.pumpAndSettle(); 

        expect(recordedLoadingStates.isEmpty, true, reason: "No notifications as fetchMore should not run");
        verifyNever(localMockRepo.fetchPokemons(nextUrl: argThat(isNotNull, named: 'nextUrl')));
      });
    });
  });

  group('Utility Methods', () {
    testWidgets('formatPokemonId should format ID correctly', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final localMockRepo = MockPokemonRepository();
        final Completer<void> completer = Completer<void>();
        List<bool> loadingStates = [];
        when(localMockRepo.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return createDummyPokemonList(results: [], next: null);
        });
        final localViewModel = PokemonListViewModel(repository: localMockRepo);
        localViewModel.addListener(() { 
          loadingStates.add(localViewModel.isLoading);
          if(loadingStates.length == 2 && !completer.isCompleted) completer.complete();
        });
        
        await tester.pump();
        try { await completer.future.timeout(const Duration(seconds:1)); } catch(e){ debugPrint("Format ID test VM load timeout");}
        await tester.pumpAndSettle();

        expect(localViewModel.formatPokemonId(1), "#001");
        expect(localViewModel.formatPokemonId(12), "#012");
        expect(localViewModel.formatPokemonId(123), "#123");
        expect(localViewModel.formatPokemonId(1234), "#1234");
      });
    });

    testWidgets('pokemons getter returns the current list of pokemons', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final mockRepo1 = MockPokemonRepository();
        when(mockRepo1.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) => Future.value(createDummyPokemonList(results: [], next: null)));

        final viewModel1 = PokemonListViewModel(repository: mockRepo1);
        final Completer<void> loadCompleter1 = Completer();
        viewModel1.addListener(() {
          if (!viewModel1.isLoading && !loadCompleter1.isCompleted) {
            loadCompleter1.complete();
          }
        });

        await tester.pump(); 
        await tester.pumpAndSettle(); 

        try {
          await loadCompleter1.future.timeout(const Duration(seconds: 1), onTimeout: () {
             debugPrint("ViewModel1 loading completer timed out. isLoading: ${viewModel1.isLoading}, error: ${viewModel1.error}, pokemons: ${viewModel1.pokemons.length}");
          });
        } catch (e) {
          debugPrint("ViewModel1 loading completer threw: $e. isLoading: ${viewModel1.isLoading}, error: ${viewModel1.error}, pokemons: ${viewModel1.pokemons.length}");
        }
        await tester.pump();
        
        final List<Pokemon> retrievedPokemons1 = viewModel1.pokemons;
        expect(retrievedPokemons1, isA<List<Pokemon>>(), reason: "Getter (Scenario 1) should return a List<Pokemon>.");
        expect(retrievedPokemons1, isEmpty, reason: "Pokemons getter (Scenario 1) should return empty list. Error: ${viewModel1.error}, isLoading: ${viewModel1.isLoading}");
        verify(mockRepo1.fetchPokemons(limit: 20, nextUrl: null)).called(1);

        final mockRepo2 = MockPokemonRepository();
        final testPokemon = createDummyPokemon(id: 99, name: 'Gettermon');
        final expectedPokemonList = createDummyPokemonList(results: [testPokemon], next: 'next/url');

        when(mockRepo2.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) => Future.value(expectedPokemonList));

        final viewModel2 = PokemonListViewModel(repository: mockRepo2);
        final Completer<void> loadCompleter2 = Completer();
        viewModel2.addListener(() {
          if (!viewModel2.isLoading && !loadCompleter2.isCompleted) {
            loadCompleter2.complete();
          }
        });

        await tester.pump();
        await tester.pumpAndSettle();

        try {
          await loadCompleter2.future.timeout(const Duration(seconds: 1), onTimeout: () {
            debugPrint("ViewModel2 loading completer timed out. isLoading: ${viewModel2.isLoading}, error: ${viewModel2.error}, pokemons: ${viewModel2.pokemons.length}");
          });
        } catch (e) {
          debugPrint("ViewModel2 loading completer threw: $e. isLoading: ${viewModel2.isLoading}, error: ${viewModel2.error}, pokemons: ${viewModel2.pokemons.length}");
        }
        await tester.pump();
        
        final List<Pokemon> retrievedPokemons2 = viewModel2.pokemons;
        expect(retrievedPokemons2, isA<List<Pokemon>>(), reason: "Getter (Scenario 2) should return a List<Pokemon>.");
        expect(retrievedPokemons2.length, 1, reason: "Pokemons getter (Scenario 2) should return populated list. Actual error: ${viewModel2.error}, isLoading: ${viewModel2.isLoading}");
        if (retrievedPokemons2.isNotEmpty) {
          expect(retrievedPokemons2.first.name, 'Gettermon');
        } else {
          fail('viewModel2.pokemons was empty (Scenario 2). Error: ${viewModel2.error}, isLoading: ${viewModel2.isLoading}');
        }
        verify(mockRepo2.fetchPokemons(limit: 20, nextUrl: null)).called(1);
      });
    });

    testWidgets('pokemons getter directly accessed after minimal setup', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final mockRepo = MockPokemonRepository();
        when(mockRepo.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async => createDummyPokemonList(results: [], next: null));

        final tempViewModel = PokemonListViewModel(repository: mockRepo);
        
        await tester.pumpAndSettle(); 

        final List<Pokemon> retrievedPokemons = tempViewModel.pokemons;
        expect(retrievedPokemons, isA<List<Pokemon>>(), reason: "Getter should return a List<Pokemon>.");
        expect(retrievedPokemons, isEmpty, reason: "Getter should reflect the initially fetched empty list.");
        
        verify(mockRepo.fetchPokemons(limit: 20, nextUrl: null)).called(1);
      });
    });
  });

  group('Lifecycle Management', () {
    testWidgets('dispose method sets _isDisposed and prevents further notifications and actions', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final mockRepo = MockPokemonRepository();
        final initialDummyList = createDummyPokemonList(results: [createDummyPokemon(id:1, name:'disposable_pokemon')], next: 'next_url_for_dispose_test');
        
        when(mockRepo.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async => initialDummyList);
        
        final vm = PokemonListViewModel(repository: mockRepo);
        
        int totalNotifications = 0;
        final Completer<void> initialLoadCompleter = Completer();
        vm.addListener(() {
          totalNotifications++;
          // For initial load, we expect 2 notifications (isLoading true, then false)
          if (!vm.isLoading && totalNotifications >= 2 && !initialLoadCompleter.isCompleted) { 
            initialLoadCompleter.complete();
          }
        });

        await tester.pump(); // Start initial fetch
        try {
          await initialLoadCompleter.future.timeout(const Duration(seconds: 2), 
            onTimeout: () => debugPrint("Initial load for dispose test timed out. Notifications: $totalNotifications, isLoading: ${vm.isLoading}")
          );
        } catch(e) {
          debugPrint("Initial load for dispose test threw: $e. Notifications: $totalNotifications, isLoading: ${vm.isLoading}");
        }
        await tester.pumpAndSettle(); // Settle initial fetch

        expect(totalNotifications, greaterThanOrEqualTo(2), reason: "Listener should have been called at least twice for initial load.");
        expect(vm.hasMore, true, reason: "Setup: hasMore should be true before dispose.");

        final int notificationsBeforeDisposeAction = totalNotifications;

        vm.dispose(); // Call dispose

        // 1. Test _safeNotifyListeners guard during fetchInitialPokemons
        final anotherDummyList = createDummyPokemonList(results: [createDummyPokemon(id:2, name:'after_dispose_pokemon')], next: 'another_url');
        // Re-stub for the fetchInitialPokemons call after dispose
        when(mockRepo.fetchPokemons(limit: 20, nextUrl: null)) 
            .thenAnswer((_) async => anotherDummyList);
            
        await vm.fetchInitialPokemons(); 
        await tester.pumpAndSettle();
        
        expect(totalNotifications, notificationsBeforeDisposeAction, 
               reason: "_safeNotifyListeners should not have triggered further notifications for fetchInitialPokemons after dispose.");

        // 2. Test fetchMorePokemons guard
        final String? nextUrlForMore = initialDummyList.next; 
        expect(nextUrlForMore, isNotNull, reason: "Test setup check: nextUrlForMore should not be null for this part of the test.");

        if (nextUrlForMore != null) {
            when(mockRepo.fetchPokemons(nextUrl: nextUrlForMore)) 
                .thenAnswer((_) async => createDummyPokemonList(results: [createDummyPokemon(id:3, name:'more_after_dispose_pokemon')]));
                
            await vm.fetchMorePokemons(); 
            await tester.pumpAndSettle();

            verifyNever(mockRepo.fetchPokemons(nextUrl: nextUrlForMore));
            expect(totalNotifications, notificationsBeforeDisposeAction, 
               reason: "_safeNotifyListeners should not have triggered further notifications for fetchMorePokemons after dispose.");
        } else {
             fail("nextUrlForMore was null, preventing testing of fetchMorePokemons guard after dispose.");
        }
      });
    });
  });

  test('Simplest possible synchronous sanity check', () {
    expect(true, true, reason: "Barebones synchronous sanity check in a new test case");
  });
}
