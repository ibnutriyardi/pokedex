import 'package:pokedex/model/pokemon.dart';

class PokemonList {
  final int count;
  final String? next;
  final List<Pokemon> results;

  PokemonList({required this.count, required this.next, required this.results});
}
