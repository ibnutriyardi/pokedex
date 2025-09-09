import 'package:flutter/material.dart';
import 'package:pokedex/utils/app_ui_constants.dart';

/// A widget that displays a Pokémon type in a small, rounded capsule.
///
/// It shows the type name (e.g., "Grass", "Fire") with a specified background
/// [capsuleColor] and [textColor]. The text is capitalized.
class PokemonTypeCapsule extends StatelessWidget {
  /// The name of the Pokémon type (e.g., "grass").
  final String type;

  /// The background color of the capsule.
  final Color capsuleColor;

  /// The color of the text displaying the type name.
  final Color textColor;

  /// Optional font size for the type name. Defaults to [AppUIConstants.typeCapsuleFontSize]
  /// if not provided.
  final double? fontSize;

  /// Creates a [PokemonTypeCapsule] widget.
  ///
  /// Requires [type], [capsuleColor], and [textColor].
  /// The [fontSize] is optional.
  const PokemonTypeCapsule({
    super.key,
    required this.type,
    required this.capsuleColor,
    required this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    String formattedType;
    if (type.isEmpty) {
      formattedType = '';
    } else {
      formattedType =
          type[0].toUpperCase() +
          (type.length > 1 ? type.substring(1).toLowerCase() : '');
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppUIConstants.typeCapsuleHorizontalPadding,
        vertical: AppUIConstants.typeCapsuleVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: capsuleColor,
        borderRadius: BorderRadius.circular(AppUIConstants.defaultPadding),
      ),
      child: Text(
        formattedType,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize ?? AppUIConstants.typeCapsuleFontSize,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
