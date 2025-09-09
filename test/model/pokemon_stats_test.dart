import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/model/pokemon_stats.dart';
import 'package:pokedex/model/general_response.dart';
// The PokemonStats class uses formatHyphenatedName from string_utils.dart.
// Ensure that pokemon_stats.dart has the correct import for it, e.g.:
// import '../utils/string_utils.dart'; or similar path if string_utils is in lib/utils

void main() {
  group('PokemonStats Class Tests', () {
    group('capitalizedStatName Getter', () {
      // Helper to create a PokemonStats instance with a specific stat name
      PokemonStats createPokemonStats(String statName) {
        return PokemonStats(
          baseStat: 50,
          effort: 0,
          stat: GeneralResponse(name: statName, url: 'some-url'),
        );
      }

      test('should format a standard hyphenated stat name correctly', () {
        final pokemonStats = createPokemonStats('special-attack');
        expect(pokemonStats.capitalizedStatName, 'Special Attack');
      });

      test('should format a single-word stat name correctly', () {
        final pokemonStats = createPokemonStats('speed');
        expect(pokemonStats.capitalizedStatName, 'Speed');
      });

      test('should return an empty string if the stat name is empty', () {
        final pokemonStats = createPokemonStats('');
        expect(pokemonStats.capitalizedStatName, '');
      });

      test('should format stat names with multiple hyphens correctly', () {
        final pokemonStats = createPokemonStats('super-duper-special-defense');
        expect(pokemonStats.capitalizedStatName, 'Super Duper Special Defense');
      });

      test('should handle stat names with leading/trailing hyphens (split behavior)', () {
        final statsLeading = createPokemonStats('-hp');
        expect(statsLeading.capitalizedStatName, ' Hp'); // Leading space due to split

        final statsTrailing = createPokemonStats('attack-');
        expect(statsTrailing.capitalizedStatName, 'Attack '); // Trailing space

        final statsBoth = createPokemonStats('-defense-');
        expect(statsBoth.capitalizedStatName, ' Defense '); // Leading and trailing
      });

      test('should handle stat names with consecutive hyphens (split behavior)', () {
        final pokemonStats = createPokemonStats('speed--boost');
        expect(pokemonStats.capitalizedStatName, 'Speed  Boost'); // Double space
      });

      test('should format stat names with numbers correctly', () {
        final pokemonStats = createPokemonStats('attack-x2');
        expect(pokemonStats.capitalizedStatName, 'Attack X2');
      });

      test('should handle stat names that are already capitalized (no change in words)', () {
        // formatHyphenatedName calls capitalizeFirstLetter on each part.
        // If a part is "Attack", capitalizeFirstLetter("Attack") is "Attack".
        final pokemonStats = createPokemonStats('Special-Attack');
        expect(pokemonStats.capitalizedStatName, 'Special Attack');
      });

       test('should handle all uppercase stat names', () {
        // capitalizeFirstLetter("HP") is "HP"
        final pokemonStats = createPokemonStats('HP');
        expect(pokemonStats.capitalizedStatName, 'HP');

        final pokemonStatsHyphen = createPokemonStats('SPECIAL-DEFENSE');
        expect(pokemonStatsHyphen.capitalizedStatName, 'SPECIAL DEFENSE');
      });
    });

    // TODO: Add tests for PokemonStats.fromJson factory if not covered elsewhere.
  });
}
