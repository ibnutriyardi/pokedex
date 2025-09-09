import 'package:pokedex/model/pokemon.dart';

/// Represents a paginated list of Pokemon resources.
///
/// This is typically returned by API endpoints that list multiple Pokemon.
/// It includes a count of total available resources, a URL to the next page
/// of results (if any), and the list of [Pokemon] objects for the current page.
class PokemonList {
  /// The total number of Pokemon resources available.
  final int count;

  /// The URL for the next page of Pokemon results.
  ///
  /// This can be null if there are no more pages.
  final String? next;

  /// A list of [Pokemon] objects for the current page.
  final List<Pokemon> results;

  /// Creates a [PokemonList] instance.
  ///
  /// Requires [count], [next] (which can be null), and [results].
  PokemonList({required this.count, required this.next, required this.results});

  /// Creates a [PokemonList] instance from a JSON map.
  ///
  /// Parses the `count`, `next` URL, and a list of `results` where each
  /// item is converted to a [Pokemon] object using `Pokemon.fromJson`.
  ///
  /// Throws a [TypeError] if `count` or `results` are missing or if
  /// items in `results` are not valid JSON objects for [Pokemon.fromJson].
  factory PokemonList.fromJson(Map<String, dynamic> json) {
    return PokemonList(
      count: json['count'] as int,
      next: json['next'] as String?,
      results: (json['results'] as List)
          .map((pokemonJson) => Pokemon.fromJson(pokemonJson as Map<String, dynamic>))
          .toList(),
    );
  }
}
