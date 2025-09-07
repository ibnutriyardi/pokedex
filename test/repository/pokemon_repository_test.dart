import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pokedex/model/pokemon.dart';
import 'package:pokedex/repository/pokemon_repository.dart';

@GenerateMocks([http.Client])
import 'pokemon_repository_test.mocks.dart';

void main() {
  late PokemonRepository repository;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    repository = PokemonRepository(httpClient: mockClient); 
  });

  const String pokeapiBaseUrlForTests = "https://pokeapi.co/api/v2/";
  final utf8JsonHeaders = {'content-type': 'application/json; charset=utf-8'};

  group('fetchPokemons', () {
    final tLimit = 10;
    final tPokemonListUrl = Uri.parse('${pokeapiBaseUrlForTests}pokemon?limit=$tLimit');
    final tPokemonDetailUrl1 = Uri.parse('${pokeapiBaseUrlForTests}pokemon/1/');
    final tPokemonDetailUrl2 = Uri.parse('${pokeapiBaseUrlForTests}pokemon/2/');

    final tPokemonJson1 = {
      'id': 1, 'name': 'bulbasaur', 
      'sprites': {'other': {'official-artwork': {'front_default': 'url1'}}},
      'types': [{'type': {'name': 'grass'}}],
      'height': 7, 'weight': 69, 'abilities': [], 'stats': [], 'moves': [], 'base_experience': 64
    };
    final tPokemonJson2 = {
      'id': 2, 'name': 'ivysaur',
      'sprites': {'other': {'official-artwork': {'front_default': 'url2'}}},
      'types': [{'type': {'name': 'poison'}}],
      'height': 10, 'weight': 130, 'abilities': [], 'stats': [], 'moves': [], 'base_experience': 142
    };

    final tPokemon1 = Pokemon.fromJson(tPokemonJson1);
    final tPokemon2 = Pokemon.fromJson(tPokemonJson2);

    test('returns a PokemonList when the call completes successfully', () async {
      when(mockClient.get(tPokemonListUrl)).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'count': 2,
            'next': null,
            'results': [
              {'name': 'bulbasaur', 'url': tPokemonDetailUrl1.toString()},
              {'name': 'ivysaur', 'url': tPokemonDetailUrl2.toString()},
            ],
          }),
          200,
          headers: utf8JsonHeaders,
        ),
      );
      when(mockClient.get(tPokemonDetailUrl1)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonJson1), 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tPokemonDetailUrl2)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonJson2), 200, headers: utf8JsonHeaders),
      );

      final result = await repository.fetchPokemons(limit: tLimit);

      expect(result.count, 2);
      expect(result.next, null);
      expect(result.results.length, 2);
      expect(result.results.map((p) => p.id).toList(), containsAll([tPokemon1.id, tPokemon2.id]));
      verify(mockClient.get(tPokemonListUrl)).called(1);
      verify(mockClient.get(tPokemonDetailUrl1)).called(1);
      verify(mockClient.get(tPokemonDetailUrl2)).called(1);
    });

    test('returns a PokemonList using nextUrl when provided', () async {
      final tNextUrl = Uri.parse('${pokeapiBaseUrlForTests}pokemon?offset=10&limit=$tLimit');
       when(mockClient.get(tNextUrl)).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'count': 2,
            'next': null,
            'results': [
              {'name': 'bulbasaur', 'url': tPokemonDetailUrl1.toString()},
            ],
          }),
          200,
          headers: utf8JsonHeaders,
        ),
      );
      when(mockClient.get(tPokemonDetailUrl1)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonJson1), 200, headers: utf8JsonHeaders),
      );

      final result = await repository.fetchPokemons(limit: tLimit, nextUrl: tNextUrl.toString());

      expect(result.results.length, 1);
      expect(result.results.first.id, tPokemon1.id); 
      verify(mockClient.get(tNextUrl)).called(1);
      verify(mockClient.get(tPokemonDetailUrl1)).called(1);
    });

    test('throws an exception if the initial HTTP call completes with an error', () async {
      when(mockClient.get(tPokemonListUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );
      final call = repository.fetchPokemons;
      expect(() => call(limit: tLimit), throwsA(isA<Exception>()));
    });

     test('returns list with successfully fetched details even if some details fail', () async {
      when(mockClient.get(tPokemonListUrl)).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'count': 2,
            'next': null,
            'results': [
              {'name': 'bulbasaur', 'url': tPokemonDetailUrl1.toString()},
              {'name': 'ivysaur', 'url': tPokemonDetailUrl2.toString()},
            ],
          }),
          200,
          headers: utf8JsonHeaders,
        ),
      );
      when(mockClient.get(tPokemonDetailUrl1)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonJson1), 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tPokemonDetailUrl2)).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );

      final result = await repository.fetchPokemons(limit: tLimit);

      expect(result.results.length, 1);
      expect(result.results.first.id, tPokemon1.id);
      verify(mockClient.get(tPokemonListUrl)).called(1);
      verify(mockClient.get(tPokemonDetailUrl1)).called(1);
      verify(mockClient.get(tPokemonDetailUrl2)).called(1);
    });
  });

  group('fetchPokemonDetails', () {
    final tPokemonId = 1;
    final tPokemonUrl = Uri.parse('${pokeapiBaseUrlForTests}pokemon/$tPokemonId');
    final tSpeciesUrl = Uri.parse('${pokeapiBaseUrlForTests}pokemon-species/$tPokemonId');
    const tMockEvolutionChainUrl = '${pokeapiBaseUrlForTests}evolution-chain/1/';
    
    final tPokemonDataJson = {
      'id': tPokemonId, 'name': 'pikachu', 'height': 4, 'weight': 60,
      'base_experience': 112,
      'sprites': {'other': {'official-artwork': {'front_default': 'url_pikachu.png'}}},
      'types': [{'type': {'name': 'electric'}}],
      'abilities': [{'ability': {'name': 'static'}}],
      'stats': [{'stat': {'name': 'hp'}, 'base_stat': 35, 'effort': 0}],
      'moves': [{'move': {'name': 'thunder-shock'}}]
    };
    final tSpeciesJson = {
      'flavor_text_entries': [
        {'flavor_text': 'Pikachu that can generate powerful electricity have cheek sacs that are extra soft.', 'language': {'name': 'en'}},
        {'flavor_text': 'ピカチュウは電気を操る。', 'language': {'name': 'ja'}},
      ],
      'evolution_chain': {'url': tMockEvolutionChainUrl}
    };

    test('returns a PokemonDetail when calls complete successfully', () async {
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonDataJson), 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tSpeciesJson), 200, headers: utf8JsonHeaders),
      );

      final result = await repository.fetchPokemonDetails(tPokemonId);

      expect(result.id, tPokemonId);
      expect(result.name, 'pikachu');
      expect(result.description, 'Pikachu that can generate powerful electricity have cheek sacs that are extra soft.');
      expect(result.evolutionChainUrl, tMockEvolutionChainUrl);
      verify(mockClient.get(tPokemonUrl)).called(1);
      verify(mockClient.get(tSpeciesUrl)).called(1);
    });

    test('throws an exception if the Pokemon HTTP call fails', () async {
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );
      final call = repository.fetchPokemonDetails;
      expect(() => call(tPokemonId), throwsA(isA<Exception>()));
      verifyNever(mockClient.get(tSpeciesUrl));
    });

    test('returns PokemonDetail with default description and null evolutionUrl if Species HTTP call fails', () async {
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonDataJson), 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );
      
      final result = await repository.fetchPokemonDetails(tPokemonId);

      expect(result.id, tPokemonId);
      expect(result.description, "No description available.");
      expect(result.evolutionChainUrl, isNull);
      verify(mockClient.get(tPokemonUrl)).called(1);
      verify(mockClient.get(tSpeciesUrl)).called(1);
    });
  });

  group('fetchPokemonEvolution', () {
    final tEvolutionChainUrl = Uri.parse('${pokeapiBaseUrlForTests}evolution-chain/1/');
    final tEvolutionChainUrlString = tEvolutionChainUrl.toString();

    final tEvolutionChainJson = {
      'chain': {
        'species': {'name': 'pichu'},
        'evolves_to': [
          {
            'species': {'name': 'pikachu'},
            'evolves_to': [
              {
                'species': {'name': 'raichu'},
                'evolves_to': []
              }
            ]
          }
        ]
      }
    };

    test('returns PokemonEvolution when call completes successfully', () async {
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tEvolutionChainJson), 200, headers: utf8JsonHeaders),
      );
      final result = await repository.fetchPokemonEvolution(tEvolutionChainUrlString);
      expect(result.speciesName, 'pichu');
      expect(result.evolvesTo.first.speciesName, 'pikachu');
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });

    test('throws an exception if evolutionChainUrl is empty', () async {
      expect(() => repository.fetchPokemonEvolution(""), throwsA(isA<Exception>()));
      verifyNever(mockClient.get(any));
    });


    test('throws an exception if evolution chain HTTP call fails', () async {
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );
      expect(() => repository.fetchPokemonEvolution(tEvolutionChainUrlString), throwsA(isA<Exception>()));
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });
    
    test('throws an exception if evolution chain data format is invalid', () async {
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode({'invalid_key': 'no_chain_here'}), 200, headers: utf8JsonHeaders),
      );
      expect(() => repository.fetchPokemonEvolution(tEvolutionChainUrlString), throwsA(isA<Exception>()));
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });
  });
}
