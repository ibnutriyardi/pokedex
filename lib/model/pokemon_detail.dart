import '../utils/string_utils.dart';

class PokemonDetail {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final double height;
  final double weight;
  final List<String> abilities;
  final List<Stat> stats;
  final String description;
  final String? evolutionChainUrl;
  final int baseExperience;
  final List<PokemonMove> moves;

  double get displayHeight => height / 10;

  double get displayWeight => weight / 10;

  String get formattedId => "#${id.toString().padLeft(3, '0')}";

  String get capitalizedName {
    return capitalizeFirstLetter(name);
  }

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

  factory PokemonDetail.fromJson(
    Map<String, dynamic> json, {
    required String description,
    String? evolutionChainUrl,
  }) {
    return PokemonDetail(
      id: json['id'],
      name: json['name'],
      imageUrl:
          json['sprites']?['other']?['official-artwork']?['front_default'] ??
          json['sprites']?['front_default'] ??
          "",
      types: (json['types'] as List)
          .map((typeInfo) => typeInfo['type']['name'] as String)
          .toList(),
      height: (json['height'] as int).toDouble(),
      weight: (json['weight'] as int).toDouble(),
      abilities: (json['abilities'] as List)
          .map((abilityInfo) => abilityInfo['ability']['name'] as String)
          .map((name) => formatHyphenatedName(name))
          .toList(),
      stats: (json['stats'] as List)
          .map((statInfo) => Stat.fromJson(statInfo))
          .toList(),
      description: description,
      evolutionChainUrl: evolutionChainUrl,
      baseExperience: json['base_experience'] ?? 0,
      moves: (json['moves'] as List? ?? [])
          .map((moveInfo) => PokemonMove.fromJson(moveInfo['move']))
          .toList(),
    );
  }
}

class Stat {
  final String name;
  final int baseStat;
  final int effort;

  String get capitalizedName {
    return formatHyphenatedName(name);
  }

  Stat({required this.name, required this.baseStat, required this.effort});

  factory Stat.fromJson(Map<String, dynamic> json) {
    return Stat(
      name: json['stat']['name'],
      baseStat: json['base_stat'],
      effort: json['effort'],
    );
  }
}

class PokemonMove {
  final String name;

  String get formattedName {
    return formatHyphenatedName(name);
  }

  PokemonMove({required this.name});

  factory PokemonMove.fromJson(Map<String, dynamic> json) {
    return PokemonMove(name: json['name'] as String);
  }
}
