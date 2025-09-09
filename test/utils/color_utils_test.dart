import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/utils/color_utils.dart';

void main() {
  group('getPokemonTypeColor', () {
    test('returns correct color for all known types (lowercase)', () {
      expect(getPokemonTypeColor('grass'), const Color(0xFF78C850));
      expect(getPokemonTypeColor('fire'), const Color(0xFFF08030));
      expect(getPokemonTypeColor('water'), const Color(0xFF6890F0));
      expect(getPokemonTypeColor('bug'), const Color(0xFFA8B820));
      expect(getPokemonTypeColor('normal'), const Color(0xFFA8A878));
      expect(getPokemonTypeColor('poison'), const Color(0xFFA040A0));
      expect(getPokemonTypeColor('electric'), const Color(0xFFF8D030));
      expect(getPokemonTypeColor('ground'), const Color(0xFFE0C068));
      expect(getPokemonTypeColor('fairy'), const Color(0xFFEE99AC));
      expect(getPokemonTypeColor('fighting'), const Color(0xFFC03028));
      expect(getPokemonTypeColor('psychic'), const Color(0xFFF85888));
      expect(getPokemonTypeColor('rock'), const Color(0xFFB8A038));
      expect(getPokemonTypeColor('ghost'), const Color(0xFF705898));
      expect(getPokemonTypeColor('ice'), const Color(0xFF98D8D8));
      expect(getPokemonTypeColor('dragon'), const Color(0xFF7038F8));
      expect(getPokemonTypeColor('dark'), const Color(0xFF705848));
      expect(getPokemonTypeColor('steel'), const Color(0xFFB8B8D0));
      expect(getPokemonTypeColor('flying'), const Color(0xFFA890F0));
    });

    test('returns correct color for known types (mixed case)', () {
      expect(getPokemonTypeColor('Grass'), const Color(0xFF78C850));
      expect(getPokemonTypeColor('FiRe'), const Color(0xFFF08030));
      expect(getPokemonTypeColor('WATER'), const Color(0xFF6890F0));
    });

    test('returns default color for null type', () {
      expect(getPokemonTypeColor(null), Colors.grey.shade400);
    });

    test('returns default color for unknown type', () {
      expect(getPokemonTypeColor('unknown_type'), Colors.grey.shade400);
    });

    test('returns default color for empty string type', () {
      expect(getPokemonTypeColor(''), Colors.grey.shade400);
    });
  });
}
