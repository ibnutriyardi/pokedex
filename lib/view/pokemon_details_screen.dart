import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pokedex/viewmodel/pokemon_detail_viewmodel.dart';
import 'package:provider/provider.dart';

import '../model/pokemon_detail.dart';
import '../model/pokemon_evolution.dart';
import '../utils/app_strings.dart';
import '../utils/app_ui_constants.dart';
import '../utils/color_utils.dart';
import 'widget/pokemon_type_capsule.dart';

/// A wrapper widget for [PokemonDetailsScreen] that provides the [PokemonDetailViewModel].
///
/// This widget is responsible for creating and providing the [PokemonDetailViewModel]
/// to the [_PokemonDetailsScreen] widget tree, initiating the fetch for Pokémon details.
class PokemonDetailsScreenWrapper extends StatelessWidget {
  /// The ID of the Pokémon to display details for.
  final int pokemonId;

  /// Creates a [PokemonDetailsScreenWrapper].
  ///
  /// Requires the [pokemonId] of the Pokémon whose details are to be displayed.
  const PokemonDetailsScreenWrapper({super.key, required this.pokemonId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PokemonDetailViewModel()..fetchPokemonDetails(pokemonId),
      child: _PokemonDetailsScreen(pokemonId: pokemonId),
    );
  }
}

/// The main stateful widget for displaying the details of a specific Pokémon.
///
/// It receives a [pokemonId] and uses a [PokemonDetailViewModel] (provided by
/// [PokemonDetailsScreenWrapper]) to fetch and display Pokémon data across various tabs.
class _PokemonDetailsScreen extends StatefulWidget {
  /// The ID of the Pokémon to display details for.
  final int pokemonId;

  /// Creates a [_PokemonDetailsScreen].
  ///
  /// Requires the [pokemonId].
  const _PokemonDetailsScreen({required this.pokemonId});

  @override
  State<_PokemonDetailsScreen> createState() => _PokemonDetailsScreenState();
}

