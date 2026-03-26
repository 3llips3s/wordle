import 'dart:math';

import '../data/models/wordle_game_state.dart';

/// Provides utility functions for generating and costing hints.
class WordleHintsService {
  static const int hint1Cost = 30;
  static const int hint2Cost = 50;

  /// Returns a random, unrevealed valid index from the active word.
  int getRandomHintPosition(WordleGameState gameState) {
    final targetWord = gameState.targetWord;

    final availablePositions = <int>[];
    for (int i = 0; i < targetWord.length; i++) {
      if (!gameState.revealedPositions.contains(i)) {
        availablePositions.add(i);
      }
    }

    if (availablePositions.isEmpty) {
      return -1;
    }

    final random = Random();
    final selectedPosition =
        availablePositions[random.nextInt(availablePositions.length)];

    return selectedPosition;
  }

  int getHintCost(int hintNumber) {
    switch (hintNumber) {
      case 1:
        return hint1Cost;
      case 2:
        return hint2Cost;
      default:
        return 0;
    }
  }
}
