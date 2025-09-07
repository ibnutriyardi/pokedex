import 'package:flutter/material.dart'; // For Color

import '../model/pokemon_detail.dart';
import '../model/pokemon_evolution.dart';
import '../repository/pokemon_repository.dart';

class PokemonDetailViewModel extends ChangeNotifier {
  final PokemonRepository _repository;

  PokemonDetail? _pokemonDetail;

  PokemonDetail? get pokemonDetail => _pokemonDetail;

  PokemonEvolution? _pokemonEvolution;

  PokemonEvolution? get pokemonEvolution => _pokemonEvolution;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _error;

  String? get error => _error;

  bool _isEvolutionLoading = false;

  bool get isEvolutionLoading => _isEvolutionLoading;

  String? _evolutionError;

  String? get evolutionError => _evolutionError;

  int?
  _currentPokemonIdForFetch; // Tracks the ID for which active fetching is intended
  bool _isDisposed = false;

  PokemonDetailViewModel({PokemonRepository? repository})
    : _repository = repository ?? PokemonRepository();

  @override
  void dispose() {
    _isDisposed = true;
    _currentPokemonIdForFetch = null;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> fetchPokemonDetails(int pokemonId) async {
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
      final fetchedDetailData = await _repository.fetchPokemonDetails(
        localFetchId,
      );

      if (_currentPokemonIdForFetch != localFetchId) return;

      _pokemonDetail = fetchedDetailData;
      _error = null;

      if (_pokemonDetail?.evolutionChainUrl != null &&
          _pokemonDetail!.evolutionChainUrl!.isNotEmpty) {
        // Pass the evolutionChainUrl and the original pokemonId for context checking
        await _fetchPokemonEvolutionDataInternal(
          _pokemonDetail!.evolutionChainUrl!,
          localFetchId,
        );
      } else {
        _pokemonEvolution = null;
        _evolutionError = _pokemonDetail == null
            ? "Pokemon details not loaded."
            : "No evolution data URL available.";
        _isEvolutionLoading = false;
      }
    } catch (e) {
      if (_currentPokemonIdForFetch == localFetchId) {
        _error = e.toString();
        _pokemonDetail = null;
        _pokemonEvolution = null;
        _isEvolutionLoading = false;
        _evolutionError = null;
      }
    } finally {
      if (_currentPokemonIdForFetch == localFetchId) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  // Updated to accept evolutionChainUrl and originalPokemonId for context
  Future<void> _fetchPokemonEvolutionDataInternal(
    String evolutionChainUrl,
    int originalPokemonId,
  ) async {
    // Check against the original Pokemon ID for which this evolution fetch was initiated
    if (_currentPokemonIdForFetch != originalPokemonId) return;

    _isEvolutionLoading = true;
    _evolutionError = null;
    _safeNotifyListeners();

    try {
      final newPokemonEvolution = await _repository.fetchPokemonEvolution(
        evolutionChainUrl,
      );

      if (_currentPokemonIdForFetch != originalPokemonId) return;

      _pokemonEvolution = newPokemonEvolution;
      _evolutionError = null;
    } catch (e) {
      if (_currentPokemonIdForFetch == originalPokemonId) {
        _evolutionError = e.toString();
        // _pokemonEvolution = null; // Retain old data on error - Line removed
      }
    } finally {
      if (_currentPokemonIdForFetch == originalPokemonId) {
        _isEvolutionLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> refreshPokemonEvolutionData() async {
    if (_pokemonDetail == null) {
      _evolutionError = "Pokemon details not loaded.";
      _isEvolutionLoading = false;
      _safeNotifyListeners();
      return;
    }

    final String? evolutionUrl = _pokemonDetail!.evolutionChainUrl;
    final int currentDetailId =
        _pokemonDetail!.id; // Use current detail ID for context

    if (evolutionUrl == null || evolutionUrl.isEmpty) {
      _evolutionError = "No evolution data URL available to refresh.";
      _isEvolutionLoading = false;
      _safeNotifyListeners();
      return;
    }

    // Ensure _currentPokemonIdForFetch is set to the ID of the Pokemon whose evolution we are refreshing
    _currentPokemonIdForFetch = currentDetailId;
    await _fetchPokemonEvolutionDataInternal(evolutionUrl, currentDetailId);
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
      // Added missing type from previous interaction, ensure it stays if it was already there
      case 'flying': 
        return const Color(0xFFA890F0);
      default:
        return Colors.grey.shade400;
    }
  }
}
