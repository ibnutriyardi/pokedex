import 'dart:async' as _i7;

import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i6;
import 'package:pokedex/model/pokemon_detail.dart' as _i3;
import 'package:pokedex/model/pokemon_evolution.dart' as _i4;
import 'package:pokedex/model/pokemon_list.dart' as _i2;
import 'package:pokedex/repository/pokemon_repository.dart' as _i5;

class _FakePokemonList_0 extends _i1.SmartFake implements _i2.PokemonList {
  _FakePokemonList_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakePokemonDetail_1 extends _i1.SmartFake implements _i3.PokemonDetail {
  _FakePokemonDetail_1(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakePokemonEvolution_2 extends _i1.SmartFake
    implements _i4.PokemonEvolution {
  _FakePokemonEvolution_2(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [PokemonRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockPokemonRepository extends _i1.Mock implements _i5.PokemonRepository {
  MockPokemonRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String get baseUrl =>
      (super.noSuchMethod(
            Invocation.getter(#baseUrl),
            returnValue: _i6.dummyValue<String>(
              this,
              Invocation.getter(#baseUrl),
            ),
          )
          as String);

  @override
  _i7.Future<_i2.PokemonList> fetchPokemons({
    int? limit = 10,
    String? nextUrl,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#fetchPokemons, [], {
              #limit: limit,
              #nextUrl: nextUrl,
            }),
            returnValue: _i7.Future<_i2.PokemonList>.value(
              _FakePokemonList_0(
                this,
                Invocation.method(#fetchPokemons, [], {
                  #limit: limit,
                  #nextUrl: nextUrl,
                }),
              ),
            ),
          )
          as _i7.Future<_i2.PokemonList>);

  @override
  _i7.Future<_i3.PokemonDetail> fetchPokemonDetails(int? pokemonId) =>
      (super.noSuchMethod(
            Invocation.method(#fetchPokemonDetails, [pokemonId]),
            returnValue: _i7.Future<_i3.PokemonDetail>.value(
              _FakePokemonDetail_1(
                this,
                Invocation.method(#fetchPokemonDetails, [pokemonId]),
              ),
            ),
          )
          as _i7.Future<_i3.PokemonDetail>);

  @override
  _i7.Future<_i4.PokemonEvolution> fetchPokemonEvolution(
    String? evolutionChainUrlString,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#fetchPokemonEvolution, [
              evolutionChainUrlString,
            ]),
            returnValue: _i7.Future<_i4.PokemonEvolution>.value(
              _FakePokemonEvolution_2(
                this,
                Invocation.method(#fetchPokemonEvolution, [
                  evolutionChainUrlString,
                ]),
              ),
            ),
          )
          as _i7.Future<_i4.PokemonEvolution>);
}
