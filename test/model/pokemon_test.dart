import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/model/pokemon.dart';
// Assuming capitalizeFirstLetter is in string_utils.dart and string_utils.dart is in lib/utils
// If your string_utils.dart is elsewhere, you might need to adjust the import.
// For this test, we'll mock its behavior if it were complex, 
// but since it's a simple utility, we'll rely on its actual implementation 
// if it's easily accessible and doesn't have external dependencies itself.
// For now, let's assume capitalizeFirstLetter is part of the testable scope or well-defined.

// A simple reimplementation or mock for capitalizeFirstLetter if not directly importable 
// or if we want to isolate the Pokemon class logic strictly.
// However, usually, you'd import the actual utility.
// For this example, let's assume the real one from your project works as expected.
// If string_utils.dart was available to me, I'd import it.
// Since it's not, I have to simulate its effect for the test.

// Let's assume your actual capitalizeFirstLetter function from
// '../utils/string_utils.dart' would be imported and used like this:
// import 'package:pokedex/utils/string_utils.dart'; 
// For the purpose of this isolated test generation, I'll define a simple one here
// if direct import isn't feasible for the tool environment, but in your project, use the real import.

String _testCapitalizeFirstLetter(String text) {
  if (text.isEmpty) return "";
  return '${text[0].toUpperCase()}${text.substring(1)}';
}


void main() {
  group('Pokemon Class Tests', () {
    group('capitalizedName Getter', () {
      test('should return name with first letter capitalized for lowercase name', () {
        final pokemon = Pokemon(
          id: 1,
          name: 'bulbasaur',
          imageUrl: 'url',
          types: ['grass', 'poison'],
        );
        // Assuming capitalizeFirstLetter from your utils works like _testCapitalizeFirstLetter
        expect(pokemon.capitalizedName, 'Bulbasaur');
      });

      test('should return name as is if already capitalized', () {
        final pokemon = Pokemon(
          id: 25,
          name: 'Pikachu',
          imageUrl: 'url',
          types: ['electric'],
        );
        expect(pokemon.capitalizedName, 'Pikachu');
      });

      test('should return an empty string if name is empty', () {
        final pokemon = Pokemon(
          id: 0,
          name: '',
          imageUrl: 'url',
          types: [],
        );
        expect(pokemon.capitalizedName, '');
      });

      test('should handle single character name', () {
        final pokemon = Pokemon(
          id: 100,
          name: 'a',
          imageUrl: 'url',
          types: ['normal'],
        );
        expect(pokemon.capitalizedName, 'A');
      });

      test('should handle name with leading/trailing spaces correctly (behavior depends on capitalizeFirstLetter)', () {
        // This test's outcome depends on how your actual capitalizeFirstLetter handles spaces.
        // If it trims, then expected would be "TrimmedName". If not, " TrimmedName".
        // The Pokemon.name itself stores " trimmed name ".
        final pokemon = Pokemon(
          id: 101,
          name: '  charmander  ',
          imageUrl: 'url',
          types: ['fire'],
        );
        // Based on typical capitalizeFirstLetter, it might not trim implicitly.
        // If your capitalizeFirstLetter function is `(text) => text[0].toUpperCase() + text.substring(1)`
        // then "  charmander  " becomes "  charmander  " because space is not a letter.
        // If it was smarter and trimmed first, it would be "Charmander".
        // The current test uses a basic _testCapitalizeFirstLetter which won't trim.
        // So, "  charmander  " -> "  charmander  " (first char is space)
        // Or, if your capitalizeFirstLetter targets the first *letter*:
        // For this test, let's assume capitalizeFirstLetter operates on the first character directly.
        // If name is "  charmander  ", capitalizeFirstLetter("  charmander  ") could be "  charmander  "
        // or if it finds the first actual letter, it might be "  Charmander  ".
        // Let's rely on the simple _testCapitalizeFirstLetter behavior defined above for this example.
        // This test would be more robust if we could directly use your project's string_utils.dart
        
        // Simulating a capitalizeFirstLetter that operates on the first char of the string given:
        // If name is "  char...", name[0] is ' '.toUpperCase() is ' '. name.substring(1) is " charm...".
        // So the result would be " charmander  ".
        // If your util function trims the string first, then does toUpperCase(), the result would be "Charmander".
        // We should test based on the actual behavior of *your* `capitalizeFirstLetter`.
        // Given the import `import '../utils/string_utils.dart';`
        // and `return capitalizeFirstLetter(name);`
        // it is implied that the test for `capitalizeFirstLetter` utility function itself should cover trimming cases.
        // Here, we just test that `Pokemon.capitalizedName` passes its `name` to this function.

        // If `capitalizeFirstLetter` is simple like `text[0].toUpperCase() + text.substring(1)`:
        expect(_testCapitalizeFirstLetter('  charmander  '), '  charmander  '); // as ' '.toUpperCase() is ' '
        // Therefore, pokemon.capitalizedName would also be '  charmander  '
        expect(pokemon.capitalizedName, '  charmander  '); 
      });
    });

    // You can add more tests for Pokemon.fromJson if needed, for example:
    group('Pokemon.fromJson Factory', () {
      test('should correctly parse valid JSON', () {
        final json = {
          'id': 1,
          'name': 'bulbasaur',
          'sprites': {
            'other': {
              'official-artwork': {
                'front_default': 'http://example.com/bulbasaur.png'
              }
            }
          },
          'types': [
            {'type': {'name': 'grass'}},
            {'type': {'name': 'poison'}}
          ]
        };
        final pokemon = Pokemon.fromJson(json);
        expect(pokemon.id, 1);
        expect(pokemon.name, 'bulbasaur');
        expect(pokemon.imageUrl, 'http://example.com/bulbasaur.png');
        expect(pokemon.types, containsAll(['grass', 'poison']));
      });

      test('should handle missing optional imageUrl with empty string', () {
        final json = {
          'id': 2,
          'name': 'ivysaur',
          // imageUrl is missing
          'types': [
            {'type': {'name': 'grass'}},
            {'type': {'name': 'poison'}}
          ]
        };
        final pokemon = Pokemon.fromJson(json);
        expect(pokemon.id, 2);
        expect(pokemon.name, 'ivysaur');
        expect(pokemon.imageUrl, ''); // Expecting default empty string
        expect(pokemon.types, containsAll(['grass', 'poison']));
      });

       test('should handle null optional imageUrl with empty string', () {
        final json = {
          'id': 3,
          'name': 'venusaur',
          'sprites': {
            'other': {
              'official-artwork': {
                'front_default': null // imageUrl is null
              }
            }
          },
          'types': [
            {'type': {'name': 'grass'}},
            {'type': {'name': 'poison'}}
          ]
        };
        final pokemon = Pokemon.fromJson(json);
        expect(pokemon.id, 3);
        expect(pokemon.name, 'venusaur');
        expect(pokemon.imageUrl, ''); // Expecting default empty string
        expect(pokemon.types, containsAll(['grass', 'poison']));
      });

      test('should throw TypeError if required fields are missing or wrong type', () {
        final incompleteJson = {
          'name': 'Missing ID',
          'types': []
        };
        expect(() => Pokemon.fromJson(incompleteJson), throwsA(isA<TypeError>()));

        final wrongTypeJson = {
          'id': 'not-an-int',
          'name': 'Wrong Type ID',
          'types': []
        };
        expect(() => Pokemon.fromJson(wrongTypeJson), throwsA(isA<TypeError>()));
      });
    });
  });
}
