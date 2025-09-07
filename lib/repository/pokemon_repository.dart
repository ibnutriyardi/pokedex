import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex/model/pokemon_list.dart';

import '../model/pokemon.dart';
import '../model/pokemon_detail.dart';
import '../model/pokemon_evolution.dart';

class PokemonRepository {
  final String baseUrl = "https://pokeapi.co/api/v2/";
  final http.Client _httpClient;

  PokemonRepository({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<PokemonList> fetchPokemons({int limit = 10, String? nextUrl}) async {
    final uriString = nextUrl ?? "${baseUrl}pokemon?limit=$limit";
    final response = await _httpClient.get(Uri.parse(uriString));

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to fetch Pokemons: ${response.statusCode}, URL: $uriString",
      );
    }

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
      final detailResponse = await _httpClient.get(Uri.parse(detailUrl));

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
  }

  Future<PokemonDetail> fetchPokemonDetails(int pokemonId) async {
    final pokemonUriString = "${baseUrl}pokemon/$pokemonId";
    final pokemonResponse = await _httpClient.get(Uri.parse(pokemonUriString));

    if (pokemonResponse.statusCode != 200) {
      throw Exception(
        "Failed to load Pokemon data: ${pokemonResponse.statusCode}, URL: $pokemonUriString",
      );
    }
    final pokemonData = jsonDecode(pokemonResponse.body);

    String description = "No description available.";
    String? evolutionChainUrl;

    final speciesUriString = "${baseUrl}pokemon-species/$pokemonId";
    final speciesResponse = await _httpClient.get(Uri.parse(speciesUriString));

    if (speciesResponse.statusCode == 200) {
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
    } else {
      debugPrint(
        "Failed to load species data for description/evolution: ${speciesResponse.statusCode}, URL: $speciesUriString",
      );
    }

    return PokemonDetail.fromJson(
      pokemonData,
      description: description,
      evolutionChainUrl: evolutionChainUrl,
    );
  }

  Future<PokemonEvolution> fetchPokemonEvolution(
    String evolutionChainUrl,
  ) async {
    if (evolutionChainUrl.isEmpty) {
      throw Exception("Evolution chain URL is empty.");
    }

    final evolutionResponse = await _httpClient.get(
      Uri.parse(evolutionChainUrl),
    );

    if (evolutionResponse.statusCode != 200) {
      throw Exception(
        "Failed to load evolution chain data: ${evolutionResponse.statusCode}, URL: $evolutionChainUrl",
      );
    }

    final evolutionData = jsonDecode(evolutionResponse.body);
    if (evolutionData['chain'] == null) {
      throw Exception(
        "Invalid evolution chain data format from URL: $evolutionChainUrl",
      );
    }
    return PokemonEvolution.fromJson(evolutionData['chain']);
  }
}
