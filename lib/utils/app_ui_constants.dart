/// Holds a collection of static constant values used for defining UI dimensions,
/// padding, spacing, font sizes, and other UI-related parameters throughout the
/// Pokedex application.
///
/// Centralizing these constants helps in maintaining a consistent look and feel
/// and makes it easier to adjust UI elements globally.
class AppUIConstants {
  // --- General Padding --- 

  /// Default padding for screen edges.
  static const double screenPadding = 24.0;

  /// Large padding value, typically used for major content blocks or sections.
  static const double largePadding = 20.0;

  /// Medium padding value, for elements requiring moderate spacing.
  static const double mediumPadding = 16.0;

  /// Default padding value, often used between standard UI elements.
  static const double defaultPadding = 12.0;

  /// Small padding value, for minor spacing between elements.
  static const double smallPadding = 8.0;

  /// Extra small padding, for fine-tuned spacing.
  static const double xSmallPadding = 6.0;

  /// Tiny padding, for minimal spacing requirements.
  static const double tinyPadding = 5.0;

  // --- Specific Padding --- 

  /// Vertical padding used symmetrically, often within list items or cards.
  static const double symmetricVerticalPadding = 6.0;

  /// Vertical padding for the header section in detail views.
  static const double detailHeaderVerticalPadding = 10.0;

  /// Vertical padding for the content area within tabs.
  static const double tabContentVerticalPadding = 16.0;

  // --- Spacers --- 

  /// Large spacer, for creating significant visual separation.
  static const double largeSpacer = 24.0;

  /// Small spacer, for minor visual separation.
  static const double smallSpacer = 8.0;

  /// Tiny spacer, for minimal visual separation.
  static const double tinySpacer = 5.0;

  /// Medium spacer, for moderate visual separation.
  static const double mediumSpacer = 16.0;

  /// Default spacer, for standard visual separation between elements.
  static const double defaultSpacer = 12.0;

  // --- UI Element Dimensions & Sizing --- 

  /// Width for information labels (e.g., "Height", "Weight") in detail views.
  static const double infoLabelWidth = 100.0;

  /// Width for displaying stat values (e.g., "80") in the base stats tab.
  static const double statValueWidth = 40.0;

  /// Height of the progress bars used to display base stats.
  static const double statBarHeight = 8.0;

  /// Size of the error icon used in Hero animations or image placeholders.
  static const double heroErrorIconSize = 50.0;

  /// Default size for the main Pokemon image in the details screen.
  static const double pokemonImageSize = 140.0;

  /// Amount by which the Pokemon image overlaps with the content sheet below it.
  static const double imageOverlapAmount = 95.0;

  // --- Card Specific Dimensions (Pokemon List Items) --- 

  /// Size of the Pokemon image within a list item card.
  static const double cardPokemonImageSize = 70.0;

  /// Size of the Pokeball background image within a list item card.
  static const double cardPokeballImageSize = 100.0;

  /// Horizontal offset for the Pokeball image in a list item card.
  static const double cardPokeballOffsetX = -40.0;

  /// Vertical offset for the Pokeball image in a list item card.
  static const double cardPokeballOffsetY = -40.0;

  /// Right padding for the content within a list item card, to avoid overlap with Pokeball.
  static const double cardContentRightPadding = 40.0;

  /// Edge offset for the Pokemon image within a card, for slight visual spacing.
  static const double cardImageEdgeOffset = 2.0;

  // --- Border Radius --- 

  /// Border radius for bottom sheets or large panel containers.
  static const double sheetBorderRadius = 24.0;

  /// General border radius used for smaller elements like buttons or cards.
  static const double generalBorderRadius = 6.0;

  // --- Pokeball Background Image (Detail Screen) --- 

  /// Top positioning for the Pokeball background image in the details screen.
  static const double pokeballDetailPositionTop = 0.0;

  /// Right positioning for the Pokeball background image in the details screen.
  static const double pokeballDetailPositionRight = -50.0;

