import 'dart:async';

import 'package:flutter/material.dart';

import '../model/pokemon.dart';
import '../model/pokemon_list.dart';
import '../repository/pokemon_repository.dart';

class PokemonListViewModel extends ChangeNotifier {
  final PokemonRepository _repository;

  PokemonList? _pokemonList;

  PokemonList? get pokemonList => _pokemonList;

  List<Pokemon> _pokemons = [];

  List<Pokemon> get pokemons => _pokemons;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _error;

  String? get error => _error;

  bool _isDisposed = false;

  bool get hasMore => _pokemonList?.next != null;

  PokemonListViewModel({PokemonRepository? repository})
    : _repository = repository ?? PokemonRepository() {
    Future.microtask(() => fetchInitialPokemons());
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> fetchInitialPokemons() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _pokemonList = await _repository.fetchPokemons(limit: 20, nextUrl: null);
      _pokemons = _pokemonList?.results ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> fetchMorePokemons() async {
    if (_isLoading || !hasMore || _isDisposed) return;

    _isLoading = true;
    _safeNotifyListeners();

    try {
      final nextPageUrl = _pokemonList?.next;
      if (nextPageUrl != null) {
        PokemonList newPokemonList = await _repository.fetchPokemons(
          nextUrl: nextPageUrl,
        );
        _pokemonList = newPokemonList;
        _pokemons.addAll(newPokemonList.results);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

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
      case 'flying': // Added missing case
        return const Color(0xFFA890F0);
      default:
        return Colors.grey.shade400;
    }
  }

  String formatPokemonId(int id) {
    return "#${id.toString().padLeft(3, '0')}";
  }
}
