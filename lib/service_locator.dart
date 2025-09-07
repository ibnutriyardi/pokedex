import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex/repository/pokemon_repository.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerFactory<http.Client>(() => http.Client());

  getIt.registerLazySingleton<PokemonRepository>(
    () => PokemonRepository(httpClient: getIt<http.Client>()),
  );
}
