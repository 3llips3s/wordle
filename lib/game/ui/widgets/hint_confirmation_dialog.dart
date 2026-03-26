import 'package:flutter/material.dart';
import 'package:wordle/config/game_config/constants.dart';
import 'package:wordle/core/ui/widgets/glassmorphic_dialog.dart';

/// Renders a confirmation prompt before purchasing a hint.
///
/// Displays the [hintCost] and the player's [currentCoins] balance to explicitly
/// warn the user before deducting currency.
class HintConfirmationDialog extends StatelessWidget {
  final int hintNumber;
  final int hintCost;
  final int currentCoins;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const HintConfirmationDialog({
    super.key,
    required this.hintNumber,
    required this.hintCost,
    required this.currentCoins,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hinweis $hintNumber  •  $hintCost ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
                    ),
              ),
              const Text(
                '🪙',
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Verfügbar: $currentCoins',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: colorBlack.withValues(alpha: 0.5),
              ),
        ),

        const SizedBox(height: 40),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GlassMorphicButton(
              onPressed: onCancel,
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.close_rounded,
                color: colorRed,
                size: 30,
              ),
            ),
            GlassMorphicButton(
              onPressed: onConfirm,
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.check_rounded,
                color: colorDarkGreen,
                size: 30,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
