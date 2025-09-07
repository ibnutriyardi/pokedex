import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pokedex/utils/app_ui_constants.dart';

import '../../utils/app_strings.dart';
import 'pokemon_type_capsule.dart';

class PokemonCard extends StatelessWidget {
  final String name;
  final String id;
  final List<String> types;
  final String imageUrl;
  final Color color;
  final VoidCallback? onTap;

  const PokemonCard({
    super.key,
    required this.name,
    required this.id,
    required this.types,
    required this.imageUrl,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double fallbackCardPokemonImageSize =
        AppUIConstants.cardPokemonImageSize;
    final double localCardPokeballOffsetX = AppUIConstants.cardPokeballOffsetX;
    final double localCardPokeballOffsetY = AppUIConstants.cardPokeballOffsetY;
    final double localCardContentRightPadding =
        AppUIConstants.cardContentRightPadding;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppUIConstants.mediumPadding),
      child: Container(
        padding: EdgeInsets.all(AppUIConstants.defaultPadding),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppUIConstants.mediumPadding),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha((255 * 0.5).round()),
              blurRadius: AppUIConstants.smallPadding,
              offset: Offset(0, AppUIConstants.tinyPadding),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = constraints.maxWidth;
            if (cardWidth <= 0) cardWidth = fallbackCardPokemonImageSize / 0.45;

            final double dynamicPokemonImageSize = cardWidth * 0.45;
            final double dynamicPokeballImageSize = cardWidth * 0.55;

            final double dynamicIdFontSize = (cardWidth * 0.065).clamp(
              AppUIConstants.cardIdFontSize,
              AppUIConstants.cardIdFontSize * 1.8,
            );
            final double dynamicNameFontSize = (cardWidth * 0.085).clamp(
              AppUIConstants.cardNameFontSize,
              AppUIConstants.cardNameFontSize * 1.8,
            );
            final double dynamicTypeFontSize = (cardWidth * 0.055).clamp(
              AppUIConstants.typeCapsuleFontSize,
              AppUIConstants.typeCapsuleFontSize * 1.8,
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: AppUIConstants.xSmallPadding,
                  right: AppUIConstants.xSmallPadding,
                  child: Text(
                    id,
                    style: TextStyle(
                      color: Colors.white.withAlpha((255 * 0.7).round()),
                      fontWeight: FontWeight.bold,
                      fontSize: dynamicIdFontSize,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: localCardContentRightPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: dynamicNameFontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: AppUIConstants.xSmallPadding),
                      ...types
                          .map(
                            (type) => Padding(
                              padding: EdgeInsets.only(
                                bottom: AppUIConstants.tinyPadding,
                              ),
                              child: PokemonTypeCapsule(
                                type: type,
                                capsuleColor: Colors.white.withAlpha(
                                  AppUIConstants.typeCapsuleBackgroundAlpha,
                                ),
                                textColor: Colors.white,
                                fontSize: dynamicTypeFontSize,
                              ),
                            ),
                          )
                          .take(2),
                    ],
                  ),
                ),
                Positioned(
                  bottom: localCardPokeballOffsetY,
                  right: localCardPokeballOffsetX,
                  child: Opacity(
                    opacity: AppUIConstants.pokeballOpacity,
                    child: Image.asset(
                      AppStrings.pokeballImagePath,
                      width: dynamicPokeballImageSize,
                      height: dynamicPokeballImageSize,
                      fit: BoxFit.contain,
                      color: Colors.white,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0.0,
                  right: 0.0,
                  child: Hero(
                    tag: 'pokemon-image-$id',
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: dynamicPokemonImageSize,
                      height: dynamicPokemonImageSize,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: SizedBox(
                          width: dynamicPokemonImageSize / 2,
                          height: dynamicPokemonImageSize / 2,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withAlpha((255 * 0.5).round()),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.error_outline,
                        color: Colors.white70,
                        size: dynamicPokemonImageSize / 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
