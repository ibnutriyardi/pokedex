import '../utils/string_utils.dart';

/// Represents a stage in a Pokemon's evolution chain.
///
/// This class is recursive, as a Pokemon evolution stage (`PokemonEvolution`)
/// can evolve into further stages (a list of `PokemonEvolution` objects).
class PokemonEvolution {
  /// The name of the Pokemon species at this evolution stage (e.g., "bulbasaur").
  final String speciesName;

  /// A list of [PokemonEvolution] objects representing the next possible
  /// evolutions from this stage.
  ///
  /// This list will be empty if this stage is a final evolution.
  final List<PokemonEvolution> evolvesTo;

  /// Returns the [speciesName] with its first letter capitalized.
  /// (e.g., "bulbasaur" becomes "Bulbasaur").
  String get capitalizedSpeciesName {
    return capitalizeFirstLetter(speciesName);
  }

  /// Creates a [PokemonEvolution] instance.
  ///
  /// Requires [speciesName] and a list of next evolutions [evolvesTo].
  PokemonEvolution({required this.speciesName, required this.evolvesTo});

  /// Creates a [PokemonEvolution] instance from a JSON map.
  ///
  /// This factory constructor parses JSON data from an API response.
  /// - `speciesName` is extracted from `json['species']['name']`.
  /// - `evolvesTo` is populated by recursively calling `PokemonEvolution.fromJson`
  ///   for each item in the `json['evolves_to']` list. If `json['evolves_to']`
  ///   is null or not present, `evolvesTo` will be an empty list.
  ///
  /// Throws a [TypeError] or similar if required fields (like `json['species']` or
  /// `json['species']['name']`) are missing or have incorrect types.
  factory PokemonEvolution.fromJson(Map<String, dynamic> json) {
    List<PokemonEvolution> nextEvolutions = [];
    if (json['evolves_to'] != null) {
      nextEvolutions = (json['evolves_to'] as List)
          .map((evolutionJson) => PokemonEvolution.fromJson(evolutionJson))
          .toList();
    }

    return PokemonEvolution(
      speciesName: json['species']['name'],
      evolvesTo: nextEvolutions,
    );
  }
}
