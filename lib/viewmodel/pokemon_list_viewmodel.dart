import 'dart:async';

import 'package:flutter/material.dart';

import '../model/pokemon.dart';
import '../model/pokemon_list.dart';
import '../repository/pokemon_repository.dart';
// New import

/// {@template pokemon_list_viewmodel}
/// ViewModel for managing the state and business logic of the Pokémon list screen.
///
/// It handles fetching the initial list of Pokémon, loading more Pokémon for
/// infinite scrolling, and managing loading and error states.
/// It also provides utility methods for UI display, such as formatting Pokémon IDs.
/// {@endtemplate}
class PokemonListViewModel extends ChangeNotifier {
  final PokemonRepository _repository;

  PokemonList? _pokemonList;

  /// The raw [PokemonList] object containing pagination details and results.
  /// Can be null if no data has been fetched yet.
  PokemonList? get pokemonList => _pokemonList;

  List<Pokemon> _pokemons = [];

  /// The current list of [Pokemon] objects to be displayed.
  List<Pokemon> get pokemons => _pokemons;

  bool _isLoading = false;

  /// Indicates whether the ViewModel is currently fetching data.
  bool get isLoading => _isLoading;

  String? _error;

  /// Holds an error message string if a fetch operation failed, otherwise null.
  String? get error => _error;

  bool _isDisposed = false;

  /// Indicates whether there are more Pokémon to fetch (i.e., if `_pokemonList.next` is not null).
  bool get hasMore => _pokemonList?.next != null;

  /// {@macro pokemon_list_viewmodel}
  ///
  /// An optional [repository] can be provided for dependency injection, primarily
  /// for testing. If not supplied, a default [PokemonRepository] instance is created.
  ///
  /// Automatically triggers [fetchInitialPokemons] upon initialization.
  PokemonListViewModel({PokemonRepository? repository})
    : _repository = repository ?? PokemonRepository() {
    Future.microtask(() => fetchInitialPokemons());
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Notifies listeners only if the ViewModel has not been disposed.
  /// This prevents errors if state changes occur after disposal.
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Fetches the initial list of Pokémon.
  ///
  /// Sets [isLoading] to true and clears any previous [error].
  /// Upon completion, updates [_pokemons] with the fetched results or sets
  /// [_error] if an exception occurs. Finally, sets [isLoading] to false.
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

  /// Fetches the next page of Pokémon if [hasMore] is true and not already loading.
  ///
  /// Sets [isLoading] to true. If successful, appends the new Pokémon to the
  /// existing [_pokemons] list. Sets [_error] if an exception occurs during fetching.
  /// Finally, sets [isLoading] to false.
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

  /// Formats a Pokémon ID into a string with a leading '#' and padded with zeros
  /// to three digits (e.g., 1 becomes "#001").
  ///
  /// [id] The Pokémon ID to format.
  String formatPokemonId(int id) {
    return "#${id.toString().padLeft(3, '0')}";
  }
}
