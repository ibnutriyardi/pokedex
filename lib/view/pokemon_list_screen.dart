import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_strings.dart';
import '../utils/app_ui_constants.dart';
import '../viewmodel/pokemon_list_viewmodel.dart';
import 'pokemon_details_screen.dart'; // New import added
import 'widget/pokemon_card.dart';

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !context.read<PokemonListViewModel>().isLoading &&
        context.read<PokemonListViewModel>().hasMore) {
      context.read<PokemonListViewModel>().fetchMorePokemons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PokemonListViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.pokedexTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppUIConstants.listAppBarTitleFontSize,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, PokemonListViewModel viewModel) {
    if (viewModel.isLoading && viewModel.pokemons.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null && viewModel.pokemons.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppUIConstants.mediumPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${AppStrings.errorPrefix}${viewModel.error}",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: AppUIConstants.fontSizeMedium,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppUIConstants.smallSpacer),
              ElevatedButton(
                onPressed: () => viewModel.fetchInitialPokemons(),
                child: const Text(AppStrings.retryButtonText),
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.pokemons.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noPokemonFound,
          style: TextStyle(fontSize: AppUIConstants.fontSizeMedium),
        ),
      );
    }

    // Fixed 2-column layout
    const int crossAxisCount = 2;
    // Keep aspect ratio fixed for now, as per the simplification to 2 columns.
    // If cards are too wide/short on tablets, we can make this dynamic later.
    const double childAspectRatio = 1.4;

    return RefreshIndicator(
      onRefresh: () => viewModel.fetchInitialPokemons(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(AppUIConstants.defaultPadding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: AppUIConstants.smallPadding,
                mainAxisSpacing: AppUIConstants.smallPadding,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final pokemon = viewModel.pokemons[index];
                return PokemonCard(
                  name: pokemon.capitalizedName,
                  id: viewModel.formatPokemonId(pokemon.id),
                  types: pokemon.types.map((t) => t.toUpperCase()).toList(),
                  imageUrl: pokemon.imageUrl,
                  color: viewModel.getPokemonTypeColor(
                    pokemon.types.isNotEmpty ? pokemon.types.first : null,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PokemonDetailsScreenWrapper(
                          pokemonId: pokemon.id,
                        ), // Changed to new screen
                      ),
                    );
                  },
                );
              }, childCount: viewModel.pokemons.length),
            ),
          ),
          SliverToBoxAdapter(
            child: viewModel.isLoading && viewModel.pokemons.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.all(AppUIConstants.mediumPadding),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ),
          SliverToBoxAdapter(
            child: viewModel.error != null && viewModel.pokemons.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.all(AppUIConstants.mediumPadding),
                    child: Center(
                      child: Text(
                        "${AppStrings.couldNotLoadMorePrefix}${viewModel.error}",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: AppUIConstants.fontSizeSmall,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
