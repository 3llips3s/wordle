import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wordle/config/game_config/constants.dart';
import 'package:wordle/core/ui/widgets/glassmorphic_dialog.dart';

/// Renders the introductory tutorial modal explaining how to play.
///
/// Features a scrollable layout with animated semantic demonstrations of the
/// game rules, and includes a persistent bottom-positioned confirmation button.
class WordleInstructionsDialog extends StatelessWidget {
  final VoidCallback onClose;

  const WordleInstructionsDialog({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight =
        screenHeight * 0.85 > 600 ? 600.0 : screenHeight * 0.85;

    return SizedBox(
      height: dialogHeight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: const [0.0, 0.85, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Wördle',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorBlack,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Errate das 5-Buchstaben Wort:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorBlack,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: colorYellowAccent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Alle Wörter sind NOMEN',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: colorYellowAccent,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 42),

                      Column(
                        children: [
                          _buildExampleRow(
                            context: context,
                            letter: 'Z',
                            color: Colors.green,
                            explanation:
                                'Richtiger Buchstabe an richtiger Stelle',
                          ),
                          const SizedBox(height: 28),

                          _buildExampleRow(
                            context: context,
                            letter: 'W',
                            color: colorYellow,
                            explanation:
                                'Buchstabe im Wort aber falsche Stelle',
                          ),
                          const SizedBox(height: 28),

                          _buildExampleRow(
                            context: context,
                            letter: 'Ö',
                            color: Colors.grey,
                            explanation: 'Buchstabe nicht im Wort',
                          ),
                        ],
                      ),

                      const SizedBox(height: 52),

                      Text(
                        '🪙  Münzen System:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorBlack,
                        ),
                      ),

                      const SizedBox(height: 30),

                      _buildCoinExplanationRow(
                        context: context,
                        icon: Icons.emoji_events_rounded,
                        iconColor: Colors.green,
                        explanation:
                            'Verdiene 50 bis 5 🪙 - je nach deinen Versuchen',
                      ),
                      const SizedBox(height: 20),

                      _buildCoinExplanationRow(
                        context: context,
                        icon: Icons.star_rounded,
                        iconColor: colorYellowAccent,
                        explanation: '+5 Bonus ohne Hinweise!',
                      ),
                      const SizedBox(height: 20),

                      _buildCoinExplanationRow(
                        context: context,
                        icon: Icons.lightbulb_rounded,
                        iconColor: Colors.grey,
                        explanation:
                            'Hinweise: 1. kostet 30 🪙  und 2. kostet 50 🪙',
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GlassMorphicButton(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onPressed: onClose,
              child: Text(
                'Los geht\'s!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorYellowAccent,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleRow({
    required BuildContext context,
    required String letter,
    required Color color,
    required String explanation,
  }) {
    return Row(
      children: [
        // Letter tile
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              letter,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorWhite,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Explanation text
        Expanded(
          child: Text(
            explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorBlack,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoinExplanationRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String explanation,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorBlack,
            ),
          ),
        ),
      ],
    );
  }
}

/// Orchestrates the conditional lifecycle of the [WordleInstructionsDialog].
class WordleInstructionsManager {
  static const String _hasSeenInstructionsKey = 'has_seen_wordle_instructions';

  static Future<bool> hasSeenInstructions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenInstructionsKey) ?? false;
  }

  static Future<void> markInstructionsAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenInstructionsKey, true);
  }

  /// Evaluates SharedPreferences and triggers the instructional overlay if unread.
  static Future<bool> showInstructionsDialog(BuildContext context) async {
    if (await hasSeenInstructions()) return false;

    if (context.mounted) {
      await showCustomDialog(
        context: context,
        barrierDismissible: true,
        width: 300,
        child: WordleInstructionsDialog(
          onClose: () {
            Navigator.of(context).pop();
            markInstructionsAsSeen();
          },
        ),
      );
      return true;
    }
    return false;
  }
}
