import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordle/game/data/models/guess_model.dart';

import '../../logic/wordle_logic.dart';

/// Represents the current lifecycle state of a match.
enum GameStatus {
  playing,
  won,
  lost,
}

/// Maintains the state of an active game session.
class WordleGameState {
  final String targetWord;
  final List<WordGuess> guesses;
  final GameStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int maxAttempts;

  final int hintsUsed;
  final List<int> revealedPositions;
  final int coinsEarnedThisGame;
  final int coinsSpentThisGame;

  WordleGameState({
    required this.targetWord,
    required this.guesses,
    required this.status,
    required this.startTime,
    this.endTime,
    this.maxAttempts = 6,
    this.hintsUsed = 0,
    this.revealedPositions = const [],
    this.coinsEarnedThisGame = 0,
    this.coinsSpentThisGame = 0,
  });

  WordleGameState copyWith({
    String? targetWord,
    List<WordGuess>? guesses,
    GameStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? maxAttempts,
    int? hintsUsed,
    List<int>? revealedPositions,
    int? coinsEarnedThisGame,
    int? coinsSpentThisGame,
  }) {
    return WordleGameState(
      targetWord: targetWord ?? this.targetWord,
      guesses: guesses ?? this.guesses,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      revealedPositions: revealedPositions ?? this.revealedPositions,
      coinsEarnedThisGame: coinsEarnedThisGame ?? this.coinsEarnedThisGame,
      coinsSpentThisGame: coinsSpentThisGame ?? this.coinsSpentThisGame,
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isGameOver => status == GameStatus.won || status == GameStatus.lost;
  bool get canGuess => !isGameOver && guesses.length < maxAttempts;
  int get remainingAttempts => maxAttempts - guesses.length;

  bool get usedNoHintsBonus => hintsUsed == 0;
  bool get canUseHint1 => hintsUsed < 1 && canGuess;
  bool get canUseHint2 => hintsUsed < 2 && canGuess;
  int get maxHints => 2;
}

/// Asynchronously creates and exposes a fresh [WordleGameState].
final wordleLoadingProvider = FutureProvider<WordleGameState>((ref) async {
  final gameLogic = ref.watch(wordleLogicProvider);
  return await gameLogic.createNewGame();
});

/// Manages game logic operations and updates the [WordleGameState].
class WordleGameNotifier extends StateNotifier<WordleGameState?> {
  final WordleLogic _gameLogic;

  WordleGameNotifier(this._gameLogic) : super(null) {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    state = await _gameLogic.createNewGame();
  }

  Future<void> newGame() async {
    state = await _gameLogic.createNewGame();
  }

  Future<void> makeGuess(String guess) async {
    if (state == null) return;
    state = await _gameLogic.makeGuess(state!, guess);
  }

  Future<bool> useHint(int hintNumber) async {
    if (state == null) return false;

    final newState = await _gameLogic.useHint(state!, hintNumber);

    if (newState != null) {
      state = newState;
      return true;
    }
    return false;
  }

  Future<bool> checkArticle(String article) async {
    if (state == null) return false;
    return await _gameLogic.checkArticle(state!, article);
  }

  String getWinFeedback() {
    if (state == null) return 'Sehr gut!';
    return _gameLogic.winFeedback(state!);
  }

  int getCurrentCoins() {
    return _gameLogic.getCurrentCoins();
  }

  bool canAffordHint(int hintNumber) {
    return _gameLogic.canAffordHint(hintNumber);
  }
}

final wordleGameStateProvider =
    StateNotifierProvider<WordleGameNotifier, WordleGameState?>(
  (ref) {
    final gameLogic = ref.watch(wordleLogicProvider);
    return WordleGameNotifier(gameLogic);
  },
);
