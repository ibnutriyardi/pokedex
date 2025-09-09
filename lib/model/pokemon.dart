import '../utils/string_utils.dart';

/// Represents a basic Pokemon entity, typically used in listings.
///
/// Contains essential information like ID, name, image URL, and types.
class Pokemon {
  /// The unique identifier for the Pokemon.
  final int id;

  /// The name of the Pokemon (e.g., "bulbasaur").
  final String name;

  /// The URL for the Pokemon's official artwork image.
  /// Defaults to an empty string if not available.
  final String imageUrl;

  /// A list of type names for the Pokemon (e.g., ["grass", "poison"]).
  final List<String> types;

  /// Creates a [Pokemon] instance.
  ///
  /// All parameters are required.
  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
  });

  /// Returns the [name] of the Pokemon with its first letter capitalized.
  ///
  /// Example: "bulbasaur" becomes "Bulbasaur".
  String get capitalizedName {
    return capitalizeFirstLetter(name);
  }

  /// Creates a [Pokemon] instance from a JSON map.
  ///
  /// This factory constructor parses the JSON data, typically from an API response,
  /// to create a [Pokemon] object. It extracts the `id`, `name`, `imageUrl`
  /// (from a nested structure in sprites), and `types`.
  ///
  /// - The `imageUrl` is sourced from `json['sprites']?['other']?['official-artwork']?['front_default']`.
  ///   If this path is not found or the value is null, `imageUrl` defaults to an empty string.
  /// - `types` are extracted from a list of type objects, taking `type['name']`.
  ///
  /// Throws a [TypeError] or similar error if required fields like `id`, `name`,
  /// or `types` are missing or have incorrect types in the JSON map.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      id: json['id'],
      name: json['name'],
      imageUrl:
          json['sprites']?['other']?['official-artwork']?['front_default'] ?? "",
      types: (json['types'] as List)
          .map((t) => t['type']['name'] as String)
          .toList(),
    );
  }
}
