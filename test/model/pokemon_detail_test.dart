import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/model/pokemon_detail.dart';
import 'package:pokedex/model/pokemon_stats.dart';

// Helper function to create a PokemonDetail instance with minimal required fields for testing specific getters.
PokemonDetail _createPokemonDetailObject({
  required int id,
  required String name,
  required double height,
  double weight = 100.0,
  String imageUrl = 'http://example.com/image.png',
  List<String> types = const ['normal'],
  List<String> abilities = const ['ability1'],
  List<PokemonStats> stats = const [],
  String description = 'Test description',
  String? evolutionChainUrl,
  int baseExperience = 64,
  List<PokemonMove> moves = const [],
}) {
  return PokemonDetail(
    id: id,
    name: name,
    imageUrl: imageUrl,
    types: types,
    height: height,
    weight: weight,
    abilities: abilities,
    stats: stats,
    description: description,
    evolutionChainUrl: evolutionChainUrl,
    baseExperience: baseExperience,
    moves: moves,
  );
}

// Base JSON helper for fromJson tests - can be overridden in specific tests
Map<String, dynamic> _createPokemonDetailBaseJson({
  dynamic id = 1,
  dynamic name = 'Pikachu',
  Map<String, dynamic>? sprites = const {
    'other': {
      'official-artwork': {'front_default': 'official.png'},
    },
    'front_default': 'fallback.png',
  },
  dynamic types = const [
    {
      'type': {'name': 'electric'},
    },
  ],
  dynamic height = 4,
  dynamic weight = 60,
  dynamic abilities = const [
    {
      'ability': {'name': 'static'},
    },
    {
      'ability': {'name': 'lightning-rod'},
    },
  ],
  dynamic stats = const [
    {
      'base_stat': 35,
      'effort': 0,
      'stat': {'name': 'hp', 'url': 'hp-url'},
    },
  ],
  dynamic baseExperience = 112,
  dynamic moves = const [
    {
      'move': {'name': 'thunder-shock'},
    },
  ],
}) {
  return {
    if (id != null) 'id': id,
    if (name != null) 'name': name,
    if (sprites != null) 'sprites': sprites,
    if (types != null) 'types': types,
    if (height != null) 'height': height,
    if (weight != null) 'weight': weight,
    if (abilities != null) 'abilities': abilities,
    if (stats != null) 'stats': stats,
    if (baseExperience != null) 'base_experience': baseExperience,
    if (moves != null) 'moves': moves,
  };
}

