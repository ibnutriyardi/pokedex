import 'dart:async' as i7;

import 'package:mockito/mockito.dart' as i1;
import 'package:mockito/src/dummies.dart' as i6;
import 'package:pokedex/model/pokemon_detail.dart' as i3;
import 'package:pokedex/model/pokemon_evolution.dart' as i4;
import 'package:pokedex/model/pokemon_list.dart' as i2;
import 'package:pokedex/repository/pokemon_repository.dart' as i5;

class _FakePokemonList_0 extends i1.SmartFake implements i2.PokemonList {
  _FakePokemonList_0(super.parent, super.parentInvocation);
}

class _FakePokemonDetail_1 extends i1.SmartFake implements i3.PokemonDetail {
  _FakePokemonDetail_1(super.parent, super.parentInvocation);
}

class _FakePokemonEvolution_2 extends i1.SmartFake
    implements i4.PokemonEvolution {
  _FakePokemonEvolution_2(super.parent, super.parentInvocation);
}

/// A class which mocks [PokemonRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockPokemonRepository extends i1.Mock implements i5.PokemonRepository {
  MockPokemonRepository() {
    i1.throwOnMissingStub(this);
  }

  @override
  String get baseUrl =>
      (super.noSuchMethod(
            Invocation.getter(#baseUrl),
            returnValue: i6.dummyValue<String>(
              this,
              Invocation.getter(#baseUrl),
            ),
          )
          as String);

  @override
  i7.Future<i2.PokemonList> fetchPokemons({
    int? limit = 10,
    String? nextUrl,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#fetchPokemons, [], {
              #limit: limit,
              #nextUrl: nextUrl,
            }),
            returnValue: i7.Future<i2.PokemonList>.value(
              _FakePokemonList_0(
                this,
                Invocation.method(#fetchPokemons, [], {
                  #limit: limit,
                  #nextUrl: nextUrl,
                }),
              ),
            ),
          )
          as i7.Future<i2.PokemonList>);

  @override
  i7.Future<i3.PokemonDetail> fetchPokemonDetails(int? pokemonId) =>
      (super.noSuchMethod(
            Invocation.method(#fetchPokemonDetails, [pokemonId]),
            returnValue: i7.Future<i3.PokemonDetail>.value(
              _FakePokemonDetail_1(
                this,
                Invocation.method(#fetchPokemonDetails, [pokemonId]),
              ),
            ),
          )
          as i7.Future<i3.PokemonDetail>);

  @override
  i7.Future<i4.PokemonEvolution> fetchPokemonEvolution(
    String? evolutionChainUrlString,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#fetchPokemonEvolution, [
              evolutionChainUrlString,
            ]),
            returnValue: i7.Future<i4.PokemonEvolution>.value(
              _FakePokemonEvolution_2(
                this,
                Invocation.method(#fetchPokemonEvolution, [
                  evolutionChainUrlString,
                ]),
              ),
            ),
          )
          as i7.Future<i4.PokemonEvolution>);
}