  /// Size of the Pokeball background image in the details screen.
  static const double pokeballDetailImageSize = 250.0;

  /// Opacity for the Pokeball background image.
  static const double pokeballOpacity = 0.15;

  // --- TabBar Styling --- 

  /// Horizontal padding for labels within the TabBar.
  static const double tabBarHorizontalLabelPadding = 8.0;

  /// Width (thickness) of the TabBar indicator line.
  static const double tabBarIndicatorWidth = 3.0;

  // --- Alpha Values (0-255) --- 

  /// Alpha value for the background of Pokemon type capsules.
  static const int typeCapsuleBackgroundAlpha = 77;

  /// Alpha value for the background of stat bars.
  static const int statBarBackgroundAlpha = 51;

  // --- Evolution Tab Specific --- 

  /// Multiplier for indentation based on evolution depth.
  static const double evolutionDepthPaddingMultiplier = 20.0;

  /// Size of the evolution indicator icon (e.g., downward arrow).
  static const double evolutionIndicatorIconSize = 20.0;

  /// Spacing related to evolution indicators.
  static const double evolutionIndicatorSpacing = 10.0;

  // --- Unit Conversion Constants --- 

  /// Conversion factor from meters to total inches.
  static const double metersToTotalInches = 39.3701;

  /// Number of inches in a foot.
  static const int inchesPerFoot = 12;

  /// Conversion factor from kilograms to pounds.
  static const double kgToLbs = 2.20462;

  // --- Base Stats Calculation & Display --- 

  /// Default maximum value used for scaling stat bars if no better max is calculated.
  static const int defaultMaxStatValue = 180;

  /// Multiplier to determine a dynamic max stat value based on the highest individual stat.
  static const double maxIndividualStatMultiplier = 1.2;

  /// Absolute maximum possible value for a single Pokemon stat (as per game mechanics typically).
  static const int maxPossibleStatValue = 255;

  /// Minimum calculated maximum stat value to ensure stat bars are not excessively scaled for low-stat Pokemon.
  static const int minCalculatedMaxStatValue = 100;

  /// Lower bound for clamping the calculated total stat bar's maximum value.
  static const int totalStatClampLowerBound = 600;

  /// Upper bound for clamping the calculated total stat bar's maximum value.
  static const int totalStatClampUpperBound = 720;

  /// Multiplier used in calculating the max value for the "Total" stat bar.
  static const double totalStatMultiplier = 0.7;

  // --- Font Sizes --- 

  /// Small font size.
  static const double fontSizeSmall = 13.0;

  /// Medium font size.
  static const double fontSizeMedium = 14.0;

  /// Large font size.
  static const double fontSizeLarge = 15.0;

  /// Extra-large font size.
  static const double fontSizeXLarge = 16.0;

  /// Font size for the Pokemon ID display (e.g., #001).
  static const double pokemonIdFontSize = 20.0;

  /// Font size for the main Pokemon name display in details view.
  static const double pokemonNameFontSize = 30.0;

  /// Font size for the title in the AppBar of the Pokemon list screen.
  static const double listAppBarTitleFontSize = 22.0;

  // --- Card Specific Font Sizes --- 

  /// Font size for the Pokemon ID on list item cards.
  static const double cardIdFontSize = 10.0;

  /// Font size for the Pokemon name on list item cards.
  static const double cardNameFontSize = 14.0;

  /// Font size for the Pokemon type on list item cards.
  static const double cardTypeFontSize = 9.0;

  // --- Type Capsule Specific Font Sizes & Padding --- 

  /// Font size for text within Pokemon type capsules.
  static const double typeCapsuleFontSize = 9.0;

  /// Horizontal padding within Pokemon type capsules.
  static const double typeCapsuleHorizontalPadding = 8.0;

  /// Vertical padding within Pokemon type capsules.
  static const double typeCapsuleVerticalPadding = 5.0;
}