void main() {
  const double defaultDelta =
      0.00001; // Increased delta for floating point comparisons

  group('PokemonDetail Class Tests', () {
    group('displayHeight Getter', () {
      test('should return correct displayHeight for a given height', () {
        final pokemonDetail = _createPokemonDetailObject(
          id: 1,
          name: 'Testmon',
          height: 7.0,
        );
        expect(pokemonDetail.displayHeight, closeTo(0.7, defaultDelta));
      });
    });

    group('displayWeight Getter', () {
      test('should return correct displayWeight for a given weight', () {
        final pokemonDetail = _createPokemonDetailObject(
          id: 1,
          name: 'Testmon',
          height: 10.0,
          weight: 69.0,
        );
        expect(pokemonDetail.displayWeight, closeTo(6.9, defaultDelta));
      });
    });

    group('formattedId Getter', () {
      test(
        'should return ID with # and padded to three digits for ID < 10',
        () {
          final pokemonDetail = _createPokemonDetailObject(
            id: 7,
            name: 'TestSeven',
            height: 10.0,
          );
          expect(pokemonDetail.formattedId, '#007');
        },
      );
    });

    group('capitalizedName Getter', () {
      test('should return name with first letter capitalized', () {
        final detail = _createPokemonDetailObject(
          id: 1,
          name: "bulbasaur",
          height: 7.0,
        );
        expect(detail.capitalizedName, "Bulbasaur");
      });
    });

    group('PokemonDetail.fromJson Factory', () {
      const String defaultDescription = 'A test description.';
      const String defaultEvolutionUrl = 'evolution/chain/1';

      test('should parse all fields correctly with valid full JSON', () {
        final json = _createPokemonDetailBaseJson();
        final detail = PokemonDetail.fromJson(
          json,
          description: defaultDescription,
          evolutionChainUrl: defaultEvolutionUrl,
        );

        expect(detail.id, 1);
        expect(detail.name, 'Pikachu');
        expect(detail.imageUrl, 'official.png');
        expect(detail.types, ['electric']);
        expect(detail.height, 4.0);
        expect(detail.weight, 60.0);
        expect(detail.abilities, ['Static', 'Lightning Rod']);
        expect(detail.stats.length, 1);
        expect(detail.stats[0].baseStat, 35);
        expect(detail.stats[0].stat.name, 'hp');
        expect(detail.description, defaultDescription);
        expect(detail.evolutionChainUrl, defaultEvolutionUrl);
        expect(detail.baseExperience, 112);
        expect(detail.moves.length, 1);
        expect(detail.moves[0].name, 'thunder-shock');
      });

      group('id field', () {
        test('should throw TypeError if id is null (due to cast error)', () {
          final json = _createPokemonDetailBaseJson();
          (json as Map).remove('id'); // Make id truly null by removing its key
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<TypeError>()),
          );
        });
        test('should throw TypeError if id is not an int', () {
          final json = _createPokemonDetailBaseJson(id: 'not-an-int');
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<TypeError>()),
          );
        });
      });

      group('name field', () {
        test('should default to empty string if name is null', () {
          final json = _createPokemonDetailBaseJson(name: null);
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.name, '');
        });
        test('should throw TypeError if name is not a String', () {
          final json = _createPokemonDetailBaseJson(name: 123);
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<TypeError>()),
          );
        });
      });

      group('imageUrl field', () {
        test('should use official-artwork if available', () {
          final json = _createPokemonDetailBaseJson(
            sprites: {
              'other': {
                'official-artwork': {'front_default': 'official.png'},
              },
              'front_default': 'fallback.png',
            },
          );
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.imageUrl, 'official.png');
        });

        test('should use front_default if official-artwork is null', () {
          final json = _createPokemonDetailBaseJson(
            sprites: {
              'other': {
                'official-artwork': {'front_default': null},
              },
              'front_default': 'fallback.png',
            },
          );
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.imageUrl, 'fallback.png');
        });

        test(
          'should use front_default if official-artwork path is missing',
          () {
            final json = _createPokemonDetailBaseJson(
              sprites: {'other': {}, 'front_default': 'fallback.png'},
            );
            final detail = PokemonDetail.fromJson(
              json,
              description: defaultDescription,
            );
            expect(detail.imageUrl, 'fallback.png');
          },
        );

        test("should use front_default if 'other' path is missing", () {
          final json = _createPokemonDetailBaseJson(
            sprites: {'front_default': 'fallback.png'},
          );
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.imageUrl, 'fallback.png');
        });

        test(
          'should default to empty string if all image paths are null or missing',
          () {
            final json1 = _createPokemonDetailBaseJson(
              sprites: {
                'other': {
                  'official-artwork': {'front_default': null},
                },
                'front_default': null,
              },
            );
            final detail1 = PokemonDetail.fromJson(
              json1,
              description: defaultDescription,
            );
            expect(detail1.imageUrl, '');

            final json2 = _createPokemonDetailBaseJson(sprites: {});
            final detail2 = PokemonDetail.fromJson(
              json2,
              description: defaultDescription,
            );
            expect(detail2.imageUrl, '');

            final json3 = _createPokemonDetailBaseJson(sprites: null);
            final detail3 = PokemonDetail.fromJson(
              json3,
              description: defaultDescription,
            );
            expect(detail3.imageUrl, '');
          },
        );
      });

      group('types field', () {
        test('should default to empty list if types is null', () {
          final json = _createPokemonDetailBaseJson(types: null);
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.types, isEmpty);
        });
        test('should throw TypeError if types is not a List', () {
          final json = _createPokemonDetailBaseJson(types: 'not-a-list');
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<TypeError>()),
          );
        });
        test(
          'should default type name to empty string if typeInfo.type.name is null',
          () {
            final json = _createPokemonDetailBaseJson(
              types: [
                {
                  'type': {'name': null},
                },
              ],
            );
            final detail = PokemonDetail.fromJson(
              json,
              description: defaultDescription,
            );
            expect(detail.types, ['']);
          },
        );
        test(
          'should default type name to empty string if typeInfo.type is null',
          () {
            final json = _createPokemonDetailBaseJson(
              types: [
                {'type': null},
              ],
            );
            final detail = PokemonDetail.fromJson(
              json,
              description: defaultDescription,
            );
            expect(detail.types, ['']);
          },
        );
        test('should throw Error if typeInfo is not a Map', () {
          final json = _createPokemonDetailBaseJson(types: ['not-a-map']);
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<Error>()),
          );
        });
        test(
          'should throw TypeError if typeInfo.type.name is not a String',
          () {
            final json = _createPokemonDetailBaseJson(
              types: [
                {
                  'type': {'name': 123},
                },
              ],
            );
            expect(
              () =>
                  PokemonDetail.fromJson(json, description: defaultDescription),
              throwsA(isA<TypeError>()),
            );
          },
        );
      });

      group('height field', () {
        test('should default to 0.0 if height is null', () {
          final json = _createPokemonDetailBaseJson(height: null);
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.height, 0.0);
        });
        test('should throw TypeError if height is not a num', () {
          final json = _createPokemonDetailBaseJson(height: 'not-a-num');
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<TypeError>()),
          );
        });
      });

      group('weight field', () {
        test('should default to 0.0 if weight is null', () {
          final json = _createPokemonDetailBaseJson(weight: null);
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.weight, 0.0);
        });
        test('should throw TypeError if weight is not a num', () {
          final json = _createPokemonDetailBaseJson(weight: 'not-a-num');
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<TypeError>()),
          );
        });
      });

      group('abilities field', () {
        test('should default to empty list if abilities is null', () {
          final json = _createPokemonDetailBaseJson(abilities: null);
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.abilities, isEmpty);
        });
        test('should throw TypeError if abilities is not a List', () {
          final json = _createPokemonDetailBaseJson(abilities: 'not-a-list');
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<TypeError>()),
          );
        });
        test(
          'should correctly format ability names including if abilityInfo.ability.name is null',
          () {
            final json = _createPokemonDetailBaseJson(
              abilities: [
                {
                  'ability': {'name': null},
                },
              ],
            );
            final detail = PokemonDetail.fromJson(
              json,
              description: defaultDescription,
            );
            expect(detail.abilities, ['']);
          },
        );
        test(
          'should correctly format ability names including if abilityInfo.ability is null',
          () {
            final json = _createPokemonDetailBaseJson(
              abilities: [
                {'ability': null},
              ],
            );
            final detail = PokemonDetail.fromJson(
              json,
              description: defaultDescription,
            );
            expect(detail.abilities, ['']);
          },
        );
        test('should throw Error if abilityInfo is not a Map', () {
          final json = _createPokemonDetailBaseJson(abilities: ['not-a-map']);
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<Error>()),
          );
        });
        test(
          'should throw TypeError if abilityInfo.ability.name is not a String',
          () {
            final json = _createPokemonDetailBaseJson(
              abilities: [
                {
                  'ability': {'name': 123},
                },
              ],
            );
            expect(
              () =>
                  PokemonDetail.fromJson(json, description: defaultDescription),
              throwsA(isA<TypeError>()),
            );
          },
        );
      });

      group('stats field', () {
        test('should default to empty list if stats is null', () {
          final json = _createPokemonDetailBaseJson(stats: null);
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.stats, isEmpty);
        });
        test('should throw TypeError if stats is not a List', () {
          final json = _createPokemonDetailBaseJson(stats: 'not-a-list');
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<TypeError>()),
          );
        });
        test('should throw TypeError if statInfo is not a Map', () {
          final json = _createPokemonDetailBaseJson(stats: ['not-a-map']);
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<TypeError>()),
          );
        });
        test(
          'should throw TypeError if PokemonStats.fromJson receives incompatible type',
          () {
            final json = _createPokemonDetailBaseJson(
              stats: [
                {'base_stat': 'not-an-int'},
              ],
            );
            expect(
              () =>
                  PokemonDetail.fromJson(json, description: defaultDescription),
              throwsA(isA<TypeError>()),
            );
          },
        );
      });

      group('baseExperience field', () {
        test('should default to 0 if base_experience is null', () {
          final json = _createPokemonDetailBaseJson(baseExperience: null);
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.baseExperience, 0);
        });
        test('should throw TypeError if base_experience is not an int', () {
          final json = _createPokemonDetailBaseJson(
            baseExperience: 'not-an-int',
          );
          expect(
            () => PokemonDetail.fromJson(json, description: defaultDescription),
            throwsA(isA<TypeError>()),
          );
        });
      });

      group('description and evolutionChainUrl fields', () {
        test(
          'should correctly pass through description and evolutionChainUrl',
          () {
            final json = _createPokemonDetailBaseJson();
            final detail = PokemonDetail.fromJson(
              json,
              description: "Custom Desc",
              evolutionChainUrl: "custom/url",
            );
            expect(detail.description, "Custom Desc");
            expect(detail.evolutionChainUrl, "custom/url");
          },
        );
        test('should handle null evolutionChainUrl', () {
          final json = _createPokemonDetailBaseJson();
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
            evolutionChainUrl: null,
          );
          expect(detail.evolutionChainUrl, isNull);
        });
      });

      // --- Existing moves parsing tests ---
      group('moves parsing', () {
        test('should parse valid list of moves', () {
          final json = _createPokemonDetailBaseJson(
            moves: [
              {
                'move': {'name': 'tackle'},
              },
              {
                'move': {'name': 'growl'},
              },
            ],
          );
          final detail = PokemonDetail.fromJson(
            json,
            description: defaultDescription,
          );
          expect(detail.moves.length, 2);
          expect(detail.moves[0].name, 'tackle');
          expect(detail.moves[1].name, 'growl');
        });

        test(
          "should result in an empty list if json field 'moves' is an empty list",
          () {
            final json = _createPokemonDetailBaseJson(moves: []);
            final detail = PokemonDetail.fromJson(
              json,
              description: defaultDescription,
            );
            expect(detail.moves, isEmpty);
          },
        );

        test(
          "should result in an empty list if json field 'moves' is null (not present)",
          () {
            final jsonWithNoMoves = _createPokemonDetailBaseJson();
            (jsonWithNoMoves as Map).remove(
              'moves',
            ); // Ensure moves is truly absent
            final detail = PokemonDetail.fromJson(
              jsonWithNoMoves,
              description: defaultDescription,
            );
            expect(detail.moves, isEmpty);
          },
        );

        test(
          "should throw TypeError if json field 'moves' is not a List type (e.g., a String)",
          () {
            final json = _createPokemonDetailBaseJson(
              moves: 'this-is-not-a-list',
            );
            expect(
              () =>
                  PokemonDetail.fromJson(json, description: defaultDescription),
              throwsA(isA<TypeError>()),
            );
          },
        );

        test(
          'should handle moveInfo map not containing a \'move\' key with default empty PokemonMove',
          () {
            final json = _createPokemonDetailBaseJson(
              moves: [
                {'irrelevant_key': 'some_data'},
              ],
            );
            final detail = PokemonDetail.fromJson(
              json,
              description: defaultDescription,
            );
            expect(detail.moves.length, 1);
            expect(detail.moves[0].name, '');
          },
        );

        test(
          "should handle moveInfo field 'move' being null with default empty PokemonMove",
          () {
            final json = _createPokemonDetailBaseJson(
              moves: [
                {'move': null},
              ],
            );
            final detail = PokemonDetail.fromJson(
              json,
              description: defaultDescription,
            );
            expect(detail.moves.length, 1);
            expect(detail.moves[0].name, '');
          },
        );

        test(
          "should throw TypeError if moveInfo field 'move' is not a map",
          () {
            final json = _createPokemonDetailBaseJson(
              moves: [
                {'move': 'not-a-map'},
              ],
            );
            expect(
              () =>
                  PokemonDetail.fromJson(json, description: defaultDescription),
              throwsA(isA<TypeError>()),
            );
          },
        );

        test(
          'should throw Error if an item in moves list is not a Map (e.g., a String)',
          () {
            final jsonWithInvalidMoveItemType = _createPokemonDetailBaseJson(
              moves: [
                {
                  'move': {'name': 'valid-move'},
                },
                'not-a-map-item-itself',
              ],
            );
            expect(
              () => PokemonDetail.fromJson(
                jsonWithInvalidMoveItemType,
                description: defaultDescription,
              ),
              throwsA(isA<Error>()),
            );
          },
        );

        test(
          'should throw TypeError if PokemonMove.fromJson receives name that is not a string',
          () {
            final json = _createPokemonDetailBaseJson(
              moves: [
                {
                  'move': {'name': 123}, // name is int, not string
                },
              ],
            );
            expect(
              () =>
                  PokemonDetail.fromJson(json, description: defaultDescription),
              throwsA(isA<TypeError>()),
            );
          },
        );
      });
    }); // End PokemonDetail.fromJson Factory group
  }); // End PokemonDetail Class Tests group

  group('PokemonMove Class Tests', () {
    group('formattedName Getter', () {
      test('should format a standard hyphenated name correctly', () {
        final move = PokemonMove(name: 'thunder-shock');
        expect(move.formattedName, 'Thunder Shock');
      });

      test(
        'should format a single-word name correctly (capitalize first letter)',
        () {
          final move = PokemonMove(name: 'tackle');
          expect(move.formattedName, 'Tackle');
        },
      );

      test('should return an empty string if name is empty', () {
        final move = PokemonMove(name: '');
        expect(move.formattedName, '');
      });

      test('should format names with multiple hyphens correctly', () {
        final move = PokemonMove(name: 'double-edge-attack');
        expect(move.formattedName, 'Double Edge Attack');
      });
    });

    group('PokemonMove.fromJson Factory', () {
      test('should create PokemonMove with correct name from json', () {
        final move = PokemonMove.fromJson({'name': 'flamethrower'});
        expect(move.name, 'flamethrower');
      });

      test('should default to empty string if name is null in json', () {
        final move = PokemonMove.fromJson({'name': null});
        expect(move.name, '');
      });

      test('should default to empty string if json is empty', () {
        final move = PokemonMove.fromJson({});
        expect(move.name, '');
      });

      test('should throw TypeError if name in json is not a string', () {
        expect(
          () => PokemonMove.fromJson({'name': 123}),
          throwsA(isA<TypeError>()),
        );
      });
    });
  });
}
