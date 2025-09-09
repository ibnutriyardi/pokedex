/// A utility class holding constant string values used throughout the application.
///
/// This helps in centralizing and managing all user-facing strings and internal
/// string constants, making localization or modification easier.
class AppStrings {
  /// The main title for the Pokedex application.
  static const String pokedexTitle = 'Pokedex';

  /// A prefix used for displaying error messages.
  static const String errorPrefix = 'Error: ';

  /// Text for a button that allows the user to retry an action.
  static const String retryButtonText = 'Retry';

  /// Message displayed when no Pokemon are found in a list or search.
  static const String noPokemonFound = 'No Pokemon found.';

  /// Prefix for messages indicating failure to load more items in a list.
  static const String couldNotLoadMorePrefix = 'Could not load more: ';

  /// Title for error dialogs or screens in the Pokemon details view.
  static const String detailsScreenErrorTitle = 'Error';

  /// Title for screens indicating a requested Pokemon was not found.
  static const String detailsScreenNotFoundTitle = 'Not Found';

  /// Message displayed when a specific Pokemon's details cannot be found.
  static const String detailsScreenPokemonNotFound = 'Pokemon not found.';

  /// Label for the 'About' tab in the Pokemon details screen.
  static const String aboutTab = 'About';

  /// Label for the 'Base Stats' tab in the Pokemon details screen.
  static const String baseStatsTab = 'Base Stats';

  /// Label for the 'Evolution' tab in the Pokemon details screen.
  static const String evolutionTab = 'Evolution';

  /// Label for the 'Moves' tab in the Pokemon details screen.
  static const String movesTab = 'Moves';

  /// Label for the species information in the Pokemon details 'About' tab.
  static const String speciesLabel = 'Species';

  /// Label for the height information in the Pokemon details 'About' tab.
  static const String heightLabel = 'Height';

  /// Label for the weight information in the Pokemon details 'About' tab.
  static const String weightLabel = 'Weight';

  /// Label for the abilities information in the Pokemon details 'About' tab.
  static const String abilitiesLabel = 'Abilities';

  /// Label for the total of base stats in the Pokemon details 'Base Stats' tab.
  static const String totalLabel = 'Total';

  /// A descriptive text explaining what base stats are.
  static const String baseStatsDescription =
      'Base stats are the inherent values of a Pokémon species.';

  /// Prefix for error messages when loading Pokemon evolution data.
  static const String evolutionErrorPrefix = 'Error loading evolution: ';

  /// Message displayed when no evolution data is available for a Pokemon.
  static const String noEvolutionData = 'No evolution data available.';

  /// Message displayed when a Pokemon does not evolve.
  static const String doesNotEvolve = 'This Pokémon does not evolve.';

  /// Message displayed when a Pokemon has no moves listed.
  static const String noMovesAvailable = 'No moves available.';

  /// File path for the Pokeball background image asset.
  static const String pokeballImagePath = 'assets/images/pokeball.png';
}
