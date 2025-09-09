// For debugPrintOverride
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint
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

  group('Exception toString methods', () {
    test('DataParsingException toString includes originalException if provided', () {
      final originalEx = FormatException("Bad format");
      final parsingEx = DataParsingException("JSON parsing failed", originalException: originalEx);
      expect(parsingEx.toString(), contains("DataParsingException: JSON parsing failed"));
      expect(parsingEx.toString(), contains("Original Exception: FormatException: Bad format"));
    });

    test('DataParsingException toString does not include originalException if not provided', () {
      final parsingEx = DataParsingException("JSON parsing failed");
      expect(parsingEx.toString(), "DataParsingException: JSON parsing failed");
      expect(parsingEx.toString(), isNot(contains("Original Exception:")));
    });
  });

  group('fetchPokemons', () {
    final tLimit = 10;
    final tPokemonListUrl = Uri.parse('${pokeapiBaseUrlForTests}pokemon?limit=$tLimit');
    final tPokemonDetailUrl1 = Uri.parse('${pokeapiBaseUrlForTests}pokemon/1/');
    final tPokemonDetailUrl2 = Uri.parse('${pokeapiBaseUrlForTests}pokemon/2/');
    final tPokemonDetailUrl3 = Uri.parse('${pokeapiBaseUrlForTests}pokemon/3/');

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
      expect(result.results.map((p) => p.id).toList(), containsAll([tPokemon1.id, Pokemon.fromJson(tPokemonJson2).id]));
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

    test('handles null or invalid items in results list and prints warnings', () async {
      List<String> localDebugPrintOutput = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) localDebugPrintOutput.add(message);
      };

      final nullItem = null;
      final notAMapItem = []; // Example of an item that is not a Map
      final itemWithNullUrl = {'name': 'pokemon_null_url', 'url': null};
      final itemWithEmptyUrl = {'name': 'pokemon_empty_url', 'url': ''};
      final validItem = {'name': 'valid_pokemon', 'url': tPokemonDetailUrl1.toString()};

      when(mockClient.get(tPokemonListUrl)).thenAnswer((_) async => http.Response(
            jsonEncode({
              'count': 5, 
              'next': null,
              'results': [
                nullItem,
                notAMapItem,
                itemWithNullUrl,
                itemWithEmptyUrl,
                validItem,
              ],
            }),
            200,
            headers: utf8JsonHeaders,
          ));
      when(mockClient.get(tPokemonDetailUrl1))
          .thenAnswer((_) async => http.Response(jsonEncode(tPokemonJson1), 200, headers: utf8JsonHeaders));

      final result = await repository.fetchPokemons(limit: tLimit);

      expect(result.results.length, 1, reason: "Only the valid pokemon should be processed.");
      if (result.results.isNotEmpty) expect(result.results.first.name, 'bulbasaur');
      
      expect(localDebugPrintOutput, hasLength(4), reason: "Should be exactly 4 warning messages.");
      expect(localDebugPrintOutput[0], startsWith("Warning: Item is null or not a Map in fetchPokemons results. Item: null"), reason: "DebugPrint for actual null item missing or incorrect.");
      expect(localDebugPrintOutput[1], startsWith("Warning: Item is null or not a Map in fetchPokemons results. Item: ${notAMapItem.toString()}"), reason: "DebugPrint for non-Map item missing or incorrect.");
      expect(localDebugPrintOutput[2], startsWith("Warning: detailUrl is null or empty for item: ${itemWithNullUrl.toString()}"), reason: "DebugPrint for item with null URL value missing or incorrect.");
      expect(localDebugPrintOutput[3], startsWith("Warning: detailUrl is null or empty for item: ${itemWithEmptyUrl.toString()}"), reason: "DebugPrint for item with empty URL value missing or incorrect.");

      debugPrint = originalDebugPrint; // Restore original
    });

    test('handles malformed JSON in detail response and prints warning', () async {
      List<String> localDebugPrintOutput = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) localDebugPrintOutput.add(message);
      };

      const malformedDetailItemName = 'malformed_pokemon_name';
      final malformedDetailItemUrl = Uri.parse('${pokeapiBaseUrlForTests}pokemon/malformed/');
      final malformedItemInList = {'name': malformedDetailItemName, 'url': malformedDetailItemUrl.toString()};
      final validItemInList = {'name': 'good_pokemon', 'url': tPokemonDetailUrl1.toString()};
      const malformedJsonBody = 'this is not json {';

      when(mockClient.get(tPokemonListUrl)).thenAnswer((_) async => http.Response(
            jsonEncode({
              'count': 2,
              'next': null,
              'results': [ malformedItemInList, validItemInList ],
            }),
            200,
            headers: utf8JsonHeaders,
          ));
      
      when(mockClient.get(malformedDetailItemUrl)).thenAnswer((_) async => http.Response(
          malformedJsonBody, 
          200, 
          headers: utf8JsonHeaders));
      
      when(mockClient.get(tPokemonDetailUrl1))
          .thenAnswer((_) async => http.Response(jsonEncode(tPokemonJson1), 200, headers: utf8JsonHeaders));

      final result = await repository.fetchPokemons(limit: tLimit);

      expect(result.results.length, 1, reason: "Only the good_pokemon should be processed.");
      if (result.results.isNotEmpty) expect(result.results.first.name, 'bulbasaur');
      
      expect(localDebugPrintOutput, isNotEmpty, reason: "Debug print for malformed JSON was expected.");
      expect(localDebugPrintOutput.first, startsWith("Error parsing detail JSON for $malformedDetailItemName"), reason: "DebugPrint for malformed detail JSON missing or incorrect.");
      expect(localDebugPrintOutput.first, contains("URL: $malformedDetailItemUrl"), reason: "DebugPrint for malformed detail JSON should contain the URL.");
      expect(localDebugPrintOutput.first, contains("Body (first 100 chars): $malformedJsonBody"), reason: "DebugPrint for malformed detail JSON should contain the start of the body.");

      debugPrint = originalDebugPrint; // Restore original
    });

    test('handles error during detail fetch for an item and prints warning', () async {
      List<String> localDebugPrintOutput = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) localDebugPrintOutput.add(message);
      };

      when(mockClient.get(tPokemonListUrl)).thenAnswer((_) async => http.Response(
            jsonEncode({
              'count': 3, 
              'next': null,
              'results': [
                {'name': 'good_pokemon', 'url': tPokemonDetailUrl1.toString()},
                {'name': 'bad_fetch_pokemon', 'url': tPokemonDetailUrl2.toString()},
                {'name': 'network_fail_pokemon', 'url': tPokemonDetailUrl3.toString()}
              ],
            }),
            200,
            headers: utf8JsonHeaders,
          ));
      when(mockClient.get(tPokemonDetailUrl1))
          .thenAnswer((_) async => http.Response(jsonEncode(tPokemonJson1), 200, headers: utf8JsonHeaders)); 
      when(mockClient.get(tPokemonDetailUrl2)) 
          .thenAnswer((_) async => http.Response('Server Error', 500));
      when(mockClient.get(tPokemonDetailUrl3)) 
          .thenThrow(const SocketException("Connection issue")); 

      final result = await repository.fetchPokemons(limit: tLimit);

      expect(result.results.length, 1, reason: "Only the good pokemon should make it.");
      if (result.results.isNotEmpty) expect(result.results.first.name, 'bulbasaur');
      expect(localDebugPrintOutput, contains(startsWith("Failed to fetch detail for bad_fetch_pokemon: Status 500")), reason: "DebugPrint for 500 status on detail fetch missing.");
      expect(localDebugPrintOutput, contains(startsWith("Failed to fetch detail for network_fail_pokemon: SocketException: Connection issue")), reason: "DebugPrint for SocketException on detail fetch missing.");

      debugPrint = originalDebugPrint; // Restore original
    });

    test('throws NetworkException if the HTTP GET call itself fails', () async {
      when(mockClient.get(tPokemonListUrl)).thenThrow(const SocketException("Connection failed"));
      final call = repository.fetchPokemons;
      expect(() => call(limit: tLimit), 
             throwsA(isA<NetworkException>()
                  .having((e) => e.message, 'message', contains("Connection failed"))
                  .having((e) => e.uri, 'uri', tPokemonListUrl)));
    });

    test('throws PokemonNotFoundException if the initial HTTP call returns 404', () async {
      when(mockClient.get(tPokemonListUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );
      final call = repository.fetchPokemons;
      expect(() => call(limit: tLimit), 
             throwsA(isA<PokemonNotFoundException>()
                  .having((e) => e.uri, 'uri', tPokemonListUrl)
                  .having((e) => e.statusCode, 'statusCode', 404)));
    });
    
    test('throws NetworkException if the initial HTTP call returns non-200/404 error', () async {
      when(mockClient.get(tPokemonListUrl)).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );
      final call = repository.fetchPokemons;
      expect(() => call(limit: tLimit), 
             throwsA(isA<NetworkException>()
                  .having((e) => e.statusCode, 'statusCode', 500)
                  .having((e) => e.uri, 'uri', tPokemonListUrl)));
    });

    test('throws DataParsingException if initial list JSON is malformed', () async {
      when(mockClient.get(tPokemonListUrl)).thenAnswer(
        (_) async => http.Response('{malformed_json_missing_quote', 200, headers: utf8JsonHeaders),
      );
      final call = repository.fetchPokemons;
      expect(() => call(limit: tLimit), throwsA(isA<DataParsingException>()));
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

    test('throws NetworkException if Pokemon HTTP call returns non-200/404 error', () async {
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response('Internal Server Error', 500, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tSpeciesJson), 200, headers: utf8JsonHeaders),
      );

      final call = repository.fetchPokemonDetails;
      expect(
        () => call(tPokemonId),
        throwsA(isA<NetworkException>()
            .having((e) => e.message, 'message', 'Failed to load Pokemon data')
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.uri, 'uri', tPokemonUrl)),
      );
      verify(mockClient.get(tPokemonUrl)).called(1);
      verify(mockClient.get(tSpeciesUrl)).called(1);
    });

    test('throws DataParsingException if PokemonDetail.fromJson fails (valid JSON, bad structure)', () async {
      final malstructuredPokemonDataJson = {
        'id': tPokemonId, 'name': 'bad_pikachu', 
        'sprites': "not_a_map", 
        'types': [{'type': {'name': 'electric'}}],
      };

      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(malstructuredPokemonDataJson), 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tSpeciesJson), 200, headers: utf8JsonHeaders),
      );

      final call = repository.fetchPokemonDetails;
      expect(
        () => call(tPokemonId),
        throwsA(isA<DataParsingException>()
            .having((e) => e.message, 'message', contains("Error creating PokemonDetail object for ID $tPokemonId"))
            .having((e) => e.originalException, 'originalException', isNotNull) 
            ),
      );
    });


    test('throws NetworkException if Future.wait itself fails (e.g., one GET throws before completing)', () async {
      when(mockClient.get(tPokemonUrl)).thenThrow(const SocketException("Connection failed for PokemonUrl"));
      when(mockClient.get(tSpeciesUrl)).thenAnswer((_) async => http.Response(jsonEncode(tSpeciesJson), 200, headers: utf8JsonHeaders)); 
      final call = repository.fetchPokemonDetails;
      expect(() => call(tPokemonId), 
            throwsA(isA<NetworkException>()
                .having((e) => e.message, 'message', contains("Failed to execute requests for Pokemon details and species data"))));
    });

    test('throws PokemonNotFoundException if the Pokemon HTTP call returns 404', () async {
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tSpeciesJson), 200, headers: utf8JsonHeaders),
      );
      final call = repository.fetchPokemonDetails;
      expect(() => call(tPokemonId), 
             throwsA(isA<PokemonNotFoundException>()
                  .having((e) => e.uri, 'uri', tPokemonUrl)));
      verify(mockClient.get(tPokemonUrl)).called(1);
    });

    test('throws DataParsingException if Pokemon data is malformed (jsonDecode fails)', () async {
      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response('{malformed_pokemon_data', 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tSpeciesJson), 200, headers: utf8JsonHeaders),
      );
      final call = repository.fetchPokemonDetails;
      expect(() => call(tPokemonId), throwsA(isA<DataParsingException>()
        .having((e) => e.message, 'message', contains("Error parsing Pokemon data for ID $tPokemonId"))
      ));
    });

    test('uses default description and prints warning if Species HTTP call fails (e.g. 500)', () async {
      List<String> localDebugPrintOutput = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) localDebugPrintOutput.add(message);
      };

      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonDataJson), 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response('Species Server Error', 500), 
      );
      final result = await repository.fetchPokemonDetails(tPokemonId);
      expect(result.description, "No description available.");
      expect(result.evolutionChainUrl, isNull);
      expect(localDebugPrintOutput, contains(startsWith("Failed to load species data for ID $tPokemonId: 500")));

      debugPrint = originalDebugPrint;
    });

     test('uses default description and prints warning if Species JSON is malformed', () async {
       List<String> localDebugPrintOutput = [];
       final originalDebugPrint = debugPrint;
       debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) localDebugPrintOutput.add(message);
      };

      when(mockClient.get(tPokemonUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode(tPokemonDataJson), 200, headers: utf8JsonHeaders),
      );
      when(mockClient.get(tSpeciesUrl)).thenAnswer(
        (_) async => http.Response('{malformed_species_json', 200, headers: utf8JsonHeaders),
      );
      final result = await repository.fetchPokemonDetails(tPokemonId);
      expect(result.description, "No description available.");
      expect(result.evolutionChainUrl, isNull);
      expect(localDebugPrintOutput, contains(startsWith("Error parsing species data for ID $tPokemonId")));
      
      debugPrint = originalDebugPrint;
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

    test('throws DataParsingException if evolutionChainUrl is empty', () async {
      expect(() => repository.fetchPokemonEvolution(""), throwsA(isA<DataParsingException>()));
      verifyNever(mockClient.get(any));
    });

    test('throws NetworkException if HTTP GET call itself fails', () async {
      when(mockClient.get(tEvolutionChainUrl)).thenThrow(const SocketException("Connection failed"));
      expect(() => repository.fetchPokemonEvolution(tEvolutionChainUrlString), 
            throwsA(isA<NetworkException>()
                  .having((e) => e.message, 'message', contains("Connection failed"))
                  .having((e) => e.uri, 'uri', tEvolutionChainUrl)));
    });

    test('throws PokemonNotFoundException if evolution chain HTTP call returns 404', () async {
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );
      expect(() => repository.fetchPokemonEvolution(tEvolutionChainUrlString), 
            throwsA(isA<PokemonNotFoundException>()
                .having((e) => e.uri, 'uri', tEvolutionChainUrl)));
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });

    test('throws NetworkException if evolution chain HTTP call returns non-200/404 error', () async {
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        (_) async => http.Response('Server Error', 500, headers: utf8JsonHeaders),
      );
      expect(
        () => repository.fetchPokemonEvolution(tEvolutionChainUrlString),
        throwsA(isA<NetworkException>()
            .having((e) => e.message, 'message', 'Failed to load evolution chain data')
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.uri, 'uri', tEvolutionChainUrl)),
      );
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });
    
    test('throws DataParsingException if evolution chain data format is invalid (no chain key)', () async {
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        (_) async => http.Response(jsonEncode({'invalid_key': 'no_chain_here'}), 200, headers: utf8JsonHeaders),
      );
      expect(() => repository.fetchPokemonEvolution(tEvolutionChainUrlString), 
            throwsA(isA<DataParsingException>()
                .having((e) => e.message, 'message', contains("Invalid evolution chain data format"))));
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });

    test('throws DataParsingException if evolution chain JSON is malformed', () async {
      when(mockClient.get(tEvolutionChainUrl)).thenAnswer(
        (_) async => http.Response('{malformed_evolution_json', 200, headers: utf8JsonHeaders),
      );
      expect(() => repository.fetchPokemonEvolution(tEvolutionChainUrlString), throwsA(isA<DataParsingException>()));
      verify(mockClient.get(tEvolutionChainUrl)).called(1);
    });
  });
}
