import 'package:flutter/material.dart';
import 'package:pokedex/repository/pokemon_repository.dart';
import 'package:pokedex/service_locator.dart';
import 'package:pokedex/view/pokemon_list_screen.dart';
import 'package:pokedex/viewmodel/pokemon_detail_viewmodel.dart';
import 'package:pokedex/viewmodel/pokemon_list_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  setupServiceLocator();
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

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
