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

        await tester.pump(); // Start microtask
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
        verify(localMockRepository.fetchPokemons(limit: 20, nextUrl: null)).called(1);
      });
    });

    testWidgets('initial state is loading, then error', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final localMockRepository = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        final Completer<void> loadingCompleter = Completer<void>();

        when(localMockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          throw Exception("Network error");
        });

        final localViewModel = PokemonListViewModel(repository: localMockRepository);
        localViewModel.addListener(() {
          recordedLoadingStates.add(localViewModel.isLoading);
          if (recordedLoadingStates.length == 2 && !loadingCompleter.isCompleted) {
            loadingCompleter.complete();
          }
        });

        await tester.pump(); // Start microtask
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
        expect(localViewModel.error, "Exception: Network error");
        expect(localViewModel.pokemons.isEmpty, true);
        verify(localMockRepository.fetchPokemons(limit: 20, nextUrl: null)).called(1);
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

        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return createDummyPokemonList(results: [], next: null);
        });

        viewModel = PokemonListViewModel(repository: mockRepository);
        viewModel.addListener(() {
          recordedLoadingStates.add(viewModel.isLoading);
          if (recordedLoadingStates.length == 2 && !currentCompleter.isCompleted) {
            currentCompleter.complete();
          }
        });

        await tester.pump(); // Constructor microtask
        try {
          await currentCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) {
          debugPrint('Constructor load completer timeout. States: $recordedLoadingStates');
        }
        await tester.pumpAndSettle();
        expect(recordedLoadingStates, [true, false], reason: "Constructor load: isLoading true, then false");
        
        recordedLoadingStates.clear();
        currentCompleter = Completer<void>(); // Reset for explicit fetch

        final newList = createDummyPokemonList(next: 'next_page', results: [
          createDummyPokemon(id: 3, name: 'charmander')
        ]);

        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return newList;
        });

        await viewModel.fetchInitialPokemons(); // Explicit call
        await tester.pump(); // Start explicit fetch
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
        verify(mockRepository.fetchPokemons(limit: 20, nextUrl: null)).called(2);
      });
    });

    testWidgets('failure', (WidgetTester tester) async {
      await tester.runAsync(() async {
        mockRepository = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        Completer<void> currentCompleter = Completer<void>();

        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return createDummyPokemonList(results: [], next: null);
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
        expect(recordedLoadingStates, [true, false], reason: "Constructor load for failure test");
        
        recordedLoadingStates.clear();
        currentCompleter = Completer<void>();

        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          throw Exception("Fetch failed");
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
        expect(viewModel.error, "Exception: Fetch failed");
        expect(viewModel.pokemons.isEmpty, true);
        verify(mockRepository.fetchPokemons(limit: 20, nextUrl: null)).called(2);
      });
    });
  });

  group('fetchMorePokemons', () {
    testWidgets('success and appends data', (WidgetTester tester) async {
      await tester.runAsync(() async {
        mockRepository = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        Completer<void> currentCompleter = Completer<void>();

        final initialListFromConstructor = createDummyPokemonList(
            results: [createDummyPokemon(id: 1, name: 'pidgey')],
            next: 'http://initial.next.page/api?page=2');
        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return initialListFromConstructor;
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
        
        recordedLoadingStates.clear();
        currentCompleter = Completer<void>();

        final morePokemonData = createDummyPokemonList(
            results: [createDummyPokemon(id: 2, name: 'rattata')],
            next: 'http://another.next.page/api?page=3');
        final expectedNextUrl = 'http://initial.next.page/api?page=2';

        when(mockRepository.fetchPokemons(nextUrl: expectedNextUrl))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return morePokemonData;
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
        verify(mockRepository.fetchPokemons(nextUrl: expectedNextUrl)).called(1);
      });
    });

    testWidgets('failure during fetch more', (WidgetTester tester) async {
      await tester.runAsync(() async {
        mockRepository = MockPokemonRepository();
        List<bool> recordedLoadingStates = [];
        Completer<void> currentCompleter = Completer<void>();

        final initialListFromConstructor = createDummyPokemonList(
            results: [createDummyPokemon(id: 1, name: 'pidgey')],
            next: 'http://initial.next.page/api?page=2');
        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return initialListFromConstructor;
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
        
        recordedLoadingStates.clear();
        currentCompleter = Completer<void>();

        final expectedNextUrl = 'http://initial.next.page/api?page=2';
        when(mockRepository.fetchPokemons(nextUrl: expectedNextUrl))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          throw Exception("Failed to fetch more");
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
        expect(viewModel.error, "Exception: Failed to fetch more");
        expect(viewModel.pokemons.length, pokemonsBeforeFetchMore.length);
        expect(viewModel.pokemons, equals(pokemonsBeforeFetchMore));
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
        
        // Listener for all operations, completer changes based on context
        Completer<void> currentCompleter = constructorLoadCompleter; // Initially for constructor
        viewModel.addListener(() {
          recordedLoadingStates.add(viewModel.isLoading);
          if (recordedLoadingStates.length == 2 && !currentCompleter.isCompleted) {
            currentCompleter.complete();
          }
        });
        
        await tester.pump(); // Constructor microtask
        try {
            await constructorLoadCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) { debugPrint('isLoading guard constructor load completer timeout. States: $recordedLoadingStates'); }
        await tester.pumpAndSettle();
        expect(recordedLoadingStates, [true, false], reason: "isLoading guard: Constructor load");
        
        recordedLoadingStates.clear();
        currentCompleter = Completer<void>(); // New completer for the first fetchMore attempt

        final initialNextUrl = 'http://initial.next.page/api?page=2';
        when(mockRepository.fetchPokemons(nextUrl: initialNextUrl))
            .thenAnswer((_) async {
          // Make this take a bit longer so the second call definitely happens while first is loading
          await Future.delayed(const Duration(milliseconds: 100)); 
          return createDummyPokemonList(results: [createDummyPokemon(id:99, name:'slowpoke')], next: null);
        });

        final firstFetchFuture = viewModel.fetchMorePokemons(); // This should proceed
        // Immediately try to call it again - this one should be guarded
        final secondFetchFuture = viewModel.fetchMorePokemons(); 
        
        await tester.pump(); // Start the first fetchMore
        try {
          await currentCompleter.future.timeout(const Duration(seconds: 2)); 
        } catch (e) {
          debugPrint('First fetchMore in isLoading guard test timed out. States: $recordedLoadingStates');
        }
        // Don't pumpAndSettle until both futures are awaited, 
        // to ensure the guard in fetchMorePokemons has a chance to be tested correctly.

        await Future.wait([firstFetchFuture, secondFetchFuture]);
        await tester.pumpAndSettle(); // Settle everything after both calls are processed

        expect(recordedLoadingStates, [true, false], reason: "Only the first call should proceed and notify [true, false].");
        verify(mockRepository.fetchPokemons(nextUrl: initialNextUrl)).called(1); // Only one actual fetch
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

        await localViewModel.fetchMorePokemons();
        await tester.pumpAndSettle(); // pumpAndSettle to ensure no stray timers/microtasks

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

    testWidgets('getPokemonTypeColor returns correct color', (WidgetTester tester) async {
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
        try { await completer.future.timeout(const Duration(seconds:1)); } catch(e){ debugPrint("Get color test VM load timeout"); }
        await tester.pumpAndSettle();

        expect(localViewModel.getPokemonTypeColor('grass'), const Color(0xFF78C850));
        expect(localViewModel.getPokemonTypeColor('fire'), const Color(0xFFF08030));
        expect(localViewModel.getPokemonTypeColor('water'), const Color(0xFF6890F0));
        expect(localViewModel.getPokemonTypeColor('electric'), const Color(0xFFF8D030));
        expect(localViewModel.getPokemonTypeColor('psychic'), const Color(0xFFF85888));
        expect(localViewModel.getPokemonTypeColor('ice'), const Color(0xFF98D8D8));
        expect(localViewModel.getPokemonTypeColor('dragon'), const Color(0xFF7038F8));
        expect(localViewModel.getPokemonTypeColor('dark'), const Color(0xFF705848));
        expect(localViewModel.getPokemonTypeColor('fairy'), const Color(0xFFEE99AC));
        expect(localViewModel.getPokemonTypeColor('normal'), const Color(0xFFA8A878));
        expect(localViewModel.getPokemonTypeColor('fighting'), const Color(0xFFC03028));
        expect(localViewModel.getPokemonTypeColor('flying'), const Color(0xFFA890F0));
        expect(localViewModel.getPokemonTypeColor('poison'), const Color(0xFFA040A0));
        expect(localViewModel.getPokemonTypeColor('ground'), const Color(0xFFE0C068));
        expect(localViewModel.getPokemonTypeColor('rock'), const Color(0xFFB8A038));
        expect(localViewModel.getPokemonTypeColor('bug'), const Color(0xFFA8B820));
        expect(localViewModel.getPokemonTypeColor('ghost'), const Color(0xFF705898));
        expect(localViewModel.getPokemonTypeColor('steel'), const Color(0xFFB8B8D0));
        expect(localViewModel.getPokemonTypeColor('GRASS'), const Color(0xFF78C850));
        expect(localViewModel.getPokemonTypeColor('UnknownType'), Colors.grey.shade400);
        expect(localViewModel.getPokemonTypeColor(null), Colors.grey.shade400);
        expect(localViewModel.getPokemonTypeColor(''), Colors.grey.shade400);
      });
    });
  });

  test('Simplest possible synchronous sanity check', () {
    expect(true, true, reason: "Barebones synchronous sanity check in a new test case");
  });
}
