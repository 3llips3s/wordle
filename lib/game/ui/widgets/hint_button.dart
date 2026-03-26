import 'package:flutter/material.dart';

import 'package:wordle/config/game_config/constants.dart';

/// Renders an interactive lightbulb icon to trigger hints.
///
/// Changes visually based on [isActive] status to indicate affordance.
class HintButton extends StatelessWidget {
  final bool isActive;
  final bool useContainer;
  final VoidCallback? onPressed;
  final VoidCallback? onInsufficientCoins;

  const HintButton({
    super.key,
    required this.isActive,
    this.useContainer = true,
    this.onPressed,
    this.onInsufficientCoins,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();
    final containerColor = _getContainerColor();

    final iconWidget = Icon(
      Icons.lightbulb_rounded,
      size: 28,
      color: iconColor,
    );

    final content = useContainer
        ? Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: iconWidget,
          )
        : iconWidget;

    return GestureDetector(
      onTap: isActive ? onPressed : onInsufficientCoins,
      child: content,
    );
  }

  Color _getIconColor() {
    if (useContainer) {
      return isActive ? colorBlack : colorGrey600;
    } else {
      return isActive ? colorWhite : colorGrey600;
    }
  }

  Color _getContainerColor() {
    if (!useContainer) return Colors.transparent;
    return isActive ? colorWhite : colorGrey400;
  }
}
