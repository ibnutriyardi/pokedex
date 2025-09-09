import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/model/pokemon_evolution.dart';
// The PokemonEvolution class uses capitalizeFirstLetter from string_utils.dart.
// Ensure that pokemon_evolution.dart has the correct import for it, e.g.:
// import 'package:pokedex/utils/string_utils.dart';

void main() {
  group('PokemonEvolution Class Tests', () {
    group('capitalizedSpeciesName Getter', () {
      test('should capitalize the first letter of a lowercase species name', () {
        final evolution = PokemonEvolution(speciesName: 'bulbasaur', evolvesTo: []);
        expect(evolution.capitalizedSpeciesName, 'Bulbasaur');
      });

      test('should return an already capitalized species name as is', () {
        final evolution = PokemonEvolution(speciesName: 'Pikachu', evolvesTo: []);
        expect(evolution.capitalizedSpeciesName, 'Pikachu');
      });

      test('should return an empty string if speciesName is empty', () {
        final evolution = PokemonEvolution(speciesName: '', evolvesTo: []);
        expect(evolution.capitalizedSpeciesName, '');
      });

      test('should capitalize only the first letter of a hyphenated species name', () {
        // Based on typical capitalizeFirstLetter behavior which targets the string's start.
        final evolution = PokemonEvolution(speciesName: 'mr-mime', evolvesTo: []);
        expect(evolution.capitalizedSpeciesName, 'Mr-mime');
      });

      test('should handle species names starting with non-letters correctly', () {
        // Example: if capitalizeFirstLetter only affects `^[a-z]`
        final evolutionNonLetter = PokemonEvolution(speciesName: '7sins', evolvesTo: []);
        expect(evolutionNonLetter.capitalizedSpeciesName, '7sins'); // Assuming no change

        final evolutionSpecialChar = PokemonEvolution(speciesName: '-charizard', evolvesTo: []);
        expect(evolutionSpecialChar.capitalizedSpeciesName, '-charizard'); // Assuming no change
      });

      test('should handle species names with numbers correctly', () {
        final evolution = PokemonEvolution(speciesName: 'porygon2', evolvesTo: []);
        expect(evolution.capitalizedSpeciesName, 'Porygon2');
      });

      test('should handle single-letter lowercase species name', () {
        final evolution = PokemonEvolution(speciesName: 'a', evolvesTo: []);
        expect(evolution.capitalizedSpeciesName, 'A');
      });

      test('should handle single-letter uppercase species name', () {
        final evolution = PokemonEvolution(speciesName: 'Z', evolvesTo: []);
        expect(evolution.capitalizedSpeciesName, 'Z');
      });
    });

    // TODO: Add tests for PokemonEvolution.fromJson factory if not covered elsewhere.
    // TODO: Add tests for 'evolvesTo' logic if complex.
  });
}
