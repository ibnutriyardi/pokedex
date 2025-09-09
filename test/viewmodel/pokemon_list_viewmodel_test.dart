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

        await tester.pump(); 
        try {
          await currentCompleter.future.timeout(const Duration(seconds: 2));
        } catch (e) {
          debugPrint('Constructor load completer timeout. States: $recordedLoadingStates');
        }
        await tester.pumpAndSettle();
        expect(recordedLoadingStates, [true, false], reason: "Constructor load: isLoading true, then false");
        
        recordedLoadingStates.clear();
        currentCompleter = Completer<void>(); 

        final newList = createDummyPokemonList(next: 'next_page', results: [
          createDummyPokemon(id: 3, name: 'charmander')
        ]);

        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return newList;
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
        verify(mockRepository.fetchPokemons(limit: 20, nextUrl: null)).called(2);
      });
    });

    testWidgets('failure with DataParsingException', (WidgetTester tester) async {
      await tester.runAsync(() async {
        mockRepository = MockPokemonRepository();
        final List<bool> recordedLoadingStates = [];
        Completer<void> currentCompleter = Completer<void>();
        final testException = DataParsingException("Failed to parse data");

        when(mockRepository.fetchPokemons(limit: 20, nextUrl: null))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 1));
          return createDummyPokemonList(results: [], next: null);
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

    testWidgets('failure during fetch more with PokemonNotFoundException', (WidgetTester tester) async {
      await tester.runAsync(() async {
        mockRepository = MockPokemonRepository();
        List<bool> recordedLoadingStates = [];
        Completer<void> currentCompleter = Completer<void>();
        final testException = PokemonNotFoundException("More Pokemon not found", uri: dummyUri);

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
             // Complete after every pair of loading state changes (true, then false)
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
  });

  test('Simplest possible synchronous sanity check', () {
    expect(true, true, reason: "Barebones synchronous sanity check in a new test case");
  });
}
