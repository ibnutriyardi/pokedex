import 'package:flutter/material.dart';
import 'package:pokedex/repository/pokemon_repository.dart';
import 'package:pokedex/service_locator.dart';
import 'package:pokedex/view/pokemon_list_screen.dart';
import 'package:pokedex/viewmodel/pokemon_detail_viewmodel.dart';
import 'package:pokedex/viewmodel/pokemon_list_viewmodel.dart';
import 'package:provider/provider.dart';

/// The main entry point for the Pokedex application.
///
/// Initializes the service locator for dependency injection and runs the [PokedexApp].
void main() {
  setupServiceLocator();
  runApp(const PokedexApp());
}

/// The root widget of the Pokedex application.
///
/// It sets up the [MultiProvider] to make ViewModels ([PokemonListViewModel]
/// and [PokemonDetailViewModel]) available throughout the widget tree.
/// It also configures the [MaterialApp] with the title, theme, and initial route.
class PokedexApp extends StatelessWidget {
  /// Creates the [PokedexApp] widget.
  const PokedexApp({super.key});

  /// Builds the widget tree for the application.
  ///
  /// Sets up [MultiProvider] for state management and returns a [MaterialApp]
  /// configured with the home screen ([PokemonListScreen]), theme, and title.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PokemonListViewModel>(
          create: (_) {
            final repository = getIt<PokemonRepository>();
            return PokemonListViewModel(repository: repository);
          },
        ),
        ChangeNotifierProvider<PokemonDetailViewModel>(
          create: (_) {
            final repository = getIt<PokemonRepository>();
            return PokemonDetailViewModel(repository: repository);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Pokedex',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        home: const PokemonListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
