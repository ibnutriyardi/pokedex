import 'package:flutter/material.dart';
import 'package:pokedex/utils/app_ui_constants.dart';

class PokemonTypeCapsule extends StatelessWidget {
  final String type;
  final Color capsuleColor;
  final Color textColor;
  final double? fontSize;

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
