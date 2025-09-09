import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex/repository/pokemon_repository.dart';

/// Global instance of the [GetIt] service locator.
///
/// Used to register and retrieve dependencies throughout the application,
/// promoting loose coupling and testability.
final getIt = GetIt.instance;

/// Sets up the service locator by registering necessary dependencies.
///
/// This function should be called once at application startup (e.g., in `main.dart`).
/// It registers:
/// - An [http.Client] as a factory, so a new client is created each time it's requested.
/// - A [PokemonRepository] as a lazy singleton, meaning it will be instantiated only
///   when first requested and then the same instance will be returned for subsequent requests.
///   The [PokemonRepository] itself depends on an [http.Client] which is resolved by `getIt`.
void setupServiceLocator() {
  getIt.registerFactory<http.Client>(() => http.Client());

  getIt.registerLazySingleton<PokemonRepository>(
    () => PokemonRepository(httpClient: getIt<http.Client>()),
  );
}
