import 'package:pokedex/model/general_response.dart';

class PokemonStats {
  final int baseStat;
  final int effort;
  final GeneralResponse stat;

  PokemonStats({
    required this.baseStat,
    required this.effort,
    required this.stat,
  });
}