class _PokemonDetailsScreenState extends State<_PokemonDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Default values used as fallbacks if AppUIConstants are not set (e.g., 0.0)
  static const double _defaultScreenPadding = 16.0;
  static const double _defaultXSmallPadding = 8.0;
  static const double _defaultSmallPadding = 8.0;
  static const double _defaultMediumPadding = 16.0;
  static const double _defaultLargePadding = 24.0;
  static const double _defaultSheetBorderRadius = 24.0;
  static const double _defaultPokemonImageSize = 144.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Builds the decorative Pokeball background image.
  Widget _buildPokeballBackground(
    Color pokemonTypeColor,
    bool isLandscape,
    double mainPokemonImageSize,
  ) {
    double pokeballSize = mainPokemonImageSize * 1.6;

    return Positioned(
      top: isLandscape
          ? (AppUIConstants.smallPadding > 0
                ? AppUIConstants.smallPadding
                : _defaultSmallPadding)
          : (AppUIConstants.pokeballDetailPositionTop != 0
                ? AppUIConstants.pokeballDetailPositionTop
                : 0),
      right: AppUIConstants.pokeballDetailPositionRight != 0
          ? AppUIConstants.pokeballDetailPositionRight
          : 0,
      child: Opacity(
        opacity: AppUIConstants.pokeballOpacity,
        child: Image.asset(
          AppStrings.pokeballImagePath,
          width: pokeballSize,
          height: pokeballSize,
          fit: BoxFit.contain,
          color: Colors.white,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Builds the row displaying the Pokémon's name and formatted ID.
  Widget _buildPokemonNameAndIdRow(PokemonDetail pokemon) {
    TextStyle nameStyle = TextStyle(
      fontSize: AppUIConstants.pokemonNameFontSize,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    TextStyle idStyle = TextStyle(
      fontSize: AppUIConstants.pokemonIdFontSize,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppUIConstants.screenPadding > 0
            ? AppUIConstants.screenPadding
            : _defaultScreenPadding,
        vertical: AppUIConstants.xSmallPadding > 0
            ? AppUIConstants.xSmallPadding
            : _defaultXSmallPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              pokemon.capitalizedName,
              style: nameStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(pokemon.formattedId, style: idStyle),
        ],
      ),
    );
  }

  /// Builds the row displaying Pokémon type capsules.
  Widget _buildTypeCapsulesRow(PokemonDetail pokemon, Color pokemonTypeColor) {
    if (pokemon.types.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppUIConstants.screenPadding > 0
            ? AppUIConstants.screenPadding
            : _defaultScreenPadding,
        vertical: AppUIConstants.xSmallPadding > 0
            ? AppUIConstants.xSmallPadding
            : _defaultXSmallPadding,
      ),
      child: Row(
        children: pokemon.types
            .map(
              (type) => Padding(
                padding: EdgeInsets.only(
                  right: AppUIConstants.xSmallPadding > 0
                      ? AppUIConstants.xSmallPadding
                      : _defaultXSmallPadding,
                ),
                child: PokemonTypeCapsule(
                  type: type,
                  capsuleColor: Color.alphaBlend(
                    Colors.white.withAlpha(
                      AppUIConstants.typeCapsuleBackgroundAlpha,
                    ),
                    pokemonTypeColor,
                  ),
                  textColor: Colors.white,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// Builds the main Pokémon image with a Hero animation.
  Widget _buildPokemonImage(PokemonDetail pokemon, double imageSize) {
    return Hero(
      tag: 'pokemon-image-${pokemon.id}',
      child: CachedNetworkImage(
        imageUrl: pokemon.imageUrl,
        height: imageSize,
        width: imageSize,
        fit: BoxFit.contain,
        placeholder: (context, url) => SizedBox(
          height: imageSize,
          width: imageSize,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.error_outline,
          size: imageSize * 0.5,
          color: Colors.white70,
        ),
      ),
    );
  }

  /// Builds the tab system (TabBar and TabBarView) for different Pokémon details sections.
  Widget _buildTabSystem(
    BuildContext context,
    PokemonDetail pokemon,
    Color pokemonTypeColor,
  ) {
    return Column(
      children: [
        SizedBox(
          height: AppUIConstants.largePadding > 0
              ? AppUIConstants.largePadding
              : _defaultLargePadding,
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppUIConstants.largePadding > 0
                ? AppUIConstants.largePadding
                : _defaultLargePadding,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(primary: pokemonTypeColor),
              tabBarTheme: Theme.of(context).tabBarTheme.copyWith(
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: TextStyle(
                  fontSize: AppUIConstants.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: AppUIConstants.fontSizeSmall,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.symmetric(
                horizontal: AppUIConstants.xSmallPadding > 0
                    ? AppUIConstants.xSmallPadding
                    : _defaultXSmallPadding,
              ),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: pokemonTypeColor,
                  width: AppUIConstants.tabBarIndicatorWidth,
                ),
              ),
              tabs: const [
                Tab(text: AppStrings.aboutTab),
                Tab(text: AppStrings.baseStatsTab),
                Tab(text: AppStrings.evolutionTab),
                Tab(text: AppStrings.movesTab),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAboutTab(context, pokemon, Colors.black54),
              _buildBaseStatsTab(context, pokemon, pokemonTypeColor),
              _buildEvolutionTab(
                context,
                pokemon,
                context.watch<PokemonDetailViewModel>(),
              ),
              _buildMovesTab(context, pokemon, pokemonTypeColor),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the UI layout for portrait orientation.
  Widget _buildPortraitLayout(
    BuildContext context,
    PokemonDetail pokemon,
    Color pokemonTypeColor,
  ) {
    final double imageOverlapAmount = _defaultPokemonImageSize * 0.4;
    final double sheetBorderRadius = AppUIConstants.sheetBorderRadius > 0
        ? AppUIConstants.sheetBorderRadius
        : _defaultSheetBorderRadius;

    return Stack(
      children: [
        _buildPokeballBackground(
          pokemonTypeColor,
          false,
          _defaultPokemonImageSize,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPokemonNameAndIdRow(pokemon),
            _buildTypeCapsulesRow(pokemon, pokemonTypeColor),
            SizedBox(
              height: AppUIConstants.xSmallPadding > 0
                  ? AppUIConstants.xSmallPadding
                  : _defaultXSmallPadding,
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: _defaultPokemonImageSize - imageOverlapAmount,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(sheetBorderRadius),
                              topRight: Radius.circular(sheetBorderRadius),
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: _buildTabSystem(
                                  context,
                                  pokemon,
                                  pokemonTypeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: Offset(
                      0,
                      -(AppUIConstants.screenPadding > 0
                          ? AppUIConstants.screenPadding
                          : _defaultLargePadding),
                    ),
                    child: _buildPokemonImage(
                      pokemon,
                      _defaultPokemonImageSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the UI layout for landscape orientation.
  Widget _buildLandscapeLayout(
    BuildContext context,
    PokemonDetail pokemon,
    Color pokemonTypeColor,
  ) {
    final double sheetBorderRadius = AppUIConstants.sheetBorderRadius > 0
        ? AppUIConstants.sheetBorderRadius
        : _defaultSheetBorderRadius;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            color: pokemonTypeColor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final double dynamicLandscapeImageSize = (availableWidth * 0.60)
                    .clamp(
                      _defaultPokemonImageSize * 1.1,
                      _defaultPokemonImageSize * 1.7,
                    );

                return Stack(
                  children: [
                    _buildPokeballBackground(
                      pokemonTypeColor,
                      true,
                      dynamicLandscapeImageSize,
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.all(
                          AppUIConstants.smallPadding > 0
                              ? AppUIConstants.smallPadding
                              : _defaultSmallPadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPokemonNameAndIdRow(pokemon),
                            _buildTypeCapsulesRow(pokemon, pokemonTypeColor),
                            Expanded(
                              child: Center(
                                child: _buildPokemonImage(
                                  pokemon,
                                  dynamicLandscapeImageSize,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: AppUIConstants.mediumPadding > 0
                                  ? AppUIConstants.mediumPadding
                                  : _defaultMediumPadding,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(sheetBorderRadius),
              ),
            ),
            child: _buildTabSystem(context, pokemon, pokemonTypeColor),
          ),
        ),
      ],
    );
  }

  /// Builds the main widget tree for the screen.
  ///
  /// Handles loading, error, and data states, and delegates to orientation-specific
  /// layout builders ([_buildPortraitLayout] or [_buildLandscapeLayout]).
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PokemonDetailViewModel>();
    final pokemon = viewModel.pokemonDetail;
    final isLoading = viewModel.isLoading;
    final error = viewModel.error;

    if (isLoading && pokemon == null) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.detailsScreenErrorTitle)),
        body: Center(child: Text('${AppStrings.errorPrefix}$error')),
      );
    }
    if (pokemon == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.detailsScreenNotFoundTitle),
        ),
        body: const Center(
          child: Text(AppStrings.detailsScreenPokemonNotFound),
        ),
      );
    }

    Color pokemonTypeColor = getPokemonTypeColor(
      pokemon.types.firstOrNull,
    );

    return Scaffold(
      backgroundColor: pokemonTypeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: OrientationBuilder(
        
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return _buildPortraitLayout(context, pokemon, pokemonTypeColor);
          } else {
            return _buildLandscapeLayout(context, pokemon, pokemonTypeColor);
          }
        },
      ),
    );
  }

  /// Builds the content for the 'About' tab.
  Widget _buildAboutTab(
    BuildContext context,
    PokemonDetail pokemon,
    Color subduedTextColor,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        AppUIConstants.largePadding > 0
            ? AppUIConstants.largePadding
            : _defaultLargePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pokemon.description,
            style: TextStyle(
              fontSize: AppUIConstants.fontSizeLarge,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(
            height: AppUIConstants.largeSpacer > 0
                ? AppUIConstants.largeSpacer
                : _defaultLargePadding,
          ),
          _buildInfoRow(AppStrings.speciesLabel, pokemon.capitalizedName),
          _buildInfoRow(
            AppStrings.heightLabel,
            "${pokemon.displayHeight.toStringAsFixed(1)} m (${_toFeetInches(pokemon.displayHeight)})",
          ),
          _buildInfoRow(
            AppStrings.weightLabel,
            "${pokemon.displayWeight.toStringAsFixed(1)} kg (${(pokemon.displayWeight * AppUIConstants.kgToLbs).toStringAsFixed(1)} lbs)",
          ),
          _buildInfoRow(
            AppStrings.abilitiesLabel,
            pokemon.abilities.join(', '),
          ),
        ],
      ),
    );
  }

  /// Converts a height in meters to a string representation in feet and inches.
  String _toFeetInches(double meters) {
    double totalInches = meters * AppUIConstants.metersToTotalInches;
    int feet = (totalInches / AppUIConstants.inchesPerFoot).floor();
    int inches = (totalInches % AppUIConstants.inchesPerFoot).round();
    return "$feet' $inches\"";
  }

  /// Builds a row for displaying a piece of information (label and value).
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppUIConstants.xSmallPadding > 0
            ? AppUIConstants.xSmallPadding
            : _defaultXSmallPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppUIConstants.infoLabelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppUIConstants.fontSizeLarge,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: AppUIConstants.defaultSpacer > 0
                ? AppUIConstants.defaultSpacer
                : _defaultMediumPadding,
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppUIConstants.fontSizeLarge,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the content for the 'Base Stats' tab.
  Widget _buildBaseStatsTab(
    BuildContext context,
    PokemonDetail pokemon,
    Color primaryColor,
  ) {
    int totalBaseStats = pokemon.stats.fold(
      0,
      (sum, stat) => sum + stat.baseStat,
    );
    int maxStatValue = AppUIConstants.defaultMaxStatValue;
    if (pokemon.stats.isNotEmpty) {
      final maxIndividualStat = pokemon.stats
          .map((s) => s.baseStat)
          .reduce((a, b) => a > b ? a : b);
      if (maxIndividualStat > 0) {
        maxStatValue =
            (maxIndividualStat * AppUIConstants.maxIndividualStatMultiplier)
                .round();
        if (maxStatValue > AppUIConstants.maxPossibleStatValue) {
          maxStatValue = AppUIConstants.maxPossibleStatValue;
        }
        if (maxStatValue < AppUIConstants.minCalculatedMaxStatValue) {
          maxStatValue = AppUIConstants.minCalculatedMaxStatValue;
        }
      }
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        AppUIConstants.largePadding > 0
            ? AppUIConstants.largePadding
            : _defaultLargePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...pokemon.stats.map(
            (stat) => _buildStatRow(
              stat.capitalizedStatName,
              stat.baseStat,
              primaryColor,
              maxValue: maxStatValue,
            ),
          ),
          SizedBox(
            height: AppUIConstants.defaultSpacer > 0
                ? AppUIConstants.defaultSpacer
                : _defaultMediumPadding,
          ),
          Divider(color: Colors.grey.shade300, thickness: 1),
          SizedBox(
            height: AppUIConstants.xSmallPadding > 0
                ? AppUIConstants.xSmallPadding
                : _defaultXSmallPadding,
          ),
          _buildStatRow(
            AppStrings.totalLabel,
            totalBaseStats,
            primaryColor,
            maxValue:
                (maxStatValue *
                        pokemon.stats.length *
                        AppUIConstants.totalStatMultiplier)
                    .round()
                    .clamp(
                      AppUIConstants.totalStatClampLowerBound,
                      AppUIConstants.totalStatClampUpperBound,
                    ),
          ),
          SizedBox(
            height: AppUIConstants.mediumSpacer > 0
                ? AppUIConstants.mediumSpacer
                : 20.0,
          ),
          Text(
            AppStrings.baseStatsDescription,
            style: TextStyle(
              fontSize: AppUIConstants.fontSizeSmall,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }

  /// Builds a row displaying a single statistic with a progress bar.
  Widget _buildStatRow(
    String name,
    int value,
    Color statColor, {
    required int maxValue,
  }) {
    double percentage = maxValue > 0 ? value / maxValue.toDouble() : 0.0;
    if (percentage > 1.0) percentage = 1.0;
    if (percentage < 0) percentage = 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical:
            (AppUIConstants.xSmallPadding > 0
                ? AppUIConstants.xSmallPadding
                : _defaultXSmallPadding) /
            2,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: TextStyle(
                fontSize: AppUIConstants.fontSizeLarge,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: AppUIConstants.statValueWidth,
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: AppUIConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: AppUIConstants.defaultSpacer > 0
                ? AppUIConstants.defaultSpacer
                : _defaultMediumPadding,
          ),
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppUIConstants.generalBorderRadius,
              ),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: AppUIConstants.statBarHeight,
                backgroundColor: statColor.withAlpha(
                  AppUIConstants.statBarBackgroundAlpha,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(statColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the content for the 'Evolution' tab, displaying the Pokémon's evolution chain.
  Widget _buildEvolutionTab(
    BuildContext context,
    PokemonDetail pokemon,
    PokemonDetailViewModel viewModel,
  ) {
    final evolutionChain = viewModel.pokemonEvolution;
    final isLoading = viewModel.isEvolutionLoading;
    final error = viewModel.evolutionError;

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Text(
          "${AppStrings.evolutionErrorPrefix}$error",
          style: TextStyle(fontSize: AppUIConstants.fontSizeMedium),
        ),
      );
    }

    if (evolutionChain == null) {
      return Center(
        child: Text(
          AppStrings.noEvolutionData,
          style: TextStyle(fontSize: AppUIConstants.fontSizeMedium),
        ),
      );
    }

    /// Recursively builds the list of widgets for the evolution chain display.
    List<Widget> buildEvolutionWidgets(
      PokemonEvolution currentStage,
      int depth,
    ) {
      List<Widget> widgets = [];
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            left:
                depth *
                (AppUIConstants.largePadding > 0
                    ? AppUIConstants.largePadding
                    : _defaultLargePadding),
            top: (AppUIConstants.smallPadding > 0
                ? AppUIConstants.smallPadding
                : _defaultSmallPadding),
            bottom: (AppUIConstants.smallPadding > 0
                ? AppUIConstants.smallPadding
                : _defaultSmallPadding),
          ),
          child: Center(
            child: Text(
              currentStage.capitalizedSpeciesName,
              style: TextStyle(
                fontSize: AppUIConstants.fontSizeXLarge,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
      if (currentStage.evolvesTo.isNotEmpty) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              left:
                  depth *
                      (AppUIConstants.largePadding > 0
                          ? AppUIConstants.largePadding
                          : _defaultLargePadding),
            ),
            child: Center(
              child: Icon(
                Icons.arrow_downward,
                color: Colors.grey.shade600,
                size: AppUIConstants.evolutionIndicatorIconSize,
              ),
            ),
          ),
        );
        for (var nextStage in currentStage.evolvesTo) {
          widgets.addAll(
            buildEvolutionWidgets(
              nextStage,
              depth + (currentStage.evolvesTo.length > 1 ? 1 : 0),
            ),
          );
        }
      }
      return widgets;
    }

    var evolutionContent = buildEvolutionWidgets(evolutionChain, 0);
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        AppUIConstants.largePadding > 0
            ? AppUIConstants.largePadding
            : _defaultLargePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: evolutionContent.isNotEmpty
            ? evolutionContent
            : [
                Center(
                  child: Text(
                    AppStrings.doesNotEvolve,
                    style: TextStyle(fontSize: AppUIConstants.fontSizeMedium),
                  ),
                ),
              ],
      ),
    );
  }

  /// Builds the content for the 'Moves' tab.
  Widget _buildMovesTab(
    BuildContext context,
    PokemonDetail pokemon,
    Color primaryColor,
  ) {
    if (pokemon.moves.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noMovesAvailable,
          style: TextStyle(
            fontSize: AppUIConstants.fontSizeMedium,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(
        AppUIConstants.largePadding > 0
            ? AppUIConstants.largePadding
            : _defaultLargePadding,
      ),
      itemCount: pokemon.moves.length,
      itemBuilder: (context, index) {
        final move = pokemon.moves[index];
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppUIConstants.smallPadding > 0
                ? AppUIConstants.smallPadding
                : _defaultSmallPadding,
          ),
          child: Text(
            move.formattedName,
            style: TextStyle(
              fontSize: AppUIConstants.fontSizeLarge,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
      separatorBuilder: (context, index) =>
          Divider(color: Colors.grey.shade200, height: 1),
    );
  }
}
