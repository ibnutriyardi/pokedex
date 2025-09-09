import 'package:flutter/material.dart';

import '../model/pokemon_detail.dart';
import '../model/pokemon_evolution.dart';
import '../repository/pokemon_repository.dart';

/// {@template pokemon_detail_viewmodel}
/// ViewModel for managing the state and business logic of the Pokémon details screen.
///
/// It handles fetching detailed information for a specific Pokémon, including its
/// base stats, abilities, description, and evolution chain. It manages loading
/// and error states for both the main Pokémon details and its evolution data independently.
/// {@endtemplate}
class PokemonDetailViewModel extends ChangeNotifier {
  final PokemonRepository _repository;

  PokemonDetail? _pokemonDetail;

  /// The detailed information of the currently fetched Pokémon.
  /// Null if no data is loaded or an error occurred during the fetch for main details.
  PokemonDetail? get pokemonDetail => _pokemonDetail;

  PokemonEvolution? _pokemonEvolution;

  /// The evolution chain data for the currently fetched Pokémon.
  /// Null if not loaded, if the Pokémon has no evolution data URL, or an error occurred during its fetch.
  PokemonEvolution? get pokemonEvolution => _pokemonEvolution;

  bool _isLoading = false;

  /// Indicates whether the ViewModel is currently fetching the main Pokémon details.
  bool get isLoading => _isLoading;

  String? _error;

  /// Holds an error message string if fetching the main Pokémon details failed, otherwise null.
  String? get error => _error;

  bool _isEvolutionLoading = false;

  /// Indicates whether the ViewModel is currently fetching Pokémon evolution data.
  bool get isEvolutionLoading => _isEvolutionLoading;

  String? _evolutionError;

  /// Holds an error message string if fetching Pokémon evolution data failed, otherwise null.
  String? get evolutionError => _evolutionError;

  int? _currentPokemonIdForFetch;
  bool _isDisposed = false;

  /// {@macro pokemon_detail_viewmodel}
  ///
  /// An optional [repository] can be provided for dependency injection,
  /// primarily for testing. If not supplied, a default [PokemonRepository]
  /// instance is created.
  PokemonDetailViewModel({PokemonRepository? repository})
    : _repository = repository ?? PokemonRepository();

  /// Cleans up resources and marks the ViewModel as disposed.
  ///
  /// Sets [_isDisposed] to true and clears [_currentPokemonIdForFetch]
  /// to prevent further updates or fetches on a disposed ViewModel.
  /// Calls the superclass [dispose] method.
  @override
  void dispose() {
    _isDisposed = true;
    _currentPokemonIdForFetch = null;
    super.dispose();
  }

