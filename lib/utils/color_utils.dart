import 'package:flutter/material.dart';

/// Returns a [Color] associated with the given Pokémon [type].
///
/// [type] should be a string representing the Pokémon type (e.g., "grass", "fire").
/// If the type is null or not recognized, a default grey color is returned.
Color getPokemonTypeColor(String? type) {
  if (type == null) return Colors.grey.shade400;
  switch (type.toLowerCase()) {
    case 'grass':
      return const Color(0xFF78C850);
    case 'fire':
      return const Color(0xFFF08030);
    case 'water':
      return const Color(0xFF6890F0);
    case 'bug':
      return const Color(0xFFA8B820);
    case 'normal':
      return const Color(0xFFA8A878);
    case 'poison':
      return const Color(0xFFA040A0);
    case 'electric':
      return const Color(0xFFF8D030);
    case 'ground':
      return const Color(0xFFE0C068);
    case 'fairy':
      return const Color(0xFFEE99AC);
    case 'fighting':
      return const Color(0xFFC03028);
    case 'psychic':
      return const Color(0xFFF85888);
    case 'rock':
      return const Color(0xFFB8A038);
    case 'ghost':
      return const Color(0xFF705898);
    case 'ice':
      return const Color(0xFF98D8D8);
    case 'dragon':
      return const Color(0xFF7038F8);
    case 'dark':
      return const Color(0xFF705848);
    case 'steel':
      return const Color(0xFFB8B8D0);
    case 'flying':
      return const Color(0xFFA890F0);
    default:
      return Colors.grey.shade400;
  }
}
