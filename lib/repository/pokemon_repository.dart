import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex/model/pokemon_list.dart';

import '../model/pokemon.dart';
import '../model/pokemon_detail.dart';
import '../model/pokemon_evolution.dart';

/// {@template network_exception}
/// An exception that occurs during a network request.
///
/// This could be due to issues like a failed connection, an unexpected
/// HTTP status code from the server, or other network-related problems.
/// {@endtemplate}
class NetworkException implements Exception {
  /// A human-readable message describing the error.
  final String message;

  /// The HTTP status code received from the server, if applicable.
  final int? statusCode;

  /// The URI of the network request that caused the exception, if available.
  final Uri? uri;

  /// {@macro network_exception}
  NetworkException(this.message, {this.statusCode, this.uri});

  @override
  String toString() {
    String result = 'NetworkException: $message';
    if (statusCode != null) {
      result += ', StatusCode: $statusCode';
    }
    if (uri != null) {
      result += ', URI: $uri';
    }
    return result;
  }
}

/// {@template pokemon_not_found_exception}
/// An exception indicating that a requested Pokémon or Pokémon-related resource
/// was not found on the server (typically a 404 error).
///
/// Extends [NetworkException] with a fixed [statusCode] of 404.
/// {@endtemplate}
class PokemonNotFoundException extends NetworkException {
  /// {@macro pokemon_not_found_exception}
  PokemonNotFoundException(String message, {Uri? uri})
      : super(message, statusCode: 404, uri: uri);

  @override
  String toString() {
    String result = 'PokemonNotFoundException: $message';
    if (uri != null) {
      result += ', URI: $uri';
    }
    return result;
  }
}

/// {@template data_parsing_exception}
/// An exception that occurs when there is an error parsing data received
/// from a network request, typically when decoding JSON.
/// {@endtemplate}
class DataParsingException implements Exception {
  /// A human-readable message describing the parsing error.
  final String message;

  /// The original exception that occurred during parsing, if any.
  /// This can be useful for debugging the root cause of the parsing failure.
  final dynamic originalException;

  /// {@macro data_parsing_exception}
  DataParsingException(this.message, {this.originalException});

  @override
  String toString() {
    String result = 'DataParsingException: $message';
    if (originalException != null) {
      result += '\nOriginal Exception: $originalException';
    }
    return result;
  }
}

/// {@template pokemon_repository}
/// A repository responsible for fetching Pokémon data from the PokeAPI.
///
/// This class handles all network interactions and data transformations
/// related to Pokémon, Pokémon details, and their evolutions.
/// {@endtemplate}
class PokemonRepository {
  /// The base URL for the PokeAPI.
  final String baseUrl = "https://pokeapi.co/api/v2/";
  
  final http.Client _httpClient;

