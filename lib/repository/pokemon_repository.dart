import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex/model/pokemon_list.dart';

import '../model/pokemon.dart';
import '../model/pokemon_detail.dart';
import '../model/pokemon_evolution.dart';

// --- Custom Exception Classes ---
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final Uri? uri;

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

class PokemonNotFoundException extends NetworkException {
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

class DataParsingException implements Exception {
  final String message;
  final dynamic originalException; // Optional: to store the original error

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
// --- End of Custom Exception Classes ---

class PokemonRepository {
  final String baseUrl = "https://pokeapi.co/api/v2/";
  final http.Client _httpClient;

  PokemonRepository({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

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
      final List results = data['results'] as List;

      final futures = results.map((item) async {
        if (item == null || item['url'] == null) {
          debugPrint(
            "Warning: Item or item URL is null in fetchPokemons results.",
          );
          return null;
        }
        final detailUrl = item['url'] as String;
        http.Response detailResponse;
        try {
            detailResponse = await _httpClient.get(Uri.parse(detailUrl));
        } catch (e) {
            debugPrint("Failed to fetch detail for ${item['name']}: $e, URL: $detailUrl");
            return null; // Or throw a specific error if partial failure should stop everything
        }

        if (detailResponse.statusCode == 200) {
          final detailData = jsonDecode(detailResponse.body);
          return Pokemon.fromJson(detailData);
        }
        debugPrint(
          "Failed to fetch detail for ${item['name']}: ${detailResponse.statusCode}, URL: $detailUrl",
        );
        return null;
      }).toList();

      final pokemons = (await Future.wait(futures)).whereType<Pokemon>().toList();
      return PokemonList(count: count, next: next, results: pokemons);
    } catch (e) {
      throw DataParsingException("Error parsing Pokemons list data: $e", originalException: e);
    }
  }

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
        // Not throwing DataParsingException here to allow partial data if main pokemon data is fine.
      }
    } else {
      debugPrint(
        "Failed to load species data for ID $pokemonId: ${speciesResponse.statusCode}, URL: $speciesUri. Using default description/evolution.",
      );
      // Not throwing NetworkException for species data to allow partial success.
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

  Future<PokemonEvolution> fetchPokemonEvolution(
    String evolutionChainUrlString,
  ) async {
    if (evolutionChainUrlString.isEmpty) {
      // Or throw ArgumentError perhaps
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