import 'package:flutter/material.dart';
import 'package:wordle/config/game_config/constants.dart';

class CoinDisplay extends StatelessWidget {
  final int coinCount;
  final bool useContainer;

  const CoinDisplay({
    super.key,
    required this.coinCount,
    this.useContainer = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🪙', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text(
          '$coinCount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: useContainer ? colorBlack : colorGrey400,
          ),
        ),
      ],
    );

    if (useContainer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.circular(9),
        ),
        child: content,
      );
    }

    return content;
  }
}