  /// Creates a [PokemonRepository].
  ///
  /// An optional [httpClient] can be provided, primarily for testing purposes
  /// to allow mocking of HTTP requests. If not provided, a default
  /// [http.Client] instance is used.
  PokemonRepository({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Fetches a list of Pokémon from the PokeAPI.
  ///
  /// The [limit] specifies the maximum number of Pokémon to retrieve in one call.
  /// Defaults to 10.
  /// The optional [nextUrl] can be provided to fetch the subsequent page of
  /// Pokémon results, typically obtained from a previous [PokemonList.next] value.
  ///
  /// Returns a [Future] that completes with a [PokemonList] containing the
  /// fetched Pokémon and pagination details.
  ///
  /// Throws a [NetworkException] if the HTTP GET request itself fails (e.g.,
  /// due to a connection issue) or if the server returns an unexpected
  /// status code (other than 200 or 404).
  /// Throws a [PokemonNotFoundException] if the Pokémon list endpoint returns a
  /// 404 status code, indicating the resource was not found.
  /// Throws a [DataParsingException] if the response from the server cannot be
  /// parsed correctly (e.g., malformed JSON) or if the construction via
  /// `PokemonList.fromJson` fails.
  Future<PokemonList> fetchPokemons({int limit = 10, String? nextUrl}) async {
    final uri = Uri.parse(nextUrl ?? "${baseUrl}pokemon?limit=$limit");
    http.Response response;
    try {
      response = await _httpClient.get(uri);
    } catch (e) {
      throw NetworkException("Failed to execute request for Pokemons list: $e", uri: uri);
    }

    if (response.statusCode == 404) {
      throw PokemonNotFoundException("Pokemons list not found", uri: uri);
    }
    if (response.statusCode != 200) {
      throw NetworkException(
        "Failed to fetch Pokemons",
        statusCode: response.statusCode,
        uri: uri,
      );
    }

    try {
      final data = jsonDecode(response.body);
      final int count = data['count'] as int;
      final String? next = data['next'] as String?;
      final List resultsFromApi = data['results'] as List; 

      final List<Map<String, dynamic>> detailedPokemonJsonList = [];
      for (final item in resultsFromApi) {
        if (item == null || !(item is Map) || item['url'] == null) {
          debugPrint(
            "Warning: Item is null, not a Map, or item URL is null in fetchPokemons results. Item: $item",
          );
          continue;
        }
        
        final String? itemName = item['name'] as String?;
        final String? detailUrl = item['url'] as String?;

        if (detailUrl == null) {
             debugPrint("Warning: detailUrl is null for item: $item");
             continue;
        }

        http.Response detailResponse;
        try {
            detailResponse = await _httpClient.get(Uri.parse(detailUrl));
        } catch (e) {
            debugPrint("Failed to fetch detail for ${itemName ?? 'unknown'}: $e, URL: $detailUrl");
            continue; 
        }

        if (detailResponse.statusCode == 200) {
          try {
            final detailData = jsonDecode(detailResponse.body) as Map<String, dynamic>; 
            detailedPokemonJsonList.add(detailData);
          } catch(e) {
            debugPrint("Error parsing detail JSON for ${itemName ?? 'unknown'}: $e, URL: $detailUrl. Body (first 100 chars): ${detailResponse.body.substring(0, detailResponse.body.length > 100 ? 100 : detailResponse.body.length)}");
            continue;
          }
        } else {
          debugPrint(
            "Failed to fetch detail for ${itemName ?? 'unknown'}: Status ${detailResponse.statusCode}, URL: $detailUrl",
          );
        }
      }

      final Map<String, dynamic> pokemonListInputJson = {
        'count': count,
        'next': next,
        'results': detailedPokemonJsonList, 
      };
      
      return PokemonList.fromJson(pokemonListInputJson);
    } catch (e) {
      if (e is DataParsingException) {
          rethrow;
      }
      throw DataParsingException("Error processing Pokemons list data for $uri: $e", originalException: e);
    }
  }

  /// Fetches detailed information for a specific Pokémon identified by its [pokemonId].
  ///
  /// This method makes two concurrent API calls:
  /// 1. To get the main Pokémon data (name, sprites, types, etc.).
  /// 2. To get the Pokémon species data (flavor text for description, evolution chain URL).
  ///
  /// If fetching species data fails or parsing it encounters an error, this method
  /// will use default values (e.g., "No description available.") and proceed
  /// with the main Pokémon data if that was successful.
  ///
  /// Returns a [Future] that completes with a [PokemonDetail] object containing
  /// comprehensive information about the Pokémon.
  ///
  /// Throws a [NetworkException] if the `Future.wait` for both API calls fails,
  /// or if the main Pokémon data call returns an unexpected status code (other than 200 or 404).
  /// Throws a [PokemonNotFoundException] if the main Pokémon data endpoint
  /// (for the given [pokemonId]) returns a 404 status code.
  /// Throws a [DataParsingException] if the main Pokémon data from the server
  /// cannot be parsed, or if creating the [PokemonDetail] object from the
  /// combined data fails.
  Future<PokemonDetail> fetchPokemonDetails(int pokemonId) async {
    final pokemonUri = Uri.parse("${baseUrl}pokemon/$pokemonId");
    final speciesUri = Uri.parse("${baseUrl}pokemon-species/$pokemonId");

    List<http.Response> responses;
    try {
      responses = await Future.wait([
        _httpClient.get(pokemonUri),
        _httpClient.get(speciesUri),
      ]);
    } catch (e) {
      throw NetworkException("Failed to execute requests for Pokemon details and species data: $e");
    }

    final pokemonResponse = responses[0];
    final speciesResponse = responses[1];

    if (pokemonResponse.statusCode == 404) {
      throw PokemonNotFoundException("Pokemon with ID $pokemonId not found", uri: pokemonUri);
    }
    if (pokemonResponse.statusCode != 200) {
      throw NetworkException(
        "Failed to load Pokemon data",
        statusCode: pokemonResponse.statusCode,
        uri: pokemonUri,
      );
    }
    
    dynamic pokemonData;
    try {
        pokemonData = jsonDecode(pokemonResponse.body);
    } catch (e) {
        throw DataParsingException("Error parsing Pokemon data for ID $pokemonId: $e", originalException: e);
    }

    String description = "No description available.";
    String? evolutionChainUrl;

    if (speciesResponse.statusCode == 200) {
      try {
        final speciesData = jsonDecode(speciesResponse.body);
        final flavorTextEntries = speciesData['flavor_text_entries'] as List?;
        if (flavorTextEntries != null) {
          for (var entry in flavorTextEntries) {
            if (entry is Map &&
                entry['language'] is Map &&
                entry['language']['name'] == 'en') {
              if (entry['flavor_text'] is String) {
                description = entry['flavor_text']
                    .toString()
                    .replaceAll('\n', ' ')
                    .replaceAll('\f', ' ');
                break;
              }
            }
          }
        }
        final evolutionChainData = speciesData['evolution_chain'];
        if (evolutionChainData is Map && evolutionChainData['url'] is String) {
          evolutionChainUrl = evolutionChainData['url'] as String?;
        }
      } catch (e) {
        debugPrint("Error parsing species data for ID $pokemonId: $e. Using default values.");
      }
    } else {
      debugPrint(
        "Failed to load species data for ID $pokemonId: ${speciesResponse.statusCode}, URL: $speciesUri. Using default description/evolution.",
      );
    }

    try {
      return PokemonDetail.fromJson(
        pokemonData,
        description: description,
        evolutionChainUrl: evolutionChainUrl,
      );
    } catch (e) {
      throw DataParsingException("Error creating PokemonDetail object for ID $pokemonId: $e", originalException: e);
    }
  }

  /// Fetches the evolution chain data for a Pokémon using its [evolutionChainUrlString].
  ///
  /// The [evolutionChainUrlString] is typically obtained from [PokemonDetail.evolutionChainUrl].
  ///
  /// Returns a [Future] that completes with a [PokemonEvolution] object representing
  /// the root of the evolution chain.
  ///
  /// Throws a [DataParsingException] if the [evolutionChainUrlString] is empty
  /// or if the evolution data from the server is malformed (e.g., missing the 'chain' key or unparsable JSON).
  /// Throws a [NetworkException] if the HTTP GET request itself fails or if the
  /// server returns an unexpected status code (other than 200 or 404).
  /// Throws a [PokemonNotFoundException] if the evolution chain endpoint returns a
  /// 404 status code.
  Future<PokemonEvolution> fetchPokemonEvolution(
    String evolutionChainUrlString,
  ) async {
    if (evolutionChainUrlString.isEmpty) {
      throw DataParsingException("Evolution chain URL is empty."); 
    }
    final uri = Uri.parse(evolutionChainUrlString);
    http.Response evolutionResponse;
    try {
        evolutionResponse = await _httpClient.get(uri);
    } catch (e) {
        throw NetworkException("Failed to execute request for evolution chain: $e", uri: uri);
    }

    if (evolutionResponse.statusCode == 404) {
      throw PokemonNotFoundException("Evolution chain not found", uri: uri);
    }
    if (evolutionResponse.statusCode != 200) {
      throw NetworkException(
        "Failed to load evolution chain data",
        statusCode: evolutionResponse.statusCode,
        uri: uri,
      );
    }

    try {
      final evolutionData = jsonDecode(evolutionResponse.body);
      if (evolutionData['chain'] == null) {
        throw DataParsingException(
          "Invalid evolution chain data format from URL: $uri",
        );
      }
      return PokemonEvolution.fromJson(evolutionData['chain']);
    } catch (e) {
      throw DataParsingException("Error parsing evolution chain data from URL $uri: $e", originalException: e);
    }
  }
}