  /// Notifies listeners only if the ViewModel has not been disposed.
  /// This prevents errors that might occur if state changes are attempted
  /// after the ViewModel has been disposed.
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Fetches detailed information for the Pokémon with the given [pokemonId].
  ///
  /// This method manages the overall loading state for main details and orchestrates
  /// fetching both the Pokémon details and, subsequently, its evolution chain data
  /// via [_fetchPokemonEvolutionDataInternal]. It handles potential race conditions
  /// if multiple requests for different Pokémon are made rapidly by tracking
  /// [_currentPokemonIdForFetch] against the [pokemonId] for this specific call.
  ///
  /// - Sets [isLoading] to true. Clears [error], and if the [pokemonId] is new,
  ///   it also clears [pokemonDetail], [pokemonEvolution], and [evolutionError].
  /// - If successful, updates [pokemonDetail]. If the detail includes an evolution
  ///   chain URL, it then attempts to fetch the evolution data.
  /// - If an error occurs during the main detail fetch, sets [error] and clears related data.
  /// - Finally, sets [isLoading] to false if this fetch operation is still current.
  Future<void> fetchPokemonDetails(int pokemonId) async {
    if (_isDisposed) return; // Added guard

    final int localFetchId = pokemonId;
    _currentPokemonIdForFetch = localFetchId;

    _isLoading = true;
    _error = null;

    if (_pokemonDetail?.id != localFetchId) {
      _pokemonDetail = null;
      _pokemonEvolution = null;
      _evolutionError = null;
    }
    _safeNotifyListeners();

    try {
      // Check dispose again before potentially long async operation
      if (_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners();
        return;
      }
      final fetchedDetailData = await _repository.fetchPokemonDetails(
        localFetchId,
      );

      if (_currentPokemonIdForFetch != localFetchId || _isDisposed) return;

      _pokemonDetail = fetchedDetailData;
      _error = null;

      if (_pokemonDetail?.evolutionChainUrl != null &&
          _pokemonDetail!.evolutionChainUrl!.isNotEmpty) {
        await _fetchPokemonEvolutionDataInternal(
          _pokemonDetail!.evolutionChainUrl!,
          localFetchId,
        );
      } else {
        _pokemonEvolution = null;
        _evolutionError = _pokemonDetail == null
            ? "Pokemon details not loaded, cannot check for evolution."
            : "No evolution data URL available for this Pokémon.";
        _isEvolutionLoading = false;
      }
    } catch (e) {
      if (_currentPokemonIdForFetch == localFetchId && !_isDisposed) {
        _error = e.toString();
        _pokemonDetail = null;
        _pokemonEvolution = null;
        _isEvolutionLoading = false;
        _evolutionError = null; 
      }
    } finally {
      if (_currentPokemonIdForFetch == localFetchId && !_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> _fetchPokemonEvolutionDataInternal(
    String evolutionChainUrl,
    int originalPokemonId, 
  ) async {
    // This existing guard is good, especially with the added guards in public methods.
    if (_currentPokemonIdForFetch != originalPokemonId || _isDisposed) return;

    _isEvolutionLoading = true;
    _evolutionError = null;
    _safeNotifyListeners();

    try {
      // Check dispose again before potentially long async operation
      if (_isDisposed) {
         _isEvolutionLoading = false;
        _safeNotifyListeners();
        return;
      }
      final newPokemonEvolution = await _repository.fetchPokemonEvolution(
        evolutionChainUrl,
      );

      if (_currentPokemonIdForFetch != originalPokemonId || _isDisposed) return;

      _pokemonEvolution = newPokemonEvolution;
      _evolutionError = null;
    } catch (e) {
      if (_currentPokemonIdForFetch == originalPokemonId && !_isDisposed) {
        _evolutionError = e.toString();
      }
    } finally {
      if (_currentPokemonIdForFetch == originalPokemonId && !_isDisposed) {
        _isEvolutionLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  /// Refreshes the evolution data for the currently loaded [pokemonDetail].
  ///
  /// This method is typically called to allow the user to retry fetching evolution
  /// data if it previously failed or if a manual refresh is desired.
  /// It uses the [pokemonDetail.evolutionChainUrl] and [pokemonDetail.id] of the
  /// currently displayed Pokémon for the refresh operation.
  ///
  /// - If [pokemonDetail] is null or its `evolutionChainUrl` is null/empty,
  ///   it sets [evolutionError] and updates the state, then exits.
  /// - Otherwise, it calls [_fetchPokemonEvolutionDataInternal] to perform the fetch,
  ///   ensuring the context of the fetch is tied to the current Pokémon's ID.
  Future<void> refreshPokemonEvolutionData() async {
    if (_isDisposed) return; // Added guard

    if (_pokemonDetail == null) {
      _evolutionError = "Pokemon details not loaded.";
      _isEvolutionLoading = false;
      _safeNotifyListeners();
      return;
    }

    final String? evolutionUrl = _pokemonDetail!.evolutionChainUrl;
    final int currentDetailId = _pokemonDetail!.id;

    if (evolutionUrl == null || evolutionUrl.isEmpty) {
      _evolutionError = "No evolution data URL available to refresh.";
      _isEvolutionLoading = false;
      _safeNotifyListeners();
      return;
    }

    _currentPokemonIdForFetch = currentDetailId; // Ensure this is set for _fetchPokemonEvolutionDataInternal context
    await _fetchPokemonEvolutionDataInternal(evolutionUrl, currentDetailId);
  }
}
