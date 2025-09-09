import '../utils/string_utils.dart';
import './pokemon_stats.dart';

/// Represents the detailed information for a specific Pokemon.
///
/// This class holds a comprehensive set of data about a Pokemon,
/// including its physical attributes, abilities, stats, description,
/// evolution details, and moves.
class PokemonDetail {
  /// The unique identifier for the Pokemon.
  final int id;

  /// The name of the Pokemon (e.g., "pikachu").
  final String name;

  /// The URL for the Pokemon's official artwork image.
  /// Falls back to front_default sprite if official-artwork is unavailable,
  /// or an empty string if no image URL is found.
  final String imageUrl;

  /// A list of type names for the Pokemon (e.g., ["electric"]).
  final List<String> types;

  /// The height of the Pokemon in decimetres (e.g., 4.0 for 0.4m).
  final double height;

  /// The weight of the Pokemon in hectograms (e.g., 60.0 for 6kg).
  final double weight;

  /// A list of the Pokemon's abilities, with names formatted for display
  /// (e.g., "Static", "Lightning Rod").
  final List<String> abilities;

  /// A list of [PokemonStats] objects representing the Pokemon's base stats.
  final List<PokemonStats> stats;

  /// A textual description of the Pokemon, usually a Pokédex entry.
  final String description;

  /// The URL for the Pokemon's evolution chain data.
  /// Can be null if no evolution chain URL is available.
  final String? evolutionChainUrl;

  /// The base experience gained for defeating this Pokemon.
  final int baseExperience;

  /// A list of [PokemonMove] objects representing the moves this Pokemon can learn.
  final List<PokemonMove> moves;

  /// The display height of the Pokemon in meters.
  /// Converts height from decimetres to meters.
  double get displayHeight => height / 10;

  /// The display weight of the Pokemon in kilograms.
  /// Converts weight from hectograms to kilograms.
  double get displayWeight => weight / 10;

  /// The Pokemon's ID formatted with a leading '#' and padded to three digits
  /// (e.g., "#025").
  String get formattedId => "#${id.toString().padLeft(3, '0')}";

  /// Returns the [name] of the Pokemon with its first letter capitalized.
  /// (e.g., "pikachu" becomes "Pikachu").
  String get capitalizedName {
    return capitalizeFirstLetter(name);
  }

  /// Creates a [PokemonDetail] instance.
  ///
  /// All parameters except [evolutionChainUrl] are required.
  PokemonDetail({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.height,
    required this.weight,
    required this.abilities,
    required this.stats,
    required this.description,
    this.evolutionChainUrl,
    required this.baseExperience,
    required this.moves,
  });

  /// Creates a [PokemonDetail] instance from a JSON map and other provided details.
  ///
  /// This factory parses the [json] data from an API response.
  /// The [description] and [evolutionChainUrl] are passed in separately as they
  /// are often fetched from different API endpoints or sources.
  ///
  /// Populates fields such as:
  /// - `id`, `name` directly from [json]. `name` defaults to an empty string if null.
  /// - `imageUrl` from `json['sprites']?['other']?['official-artwork']?['front_default']`,
  ///   falling back to `json['sprites']?['front_default']`, then to an empty string.
  /// - `types` by mapping over `json['types']`. Type names default to empty strings if null.
  /// - `height` and `weight` are cast from int to double. (Assumed non-null from API).
  /// - `abilities` are mapped from `json['abilities']` and formatted using `formatHyphenatedName`. Ability names default to empty strings if null.
  /// - `stats` are mapped from `json['stats']` by creating [PokemonStats] objects.
  /// - `baseExperience` from `json['base_experience']`, defaulting to 0 if null.
  /// - `moves` are mapped from `json['moves']` (defaulting to an empty list if null)
  ///   by creating [PokemonMove] objects.
  ///
  /// Throws [TypeError] or similar if required JSON fields (like `id`, `height`, `weight`) are missing or of incorrect type.
  factory PokemonDetail.fromJson(
    Map<String, dynamic> json, {
    required String description,
    String? evolutionChainUrl,
  }) {
    return PokemonDetail(
      id: json['id'],
      name: json['name'] as String? ?? '',
      imageUrl:
          json['sprites']?['other']?['official-artwork']?['front_default'] ??
          json['sprites']?['front_default'] ??
          "",
      types: (json['types'] as List? ?? [])
          .map((typeInfo) => typeInfo['type']?['name'] as String? ?? '')
          .toList(),
      height: (json['height'] as num? ?? 0).toDouble(),
      weight: (json['weight'] as num? ?? 0).toDouble(),
      abilities: (json['abilities'] as List? ?? [])
          .map((abilityInfo) => abilityInfo['ability']?['name'] as String? ?? '')
          .map((name) => formatHyphenatedName(name))
          .toList(),
      stats: (json['stats'] as List? ?? []) 
          .map((statInfo) => PokemonStats.fromJson(statInfo as Map<String, dynamic>))
          .toList(),
      description: description,
      evolutionChainUrl: evolutionChainUrl,
      baseExperience: json['base_experience'] as int? ?? 0,
      moves: (json['moves'] as List? ?? [])
          .map((moveInfo) => PokemonMove.fromJson(moveInfo['move'] as Map<String, dynamic>? ?? {}))
          .toList(),
    );
  }
}

/// Represents a move a Pokemon can learn.
class PokemonMove {
  /// The name of the move (e.g., "tackle", "thunder-shock").
  final String name;

  /// Returns the [name] of the move, formatted for display
  /// (e.g., "thunder-shock" becomes "Thunder Shock").
  String get formattedName {
    return formatHyphenatedName(name);
  }

  /// Creates a [PokemonMove] instance.
  ///
  /// Requires [name].
  PokemonMove({required this.name});

  /// Creates a [PokemonMove] instance from a JSON map.
  ///
  /// Parses `json['name']` for [name]. Defaults to an empty string if 'name' is null.
  /// Throws [TypeError] if 'name' is not a string (and not null).
  factory PokemonMove.fromJson(Map<String, dynamic> json) {
    return PokemonMove(name: json['name'] as String? ?? '');
  }
}
