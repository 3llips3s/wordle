import 'package:flutter/material.dart';
import 'package:wordle/config/game_config/constants.dart';

/// Renders the on-screen virtual keyboard for letter input.
///
/// Handles tap events and visually indicates the guessed state of each letter
/// using the provided [letterStates].
class WordleKeyboard extends StatelessWidget {
  final Function(String)? onKeyTap;
  final Map<String, Color> letterStates;

  const WordleKeyboard({
    super.key,
    this.onKeyTap,
    this.letterStates = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 30),
      color: colorBlack,
      child: Column(
        children: [
          _buildKeyRow(['Q', 'W', 'E', 'R', 'T', 'Z', 'U', 'I', 'O', 'P', 'Ü']),
          const SizedBox(height: 8),
          _buildKeyRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ö', 'Ä']),
          const SizedBox(height: 8),
          _buildKeyRow(['✓', 'Y', 'X', 'C', 'V', 'B', 'N', 'M', 'ß', '←']),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String letter) {
    bool isSpecialKey = letter.trim() == '✓' || letter.trim() == '←';
    bool isEnterKey = letter.trim() == '✓';
    bool isDelKey = letter.trim() == '←';

    Color keyColor;
    if (letterStates.containsKey(letter)) {
      keyColor = letterStates[letter]!;
    } else if (isEnterKey) {
      keyColor = colorYellow;
    } else if (isDelKey) {
      keyColor = colorRed;
    } else {
      keyColor = colorGrey300;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: keyColor,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onKeyTap != null
              ? () {
                  onKeyTap!(letter);
                }
              : null,
          child: Container(
            width: isSpecialKey ? 50 : 28,
            height: 50,
            alignment: Alignment.center,
            child: Text(
              letter.trim(),
              style: TextStyle(
                  fontSize: isSpecialKey ? 24 : 22,
                  fontWeight: FontWeight.bold,
                  color: (isDelKey || letterStates.containsKey(letter)
                      ? colorWhite
                      : colorBlack)),
            ),
          ),
        ),
      ),
    );
  }
}
