import '../utils/string_utils.dart';

class PokemonEvolution {
  final String speciesName;
  final List<PokemonEvolution> evolvesTo;

  String get capitalizedSpeciesName {
    return capitalizeFirstLetter(speciesName);
  }

  PokemonEvolution({required this.speciesName, required this.evolvesTo});

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
