import 'dart:convert';
import 'dart:io'; // Added for SocketException example
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pokedex/model/pokemon.dart';
import 'package:pokedex/repository/pokemon_repository.dart';

// Custom exceptions are now part of pokemon_repository.dart
// No separate import needed if they are defined in the same file.

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
  // final Uri dummyUriForException = Uri.parse('http://dummy.api/call'); // Not strictly needed if checking specific URIs from test setup

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
      // Arrange
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
      // Act
      final result = await repository.fetchPokemons(limit: tLimit);
      // Assert
      expect(result.count, 2);
      expect(result.next, null);
      expect(result.results.length, 2);
      expect(result.results.map((p) => p.id).toList(), containsAll([tPokemon1.id, tPokemon2.id]));
      verify(mockClient.get(tPokemonListUrl)).called(1);
      verify(mockClient.get(tPokemonDetailUrl1)).called(1);
      verify(mockClient.get(tPokemonDetailUrl2)).called(1);
    });

    test('returns a PokemonList using nextUrl when provided', () async {
      // Arrange
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
      // Act
      final result = await repository.fetchPokemons(limit: tLimit, nextUrl: tNextUrl.toString());
      // Assert
      expect(result.results.length, 1);
      expect(result.results.first.id, tPokemon1.id); 
      verify(mockClient.get(tNextUrl)).called(1);
      verify(mockClient.get(tPokemonDetailUrl1)).called(1);
    });

    test('throws NetworkException if the HTTP GET call itself fails', () async {
      // Arrange
      when(mockClient.get(tPokemonListUrl)).thenThrow(const SocketException("Connection failed"));
      // Act
      final call = repository.fetchPokemons;
      // Assert
      expect(() => call(limit: tLimit), 
             throwsA(isA<NetworkException>()
                  .having((e) => e.message, 'message', contains("Connection failed"))
                  .having((e) => e.uri, 'uri', tPokemonListUrl)));
    });

    test('throws PokemonNotFoundException if the initial HTTP call returns 404', () async {
      // Arrange
      when(mockClient.get(tPokemonListUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );
      // Act
      final call = repository.fetchPokemons;
      // Assert
      expect(() => call(limit: tLimit), 
             throwsA(isA<PokemonNotFoundException>()
                  .having((e) => e.uri, 'uri', tPokemonListUrl)
                  .having((e) => e.statusCode, 'statusCode', 404)));
    });
    
    test('throws NetworkException if the initial HTTP call returns non-200/404 error', () async {
      // Arrange
      when(mockClient.get(tPokemonListUrl)).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );
      // Act
      final call = repository.fetchPokemons;
      // Assert
      expect(() => call(limit: tLimit), 
             throwsA(isA<NetworkException>()
                  .having((e) => e.statusCode, 'statusCode', 500)
                  .having((e) => e.uri, 'uri', tPokemonListUrl)));
    });

    test('throws DataParsingException if initial list JSON is malformed', () async {
      // Arrange
      when(mockClient.get(tPokemonListUrl)).thenAnswer(
        // Corrected: Provide a truly malformed string and correct http.Response arguments
        (_) async => http.Response('{malformed_json_missing_quote', 200, headers: utf8JsonHeaders),
      );
      // Act
      final call = repository.fetchPokemons;
      // Assert
      expect(() => call(limit: tLimit), throwsA(isA<DataParsingException>()));
    });

     test('returns list with successfully fetched details even if some details fail (debugPrint for detail error)', () async {
      // Arrange
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
      // Simulate a 500 error for the second detail call
      when(mockClient.get(tPokemonDetailUrl2)).thenAnswer(
        (_) async => http.Response('Server Error For Detail', 500),
      );
      // Act
      final result = await repository.fetchPokemons(limit: tLimit);
      // Assert (The repository currently debugPrints and returns null for failed details)
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
      // Arrange
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonDataJson), 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tSpeciesJson), 200, headers: utf8JsonHeaders),
      );
      // Act
      final result = await repository.fetchPokemonDetails(tPokemonId);
      // Assert
      expect(result.id, tPokemonId);
      expect(result.name, 'pikachu');
      expect(result.description, 'Pikachu that can generate powerful electricity have cheek sacs that are extra soft.');
      expect(result.evolutionChainUrl, tMockEvolutionChainUrl);
      verify(mockClient.get(tPokemonUrl)).called(1);
      verify(mockClient.get(tSpeciesUrl)).called(1);
    });

    test('throws NetworkException if Future.wait itself fails (e.g., one GET throws before completing)', () async {
      // Arrange
      when(mockClient.get(tPokemonUrl)).thenThrow(const SocketException("Connection failed for PokemonUrl"));
      // For Future.wait, even if one fails early, it might try to execute others if not set up to cancel
      // So, we also mock the other to avoid unawaited futures if it were to be called.
      when(mockClient.get(tSpeciesUrl)).thenAnswer((_) async => http.Response(jsonEncode(tSpeciesJson), 200, headers: utf8JsonHeaders)); 
      // Act
      final call = repository.fetchPokemonDetails;
      // Assert
      expect(() => call(tPokemonId), 
            throwsA(isA<NetworkException>()
                .having((e) => e.message, 'message', contains("Failed to execute requests for Pokemon details and species data"))));
    });

    test('throws PokemonNotFoundException if the Pokemon HTTP call returns 404', () async {
      // Arrange
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );
      // Species call should still be mocked as Future.wait will try to run it.
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tSpeciesJson), 200, headers: utf8JsonHeaders),
      );
      // Act
      final call = repository.fetchPokemonDetails;
      // Assert
      expect(() => call(tPokemonId), 
             throwsA(isA<PokemonNotFoundException>()
                  .having((e) => e.uri, 'uri', tPokemonUrl)));
      // Verify PokemonUrl was called, SpeciesUrl might or might not complete depending on Future.wait error handling
      verify(mockClient.get(tPokemonUrl)).called(1);
    });

    test('throws DataParsingException if Pokemon data is malformed', () async {
      // Arrange
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        // Corrected: Provide a truly malformed string and correct http.Response arguments
        (_) async => http.Response('{malformed_pokemon_data', 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tSpeciesJson), 200, headers: utf8JsonHeaders),
      );
      // Act
      final call = repository.fetchPokemonDetails;
      // Assert
      expect(() => call(tPokemonId), throwsA(isA<DataParsingException>()
        .having((e) => e.message, 'message', contains("Error parsing Pokemon data for ID $tPokemonId"))
      ));
    });

    test('returns PokemonDetail with default description and null evolutionUrl if Species HTTP call fails (e.g. 404)', () async {
      // Arrange
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonDataJson), 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404), // Species call fails
      );
      // Act
      final result = await repository.fetchPokemonDetails(tPokemonId);
      // Assert (Repository should handle this gracefully and not throw for species failure)
      expect(result.id, tPokemonId);
      expect(result.description, "No description available.");
      expect(result.evolutionChainUrl, isNull);
      verify(mockClient.get(tPokemonUrl)).called(1);
      verify(mockClient.get(tSpeciesUrl)).called(1);
    });

     test('returns PokemonDetail with default description if Species JSON is malformed', () async {
      // Arrange
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonDataJson), 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        // Corrected: Provide a truly malformed string for species data
        (_) async => http.Response('{malformed_species_json', 200, headers: utf8JsonHeaders),
      );
      // Act
      final result = await repository.fetchPokemonDetails(tPokemonId);
      // Assert
      expect(result.id, tPokemonId);
      expect(result.description, "No description available."); // Defaults due to parsing error
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
      // Arrange
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tEvolutionChainJson), 200, headers: utf8JsonHeaders),
      );
      // Act
      final result = await repository.fetchPokemonEvolution(tEvolutionChainUrlString);
      // Assert
      expect(result.speciesName, 'pichu');
      expect(result.evolvesTo.first.speciesName, 'pikachu');
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });

    test('throws DataParsingException if evolutionChainUrl is empty', () async {
      // Arrange & Act & Assert
      expect(() => repository.fetchPokemonEvolution(""), throwsA(isA<DataParsingException>()));
      verifyNever(mockClient.get(any));
    });

    test('throws NetworkException if HTTP GET call itself fails', () async {
      // Arrange
      when(mockClient.get(tEvolutionChainUrl)).thenThrow(const SocketException("Connection failed"));
      // Act & Assert
      expect(() => repository.fetchPokemonEvolution(tEvolutionChainUrlString), 
            throwsA(isA<NetworkException>()
                  .having((e) => e.message, 'message', contains("Connection failed"))
                  .having((e) => e.uri, 'uri', tEvolutionChainUrl)));
    });

    test('throws PokemonNotFoundException if evolution chain HTTP call returns 404', () async {
      // Arrange
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );
      // Act & Assert
      expect(() => repository.fetchPokemonEvolution(tEvolutionChainUrlString), 
            throwsA(isA<PokemonNotFoundException>()
                .having((e) => e.uri, 'uri', tEvolutionChainUrl)));
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });
    
    test('throws DataParsingException if evolution chain data format is invalid (no chain key)', () async {
      // Arrange
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode({'invalid_key': 'no_chain_here'}), 200, headers: utf8JsonHeaders),
      );
      // Act & Assert
      expect(() => repository.fetchPokemonEvolution(tEvolutionChainUrlString), 
            throwsA(isA<DataParsingException>()
                .having((e) => e.message, 'message', contains("Invalid evolution chain data format"))));
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });

    test('throws DataParsingException if evolution chain JSON is malformed', () async {
      // Arrange
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        // Corrected: Provide a truly malformed string and correct http.Response arguments
        (_) async => http.Response('{malformed_evolution_json', 200, headers: utf8JsonHeaders),
      );
      // Act & Assert
      expect(() => repository.fetchPokemonEvolution(tEvolutionChainUrlString), throwsA(isA<DataParsingException>()));
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });
  });
}
