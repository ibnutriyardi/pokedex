import 'package:pokedex/model/general_response.dart';
import '../utils/string_utils.dart'; // Added import

/// Represents a specific statistic for a Pokémon, including its base value,
/// effort points, and details about the statistic itself.
class PokemonStats {
  /// The base value of the statistic.
  final int baseStat;

  /// The effort points (EVs) gained for this stat.
  final int effort;

  /// Detailed information about the statistic, including its name and URL,
  /// represented by a [GeneralResponse] object.
  final GeneralResponse stat;

  /// Returns the name of the stat (from [stat.name]), formatted for display
  /// (e.g., "special-attack" becomes "Special Attack").
  String get capitalizedStatName {
    return formatHyphenatedName(stat.name);
  }

  /// Creates a [PokemonStats] instance.
  ///
  /// Requires [baseStat], [effort], and [stat].
  PokemonStats({
    required this.baseStat,
    required this.effort,
    required this.stat,
  });

  /// Creates a [PokemonStats] instance from a JSON map.
  ///
  /// Parses the following fields from the JSON:
  /// - `base_stat` for [baseStat].
  /// - `effort` for [effort].
  /// - `stat` (which is expected to be a JSON object) for [stat],
  ///   using [GeneralResponse.fromJson].
  ///
  /// Throws a [TypeError] or similar if required fields are missing
  /// or have incorrect types in the JSON map.
  factory PokemonStats.fromJson(Map<String, dynamic> json) {
    return PokemonStats(
      baseStat: json['base_stat'] as int,
      effort: json['effort'] as int,
      stat: GeneralResponse.fromJson(json['stat'] as Map<String, dynamic>),
    );
  }
}
